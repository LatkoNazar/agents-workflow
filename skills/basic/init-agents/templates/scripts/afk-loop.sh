#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# afk-loop.sh — Autonomous Worktree + Dev-Sandbox Orchestrator ("Night Shift")
# Supports orchestration modes from .agents/workflow.json:
#   - single-ticket: Execute one specific ticket end-to-end
#   - sequential-with-review: Pick unblocked AFK tickets one by one
#   - parallel-dag-with-review: Run up to N unblocked AFK tickets in parallel
#     worktree sandboxes, review each in a fresh context, and merge sequentially.
# ==============================================================================

REPO_ROOT="$(git rev-parse --show-toplevel)"
WORKFLOW_JSON="$REPO_ROOT/.agents/workflow.json"
TICKETS_DIR="$REPO_ROOT/.agents/tickets"

MODE="${MODE:-}"
TARGET_TICKET="${1:-}"

if [[ -f "$WORKFLOW_JSON" ]] && command -v jq >/dev/null 2>&1; then
  DEFAULT_MODE="$(jq -r '.orchestration.defaultTemplate // "sequential-with-review"' "$WORKFLOW_JSON")"
  MAX_PARALLEL="$(jq -r '.orchestration.maxParallelWorktrees // 3' "$WORKFLOW_JSON")"
  MAX_RETRIES="$(jq -r '.orchestration.maxReviewIterations // 3' "$WORKFLOW_JSON")"
  BASE_BRANCH="$(jq -r '.project.defaultBranch // "main"' "$WORKFLOW_JSON")"
  IMPL_PROVIDER="$(jq -r '.orchestration.roles.implementer.provider // "claude"' "$WORKFLOW_JSON")"
  IMPL_MODEL="$(jq -r '.orchestration.roles.implementer.model // "claude-sonnet-4-6"' "$WORKFLOW_JSON")"
  REV_PROVIDER="$(jq -r '.orchestration.roles.reviewer.provider // "claude"' "$WORKFLOW_JSON")"
  REV_MODEL="$(jq -r '.orchestration.roles.reviewer.model // "claude-opus-4-6"' "$WORKFLOW_JSON")"
  MERGE_PROVIDER="$(jq -r '.orchestration.roles.merger.provider // "claude"' "$WORKFLOW_JSON")"
  MERGE_MODEL="$(jq -r '.orchestration.roles.merger.model // "claude-sonnet-4-6"' "$WORKFLOW_JSON")"
else
  DEFAULT_MODE="sequential-with-review"
  MAX_PARALLEL=3
  MAX_RETRIES=3
  BASE_BRANCH="main"
  IMPL_PROVIDER="claude"
  IMPL_MODEL="claude-sonnet-4-6"
  REV_PROVIDER="claude"
  REV_MODEL="claude-opus-4-6"
  MERGE_PROVIDER="claude"
  MERGE_MODEL="claude-sonnet-4-6"
fi

MODE="${MODE:-$DEFAULT_MODE}"
if [[ -n "$TARGET_TICKET" && "$TARGET_TICKET" != "--all" ]]; then
  MODE="single-ticket"
fi

# Helper: Run an agent CLI in a fresh context window inside a target directory
run_agent_in_dir() {
  local workdir="$1"
  local provider="$2"
  local model="$3"
  local prompt="$4"

  (
    cd "$workdir"
    case "$provider" in
      claude)
        claude -p "$prompt" --model "$model" --dangerously-skip-permissions
        ;;
      codex)
        codex exec --model "$model" --full-auto "$prompt"
        ;;
      gemini)
        gemini -p "$prompt" --model "$model" --yolo
        ;;
      *)
        $provider "$prompt"
        ;;
    esac
  )
}

