#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# setup-hooks.sh — Check & Auto-Configure Native Agent Hooks Across Coding Agents
# Ensures PreToolUse (hook-pre-bash.sh) and Stop (hook-stop-verify.sh) are wired
# for Claude Code (.claude/settings.json), Codex (.codex/hooks.json),
# Cursor (.cursor/hooks.json), and Gemini/Antigravity (.gemini/settings.json).
# ==============================================================================

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PRE_HOOK="./.agents/scripts/hook-pre-bash.sh"
STOP_HOOK="./.agents/scripts/hook-stop-verify.sh"

HOOKS_PAYLOAD='{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
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

ensure_agent_hook_file() {
  local agent_name="$1"
  local file_path="$REPO_ROOT/$2"

  mkdir -p "$(dirname "$file_path")"

  if [[ -f "$file_path" ]]; then
    if grep -q "hook-pre-bash.sh" "$file_path" 2>/dev/null; then
      echo "✅ [$agent_name] Hooks already configured in $2"
      return 0
    fi
    if command -v jq >/dev/null 2>&1; then
      local merged
      merged="$(jq -s '.[0] * .[1]' "$file_path" <(echo "$HOOKS_PAYLOAD"))"
      echo "$merged" > "$file_path"
      echo "✅ [$agent_name] Merged hooks into existing $2"
      return 0
    fi
  fi

  echo "$HOOKS_PAYLOAD" > "$file_path"
  echo "✅ [$agent_name] Created hooks config at $2"
}

# 1. Claude Code & Antigravity (.claude/settings.json)
ensure_agent_hook_file "Claude Code / Antigravity" ".claude/settings.json"

# 2. OpenAI Codex CLI (.codex/hooks.json)
ensure_agent_hook_file "Codex CLI" ".codex/hooks.json"

# 3. Cursor (.cursor/hooks.json)
ensure_agent_hook_file "Cursor" ".cursor/hooks.json"
