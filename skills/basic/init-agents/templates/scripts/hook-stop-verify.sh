#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# hook-stop-verify.sh — Stop Hook ("Exit Turnstile")
# If the agent modified code files during the turn, automatically runs
# ./.agents/scripts/verify.sh --affected before allowing the agent to finish.
# ==============================================================================

INPUT_JSON="$(cat || true)"

# Avoid infinite stop-hook loops if stop_hook_active is already true
if [[ -n "$INPUT_JSON" ]] && command -v jq >/dev/null 2>&1; then
  STOP_ACTIVE="$(echo "$INPUT_JSON" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")"
  if [[ "$STOP_ACTIVE" == "true" ]]; then
    exit 0
  fi
fi

# Only run verify.sh if the working tree has modified or staged code files
CHANGED="$(git status --porcelain 2>/dev/null | grep -vE '(\.agents/specs/|\.agents/tickets/|GLOSSARY\.md|README\.md)' || true)"
if [[ -z "$CHANGED" ]]; then
  exit 0
fi

if [[ -x "./.agents/scripts/verify.sh" ]]; then
  VERIFY_OUT="$(mktemp)"
  if ! ./.agents/scripts/verify.sh --affected >"$VERIFY_OUT" 2>&1; then
    ERR_TAIL="$(tail -n 40 "$VERIFY_OUT")"
    rm -f "$VERIFY_OUT"
    if command -v jq >/dev/null 2>&1; then
      jq -cn --arg reason "Stop gate failed: ./.agents/scripts/verify.sh --affected reported errors. Fix them before finishing:\n$ERR_TAIL" '{
        decision: "block",
        reason: $reason
      }'
      exit 0
    else
      echo "Stop gate failed: verify.sh --affected failed: $ERR_TAIL" >&2
      exit 2
    fi
  fi
  rm -f "$VERIFY_OUT"
fi

exit 0
