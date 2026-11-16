#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# afk-loop.sh — Autonomous Worktree + Dev-Sandbox Orchestrator ("Night Shift")
# Pipeline per ticket (every step in a 100% fresh <100k Smart Zone context):
#   1. Implementer (TDD + fast verify.sh --affected)
#   2. Tester Sub-Agent (Smart blast-radius test selector & log shield)
#   3. Reviewer Sub-Agent (Two-axis clean-context diff review)
#   4. Merger Sub-Agent (Merge + verify.sh --full + destroy sandbox)
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
  SMART_ZONE_LIMIT="$(jq -r '.orchestration.smartZoneLimitTokens // 100000' "$WORKFLOW_JSON")"
  BASE_BRANCH="$(jq -r '.project.defaultBranch // "main"' "$WORKFLOW_JSON")"
  IMPL_PROVIDER="$(jq -r '.orchestration.roles.implementer.provider // "claude"' "$WORKFLOW_JSON")"
  IMPL_MODEL="$(jq -r '.orchestration.roles.implementer.model // "claude-sonnet-4-6"' "$WORKFLOW_JSON")"
  TEST_PROVIDER="$(jq -r '.orchestration.roles.tester.provider // "claude"' "$WORKFLOW_JSON")"
  TEST_MODEL="$(jq -r '.orchestration.roles.tester.model // "claude-sonnet-4-6"' "$WORKFLOW_JSON")"
  REV_PROVIDER="$(jq -r '.orchestration.roles.reviewer.provider // "claude"' "$WORKFLOW_JSON")"
  REV_MODEL="$(jq -r '.orchestration.roles.reviewer.model // "claude-opus-4-6"' "$WORKFLOW_JSON")"
  MERGE_PROVIDER="$(jq -r '.orchestration.roles.merger.provider // "claude"' "$WORKFLOW_JSON")"
  MERGE_MODEL="$(jq -r '.orchestration.roles.merger.model // "claude-sonnet-4-6"' "$WORKFLOW_JSON")"
else
  DEFAULT_MODE="sequential-with-review"
  MAX_PARALLEL=3
  MAX_RETRIES=3
  SMART_ZONE_LIMIT=100000
  BASE_BRANCH="main"
  IMPL_PROVIDER="claude"
  IMPL_MODEL="claude-sonnet-4-6"
  TEST_PROVIDER="claude"
  TEST_MODEL="claude-sonnet-4-6"
  REV_PROVIDER="claude"
  REV_MODEL="claude-opus-4-6"
  MERGE_PROVIDER="claude"
  MERGE_MODEL="claude-sonnet-4-6"
fi

MODE="${MODE:-$DEFAULT_MODE}"
if [[ -n "$TARGET_TICKET" && "$TARGET_TICKET" != "--all" ]]; then
  MODE="single-ticket"
fi

