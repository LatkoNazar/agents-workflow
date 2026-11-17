#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# hook-pre-bash.sh — PreToolUse Safety & Push-Control Hook for Bash commands
# - HARD BLOCK (deny): git push --force/-f, git reset --hard, git clean -f,
#   git add .env, rm -rf outside repo.
# - ASK USER (ask): normal 'git push' so the human always controls remote pushes.
# ==============================================================================

INPUT_JSON="$(cat || true)"
if [[ -z "$INPUT_JSON" ]]; then
  exit 0
fi

extract_cmd() {
  if command -v jq >/dev/null 2>&1; then
    echo "$INPUT_JSON" | jq -r '.tool_input.command // .command // .input.command // .tool_input.CommandLine // .CommandLine // empty' 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, json
try:
    d = json.loads(sys.stdin.read())
    ti = d.get("tool_input") or {}
    inp = d.get("input") or {}
    cmd = ti.get("command") or ti.get("CommandLine") or d.get("command") or d.get("CommandLine") or inp.get("command") or ""
    print(cmd)
except Exception:
    pass
' <<< "$INPUT_JSON" 2>/dev/null || true
  else
    # Simple regex fallback if neither jq nor python3 is installed
    echo "$INPUT_JSON" | grep -oE '"(command|CommandLine)"\s*:\s*"[^"]+"' | head -n 1 | sed -E 's/.*:\s*"([^"]+)".*/\1/' || true
  fi
}

CMD="$(extract_cmd)"
if [[ -z "$CMD" ]]; then
  exit 0
fi

deny_command() {
  local reason="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg reason "$reason" '{
      decision: "deny",
      reason: $reason,
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, json
reason = sys.argv[1]
print(json.dumps({
    "decision": "deny",
    "reason": reason,
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason
    }
}))' "$reason"
  else
    echo "{\"decision\":\"deny\",\"reason\":\"$reason\"}"
  fi
  exit 0
}

ask_command() {
  local reason="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg reason "$reason" '{
      decision: "ask",
      reason: $reason,
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $reason
      }
    }'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, json
reason = sys.argv[1]
print(json.dumps({
    "decision": "ask",
    "reason": reason,
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": reason
    }
}))' "$reason"
  else
    echo "{\"decision\":\"ask\",\"reason\":\"$reason\"}"
  fi
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
