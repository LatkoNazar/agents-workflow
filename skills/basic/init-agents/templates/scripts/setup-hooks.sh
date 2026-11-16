#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# setup-hooks.sh — Check & Auto-Configure Native Agent Hooks Across ALL Agents
# Ensures PreToolUse/BeforeTool (hook-pre-bash.sh) and Stop/AfterAgent
# (hook-stop-verify.sh) are wired simultaneously for:
#   1. Claude Code      (.claude/settings.json)
#   2. OpenAI Codex CLI (.codex/hooks.json)
#   3. Gemini CLI / AGY (.gemini/settings.json)
#   4. Cursor           (.cursor/hooks.json)
# ==============================================================================

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

STANDARD_HOOKS_PAYLOAD='{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|run_shell_command|run_command",
        "hooks": [
          {
            "type": "command",
            "command": "./.agents/scripts/hook-pre-bash.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "./.agents/scripts/hook-stop-verify.sh"
          }
        ]
      }
    ]
  }
}'

GEMINI_HOOKS_PAYLOAD='{
  "hooks": {
    "BeforeTool": [
      {
        "matcher": "run_shell_command|Bash|run_command",
        "hooks": [
          {
            "type": "command",
            "command": "./.agents/scripts/hook-pre-bash.sh"
          }
        ]
      }
    ],
    "AfterAgent": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "./.agents/scripts/hook-stop-verify.sh"
          }
        ]
      }
    ]
  }
}'

ensure_agent_hook_file() {
  local agent_name="$1"
  local file_path="$REPO_ROOT/$2"
  local payload="$3"

  mkdir -p "$(dirname "$file_path")"

  if [[ -f "$file_path" ]]; then
    if grep -q "hook-pre-bash.sh" "$file_path" 2>/dev/null; then
      echo "✅ [$agent_name] Hooks already configured in $2"
      return 0
    fi
    if command -v jq >/dev/null 2>&1; then
      local merged
      merged="$(jq -s '.[0] * .[1]' "$file_path" <(echo "$payload"))"
      echo "$merged" > "$file_path"
      echo "✅ [$agent_name] Merged hooks into existing $2"
      return 0
    fi
  fi

  echo "$payload" > "$file_path"
  echo "✅ [$agent_name] Created hooks config at $2"
}

# Generate all 4 at once so switching between Codex, Gemini, Claude, and Cursor works seamlessly
ensure_agent_hook_file "Claude Code" ".claude/settings.json" "$STANDARD_HOOKS_PAYLOAD"
ensure_agent_hook_file "Codex CLI" ".codex/hooks.json" "$STANDARD_HOOKS_PAYLOAD"
ensure_agent_hook_file "Gemini CLI" ".gemini/settings.json" "$GEMINI_HOOKS_PAYLOAD"
ensure_agent_hook_file "Cursor" ".cursor/hooks.json" "$STANDARD_HOOKS_PAYLOAD"
