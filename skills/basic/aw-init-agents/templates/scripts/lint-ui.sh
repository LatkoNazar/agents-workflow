#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# lint-ui.sh — Universal UI Architecture, Design Token & Anti-Slop Linter
# Customized per project during /aw-init-agents (Tailwind/CVA, CSS Modules, etc.).
# Automatically skipped if .agents/workflow.json sets architecture.uiLinter.enabled = false
# ==============================================================================

REPO_ROOT="$(git rev-parse --show-toplevel)"
WORKFLOW_JSON="$REPO_ROOT/.agents/workflow.json"

if [[ -f "$WORKFLOW_JSON" ]] && command -v jq >/dev/null 2>&1; then
  UI_LINT_ENABLED="$(jq -r '.architecture.uiLinter.enabled // true' "$WORKFLOW_JSON")"
  if [[ "$UI_LINT_ENABLED" == "false" ]]; then
    echo "ℹ️  UI CSS/Token Linter is disabled in .agents/workflow.json (skipping)."
    exit 0
  fi
fi

BASE_REF="${BASE_REF:-main}"
# Lint only frontend feature files (or all frontend files if none specified)
FEATURE_GLOBS=("*features/*.tsx" "*features/*.jsx" "*features/*.css" "*pages/*.tsx")

HAS_VIOLATIONS=false

report_violation() {
  local rule="$1"
  local details="$2"
  echo "❌ [lint-ui] $rule" >&2
  echo "$details" | sed 's/^/   /' >&2
  HAS_VIOLATIONS=true
}

# 1. No Hardcoded Hex/RGB Colors or Inline Styles in Feature Code
# (Colors must live in tokens.css / tailwind.config / theme.ts, never hardcoded in features/*)
HARDCODED_STYLES="$(git grep -nE '(style=\{\{|#[0-9a-fA-F]{3,8}\b|rgba?\(|hsla?\()' -- "${FEATURE_GLOBS[@]}" ':!*.test.*' ':!*tokens*' ':!*theme*' 2>/dev/null || true)"
if [[ -n "$HARDCODED_STYLES" ]]; then
  report_violation "Hardcoded color or inline style={{}} in feature code (use semantic design tokens instead):" "$HARDCODED_STYLES"
fi

# 2. No Arbitrary Tailwind Bracket Values in Feature Code (e.g. w-[342px], bg-[#123], text-[15px])
ARBITRARY_TW="$(git grep -nE '\b(w|h|p|px|py|pt|pb|pl|pr|m|mx|my|mt|mb|ml|mr|gap|text|bg|border|rounded)-\[[^]]+\]' -- "${FEATURE_GLOBS[@]}" ':!*.test.*' 2>/dev/null || true)"
if [[ -n "$ARBITRARY_TW" ]]; then
  report_violation "Arbitrary bracket class [...] detected in feature code (use design system scale tokens):" "$ARBITRARY_TW"
fi

# 3. No Dead Controls, Non-Semantic Clickable Divs, or transition-all
DEAD_OR_BAD_UI="$(git grep -nE '(href="#"|onClick=\{\(\)\s*=>\s*\{\s*\}\}|<(div|span)[^>]+onClick=|\btransition-all\b|transition:\s*all)' -- '*.tsx' '*.jsx' ':!*.test.*' 2>/dev/null || true)"
if [[ -n "$DEAD_OR_BAD_UI" ]]; then
  report_violation "Anti-Slop UI violation (dead href='#', empty onClick, <div onClick>, or transition-all):" "$DEAD_OR_BAD_UI"
fi

# 4. No UI Placeholders, Hardcoded Mock Arrays, or Em-Dashes in UI Components
SLOP_COPY_OR_MOCKS="$(git grep -nE '(const\s+(mock|MOCK_)[A-Za-z0-9_]*\s*=|\[REAL DATA\]|\[PLACEHOLDER\]|"Coming soon"|—)' -- "${FEATURE_GLOBS[@]}" ':!*.test.*' 2>/dev/null || true)"
if [[ -n "$SLOP_COPY_OR_MOCKS" ]]; then
  report_violation "UI Placeholder / Mock array or Em-Dash (—) detected in feature code (seed sandbox DB instead of mocking UI):" "$SLOP_COPY_OR_MOCKS"
fi

if [[ "$HAS_VIOLATIONS" == "true" ]]; then
  exit 1
fi

echo "✅ UI Token & Anti-Slop Linter passed!"