# Helper: Check if a local markdown ticket is unblocked and ready for AFK execution
find_unblocked_afk_tickets() {
  if [[ ! -d "$TICKETS_DIR" ]]; then
    return 0
  fi
  for file in "$TICKETS_DIR"/*.md; do
    [[ -e "$file" ]] || continue
    local id
    id="$(basename "$file" .md)"
    local status mode blocked_by
    status="$(grep -E '^status:' "$file" | head -n1 | awk '{print $2}' || true)"
    mode="$(grep -E '^mode:' "$file" | head -n1 | awk '{print $2}' || true)"
    blocked_by="$(grep -E '^blocked_by:' "$file" | head -n1 | sed -E 's/^blocked_by:\s*\[?(.*)\]?/\1/' | tr -d ' "' || true)"

    if [[ "$status" == "ready-for-agent" || "$status" == "todo" ]] && [[ "$mode" == "afk" || -z "$mode" ]]; then
      local is_blocked=false
      if [[ -n "$blocked_by" && "$blocked_by" != "none" && "$blocked_by" != "[]" ]]; then
        IFS=',' read -ra DEPS <<< "$blocked_by"
        for dep in "${DEPS[@]}"; do
          [[ -z "$dep" ]] && continue
          local dep_file
          dep_file="$(ls "$TICKETS_DIR"/*"${dep}"*.md 2>/dev/null | head -n1 || true)"
          if [[ -n "$dep_file" ]]; then
            local dep_status
            dep_status="$(grep -E '^status:' "$dep_file" | head -n1 | awk '{print $2}' || true)"
            if [[ "$dep_status" != "done" ]]; then
              is_blocked=true
              break
            fi
          fi
        done
      fi
      if [[ "$is_blocked" == "false" ]]; then
        echo "$id"
      fi
    fi
  done
}

# Execute Implementer + Reviewer loop inside an isolated worktree sandbox
execute_ticket_in_worktree() {
  local ticket_id="$1"
  local ticket_file="$TICKETS_DIR/${ticket_id}.md"
  local wt_dir="$REPO_ROOT/.worktrees/wt-$ticket_id"

  echo "=================================================================="
  echo "🚀 Starting Ticket: $ticket_id"
  echo "=================================================================="

  if [[ -f "$ticket_file" ]]; then
    sed -i -E 's/^status:\s*.*/status: in-progress/' "$ticket_file" || true
  fi

  # 1. Spin up worktree + cloned Docker dev state
  "$REPO_ROOT/.agents/scripts/worktree-up.sh" "$ticket_id" "$BASE_BRANCH"

  local attempt=1
  local review_feedback=""
  local approved=false

  while [[ $attempt -le $MAX_RETRIES ]]; do
    echo "--> [$ticket_id] Implementation Attempt $attempt/$MAX_RETRIES ($IMPL_PROVIDER / $IMPL_MODEL)..."

    local impl_prompt
    impl_prompt="$(cat <<EOF
You are the Implementer Agent working in an isolated worktree with a cloned Docker dev sandbox.
Read .agents/agents/implementer.md and GLOSSARY.md.
Ticket ID: $ticket_id
Ticket Spec:
$(cat "$ticket_file" 2>/dev/null || echo "See tracker for $ticket_id")

${review_feedback:+Previous Code Review Feedback to address:
$review_feedback}

Instructions:
1. Build the complete VERTICAL SLICE required by this ticket (DB/State -> Deep Module Facade -> Contract Sync -> Frontend/UI).
2. Follow strict TDD (/tdd): write a failing integration test against the public module facade first, then implement.
3. Run ./.agents/scripts/verify.sh until it passes 100%.
4. Commit your changes to the current branch (feat/$ticket_id).
EOF
)"
    run_agent_in_dir "$wt_dir" "$IMPL_PROVIDER" "$IMPL_MODEL" "$impl_prompt"

    # Verify feedback loop deterministically before calling Reviewer
    if ! (cd "$wt_dir" && ./.agents/scripts/verify.sh); then
      review_feedback="verify.sh failed. Fix all test, contract, and typecheck errors."
      attempt=$((attempt + 1))
      continue
    fi

    echo "--> [$ticket_id] Running Clean-Context Reviewer ($REV_PROVIDER / $REV_MODEL)..."
    local rev_prompt
    rev_prompt="$(cat <<EOF
You are the Independent Code Reviewer running in a fresh context window.
Read .agents/agents/reviewer.md for the pushed project coding & architecture standards.
Compare the diff: git diff ${BASE_BRANCH}...HEAD
Ticket Spec:
$(cat "$ticket_file" 2>/dev/null || echo "See tracker for $ticket_id")