# Helper: Run an agent CLI in a fresh context window and report Smart Zone token usage
run_agent_in_dir() {
  local workdir="$1"
  local provider="$2"
  local model="$3"
  local prompt="$4"
  local role_label="${5:-agent}"

  (
    cd "$workdir"
    case "$provider" in
      claude)
        if command -v jq >/dev/null 2>&1; then
          local json_out
          json_out="$(claude -p "$prompt" --model "$model" --output-format json --dangerously-skip-permissions 2>/dev/null || true)"
          if [[ -n "$json_out" ]] && echo "$json_out" | jq -e . >/dev/null 2>&1; then
            local result_text input_tok cache_read cache_create total_ctx used_k limit_k
            result_text="$(echo "$json_out" | jq -r '.result // empty')"
            input_tok="$(echo "$json_out" | jq -r '.usage.input_tokens // 0')"
            cache_read="$(echo "$json_out" | jq -r '.usage.cache_read_input_tokens // 0')"
            cache_create="$(echo "$json_out" | jq -r '.usage.cache_creation_input_tokens // 0')"
            total_ctx=$((input_tok + cache_read + cache_create))
            used_k=$(( (total_ctx + 999) / 1000 ))
            limit_k=$(( SMART_ZONE_LIMIT / 1000 ))
            if [[ $total_ctx -gt $SMART_ZONE_LIMIT ]]; then
              echo "⚠️  [$role_label] Context window: ${used_k}k / ${limit_k}k (EXCEEDED SMART ZONE — slice tickets smaller!)" >&2
            else
              echo "🧠 [$role_label] Context window: ${used_k}k / ${limit_k}k (Smart Zone)" >&2
            fi
            echo "$result_text"
            return 0
          fi
        fi
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

# Helper: Find unblocked AFK tickets from .agents/tickets/
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

# Execute Implementer -> Tester -> Reviewer loop inside an isolated worktree sandbox
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
  local feedback=""
  local approved=false

  while [[ $attempt -le $MAX_RETRIES ]]; do
    echo "--> [$ticket_id] Attempt $attempt/$MAX_RETRIES: Implementer ($IMPL_PROVIDER / $IMPL_MODEL)..."

    local recent_commits
    recent_commits="$(cd "$wt_dir" && git log -n 5 --oneline 2>/dev/null || true)"

    local impl_prompt
    impl_prompt="$(cat <<EOF
You are the Implementer Agent working in a fresh <100k Smart Zone context inside an isolated worktree with a cloned Docker dev sandbox.
Read .agents/agents/implementer.md and GLOSSARY.md.

Recent 5 Commits:
$recent_commits

Ticket ID: $ticket_id
Ticket Spec:
$(cat "$ticket_file" 2>/dev/null || echo "See tracker for $ticket_id")

${feedback:+Feedback from previous Tester/Reviewer run to fix:
$feedback}

Instructions:
1. Build the complete VERTICAL SLICE required by this ticket (DB/State -> Deep Module Facade -> Contract Sync -> Frontend/UI).
2. Follow strict TDD (/tdd): write a failing integration test against the public module facade first, then implement.
3. Use fast ./.agents/scripts/verify.sh --affected during coding iterations so you only run tests for affected modules.
4. Commit your changes to the current branch (feat/$ticket_id).
EOF
)"
    run_agent_in_dir "$wt_dir" "$IMPL_PROVIDER" "$IMPL_MODEL" "$impl_prompt" "implementer"

    echo "--> [$ticket_id] Running Smart Tester Sub-Agent ($TEST_PROVIDER / $TEST_MODEL)..."
    local test_prompt
    test_prompt="$(cat <<EOF
You are the Tester Sub-Agent running in a fresh context window.
Read .agents/agents/tester.md.
Inspect git diff ${BASE_BRANCH}...HEAD, select and run the appropriate verification tier (./.agents/scripts/verify.sh --affected, plus any affected neighboring module tests or E2E smoke tests), absorb all raw logs, and output either:
- TEST_VERDICT: PASSED
- TEST_VERDICT: FAILED (followed by a concise 5-10 line root-cause diagnosis).
EOF
)"
    local test_output
    test_output="$(run_agent_in_dir "$wt_dir" "$TEST_PROVIDER" "$TEST_MODEL" "$test_prompt" "tester" || true)"
    echo "$test_output"

    if ! echo "$test_output" | grep -q "TEST_VERDICT: PASSED"; then
      feedback="$test_output"
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
    review_output="$(run_agent_in_dir "$wt_dir" "$REV_PROVIDER" "$REV_MODEL" "$rev_prompt" "reviewer" || true)"
    echo "$review_output"

    if echo "$review_output" | grep -q "REVIEW_DECISION: APPROVED"; then
      approved=true
      break
    else
      feedback="$review_output"
      attempt=$((attempt + 1))
    fi
  done

  if [[ "$approved" != "true" ]]; then
    echo "❌ [$ticket_id] Failed to pass Tester/Reviewer after $MAX_RETRIES attempts. Leaving worktree intact for human inspection." >&2
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
Merge branch '$branch_name' into '$BASE_BRANCH', resolve any conflicts cleanly while preserving both vertical slices, and run ./.agents/scripts/verify.sh --full to confirm the integrated branch is green.
EOF
)"
  run_agent_in_dir "$REPO_ROOT" "$MERGE_PROVIDER" "$MERGE_MODEL" "$merge_prompt" "merger"

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
