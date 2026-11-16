#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# hook-pre-bash.sh — PreToolUse Safety & Push-Control Hook for Bash commands
# - HARD BLOCK (deny): git push --force/-f, git reset --hard, git clean -f,
#   git add .env, rm -rf outside repo.
# - ASK USER (ask): normal 'git push' so the human always controls remote pushes.
# ==============================================================================

INPUT_JSON="$(cat || true)"
if [[ -z "$INPUT_JSON" ]] || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

CMD="$(echo "$INPUT_JSON" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
if [[ -z "$CMD" ]]; then
  exit 0
fi

deny_command() {
  local reason="$1"
  jq -cn --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

ask_command() {
  local reason="$1"
  jq -cn --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# 1. Hard Block: Force push
if echo "$CMD" | grep -qE '\bgit\s+push\b.*(--force|-f\b|--force-with-lease)'; then
  deny_command "Blocked by safety hook: Force push (git push --force / -f) is strictly forbidden."
fi

# 2. Hard Block: Destructive git reset / clean
if echo "$CMD" | grep -qE '\bgit\s+(reset\s+--hard|clean\s+-[a-zA-Z]*f)'; then
  deny_command "Blocked by safety hook: Destructive git reset --hard or git clean -f is forbidden."
fi

# 3. Hard Block: Staging .env files (allow .env.example / .env.sample / .env.template)
if echo "$CMD" | grep -qE '\bgit\s+add\b.*\.env(\b|\.[a-zA-Z0-9_-]+)' && ! echo "$CMD" | grep -qE '\.env\.(example|sample|template)\b'; then
  deny_command "Blocked by safety hook: Never stage or commit .env files containing secrets."
fi

# 4. Hard Block: Destructive rm -rf outside current directory
if echo "$CMD" | grep -qE '\brm\s+-[a-zA-Z]*r[a-zA-Z]*f\s+(\.\.|/|~)'; then
  deny_command "Blocked by safety hook: Destructive rm -rf outside project directory is forbidden."
fi

# 5. Ask User Confirmation: Any normal git push
if echo "$CMD" | grep -qE '\bgit\s+push\b'; then
  ask_command "Agent wants to run 'git push'. Approve pushing commits to remote?"
fi

exit 0