Check:
1. Spec Axis: Does this implement the full vertical slice requested without scope creep?
2. Standards & Architecture Axis: Are Deep Module boundaries respected (no cross-module internal/ imports, tests at public facade seam, no horizontal half-layers)?

If everything passes, output the exact token: REVIEW_DECISION: APPROVED
Otherwise, output REVIEW_DECISION: CHANGES_REQUESTED followed by concise, actionable fixes.
EOF
)"
    local review_output
    review_output="$(run_agent_in_dir "$wt_dir" "$REV_PROVIDER" "$REV_MODEL" "$rev_prompt" || true)"
    echo "$review_output"

    if echo "$review_output" | grep -q "REVIEW_DECISION: APPROVED"; then
      approved=true
      break
    else
      review_feedback="$review_output"
      attempt=$((attempt + 1))
    fi
  done

  if [[ "$approved" != "true" ]]; then
    echo "❌ [$ticket_id] Failed to pass review after $MAX_RETRIES attempts. Leaving worktree intact for human inspection." >&2
    return 1
  fi

  return 0
}

# Merge approved worktree into base branch and destroy sandbox
merge_and_teardown_ticket() {
  local ticket_id="$1"
  local ticket_file="$TICKETS_DIR/${ticket_id}.md"
  local branch_name="feat/$ticket_id"

  echo "--> [$ticket_id] Merging '$branch_name' into '$BASE_BRANCH' ($MERGE_PROVIDER / $MERGE_MODEL)..."
  local merge_prompt
  merge_prompt="$(cat <<EOF
You are the Merger Agent (see .agents/agents/merger.md).
Merge branch '$branch_name' into '$BASE_BRANCH', resolve any conflicts cleanly while preserving both vertical slices, and run ./.agents/scripts/verify.sh to confirm the integrated branch is green.
EOF
)"
  run_agent_in_dir "$REPO_ROOT" "$MERGE_PROVIDER" "$MERGE_MODEL" "$merge_prompt"

  if [[ -f "$ticket_file" ]]; then
    sed -i -E 's/^status:\s*.*/status: done/' "$ticket_file" || true
    git add "$ticket_file" && git commit -m "chore(tickets): mark $ticket_id as done" || true
  fi

  "$REPO_ROOT/.agents/scripts/worktree-down.sh" "$ticket_id" "true"
  echo "🎉 [$ticket_id] Merged and sandbox destroyed!"
}

# Main Orchestration Dispatch
case "$MODE" in
  single-ticket)
    execute_ticket_in_worktree "$TARGET_TICKET"
    merge_and_teardown_ticket "$TARGET_TICKET"
    ;;

  sequential-with-review)
    while true; do
      NEXT_TICKET="$(find_unblocked_afk_tickets | head -n1 || true)"
      if [[ -z "$NEXT_TICKET" ]]; then
        echo "✅ No more unblocked AFK tickets remaining."
        break
      fi
      execute_ticket_in_worktree "$NEXT_TICKET"
      merge_and_teardown_ticket "$NEXT_TICKET"
    done
    ;;

  parallel-dag-with-review)
    while true; do
      mapfile -t WAVE < <(find_unblocked_afk_tickets | head -n "$MAX_PARALLEL")
      if [[ ${#WAVE[@]} -eq 0 || -z "${WAVE[0]:-}" ]]; then
        echo "✅ All unblocked AFK tickets in DAG completed."
        break
      fi

      echo "🌊 Launching parallel wave of ${#WAVE[@]} worktree sandboxes: ${WAVE[*]}"
      PIDS=()
      for tid in "${WAVE[@]}"; do
        execute_ticket_in_worktree "$tid" &
        PIDS+=("$!")
      done

      WAVE_FAILED=false
      for i in "${!PIDS[@]}"; do
        if wait "${PIDS[$i]}"; then
          merge_and_teardown_ticket "${WAVE[$i]}"
        else
          WAVE_FAILED=true
        fi
      done

      if [[ "$WAVE_FAILED" == "true" ]]; then
        echo "⚠️ One or more tickets in the wave required human attention. Stopping loop." >&2
        exit 1
      fi
    done
    ;;

  *)
    echo "Unknown orchestration mode: $MODE" >&2
    exit 1
    ;;
esac
