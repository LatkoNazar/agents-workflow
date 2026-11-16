#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# verify.sh — Smart Vertical Slice Feedback Loop (with Anti-Log-Bloat)
# Modes:
#   ./.agents/scripts/verify.sh --affected        (Fast: only git-modified modules)
#   ./.agents/scripts/verify.sh --module <name>   (Fast: only a specific module)
#   ./.agents/scripts/verify.sh --contracts-only  (Sync Backend <-> Frontend types)
#   ./.agents/scripts/verify.sh --full            (Full repo verification before merge)
# ==============================================================================

MODE="affected"
TARGET_MODULE=""
BASE_REF="${BASE_REF:-main}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --affected)
      MODE="affected"
      shift
      ;;
    --module)
      MODE="module"
      TARGET_MODULE="${2:-}"
      shift 2
      ;;
    --contracts-only)
      MODE="contracts-only"
      shift
      ;;
    --full)
      MODE="full"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Anti-Log-Bloat wrapper: prints 1 summary line on success, or tail of log on failure
run_step() {
  local label="$1"
  shift
  local log_file
  log_file="$(mktemp)"
  local start_ts
  start_ts="$(date +%s)"

  if "$@" >"$log_file" 2>&1; then
    local elapsed=$(( $(date +%s) - start_ts ))
    echo "✅ $label (${elapsed}s)"
    rm -f "$log_file"
    return 0
  else
    local exit_code=$?
    local elapsed=$(( $(date +%s) - start_ts ))
    echo "❌ $label FAILED (${elapsed}s) — showing last 80 lines:" >&2
    echo "------------------------------------------------------------------" >&2
    tail -n 80 "$log_file" >&2
    echo "------------------------------------------------------------------" >&2
    rm -f "$log_file"
    return "$exit_code"
  fi
}

# Detect modified vertical modules from git diff (working tree + branch commits)
CHANGED_FILES="$( { git diff --name-only "$BASE_REF"...HEAD 2>/dev/null || true; git diff --name-only HEAD 2>/dev/null || true; } | sort -u )"

AFFECTED_BACKEND_MODULES=()
AFFECTED_FRONTEND_FEATURES=()

if [[ "$MODE" == "module" && -n "$TARGET_MODULE" ]]; then
  [[ -d "backend/src/modules/$TARGET_MODULE" ]] && AFFECTED_BACKEND_MODULES+=("backend/src/modules/$TARGET_MODULE")
  [[ -d "src/modules/$TARGET_MODULE" ]] && AFFECTED_BACKEND_MODULES+=("src/modules/$TARGET_MODULE")
  [[ -d "frontend/src/features/$TARGET_MODULE" ]] && AFFECTED_FRONTEND_FEATURES+=("frontend/src/features/$TARGET_MODULE")
  [[ -d "src/features/$TARGET_MODULE" ]] && AFFECTED_FRONTEND_FEATURES+=("src/features/$TARGET_MODULE")
elif [[ "$MODE" == "affected" && -n "$CHANGED_FILES" ]]; then
  while IFS= read -r mod; do
    [[ -n "$mod" && -d "$mod" ]] && AFFECTED_BACKEND_MODULES+=("$mod")
  done < <(echo "$CHANGED_FILES" | grep -oE '^(backend/)?src/modules/[^/]+' | sort -u || true)

  while IFS= read -r feat; do
    [[ -n "$feat" && -d "$feat" ]] && AFFECTED_FRONTEND_FEATURES+=("$feat")
  done < <(echo "$CHANGED_FILES" | grep -oE '^(frontend/)?src/features/[^/]+' | sort -u || true)
fi

# 1. Deep Module Boundary & Deterministic Anti-Slop Check
check_boundaries() {
  if git grep -nE '(from|import).*modules/[^/]+/internal' -- ':!*.agents/*' 2>/dev/null; then
    echo "Direct import from a module's internal/ directory detected! Import only from its public facade."
    return 1
  fi
  # Deterministic Anti-Slop check on frontend files (no dead href="#", no transition-all)
  if git grep -nE '(href="#"|onClick=\{\(\)\s*=>\s*\{\s*\}\}|transition-all)' -- '*.tsx' '*.jsx' ':!*.test.*' 2>/dev/null; then
    echo "Anti-Slop Violation: Dead control (href='#' or empty onClick) or 'transition-all' detected in UI code!"
    return 1
  fi
  return 0
}
run_step "[1/4] Deep Module boundary & Anti-Slop check" check_boundaries

# 2. Backend Tests (Affected module vs Full)
if [[ "$MODE" != "contracts-only" ]]; then
  run_backend_tests() {
    if [[ -f "pyproject.toml" || -f "backend/pyproject.toml" ]]; then
      if [[ "$MODE" != "full" && ${#AFFECTED_BACKEND_MODULES[@]} -gt 0 ]]; then
        pytest "${AFFECTED_BACKEND_MODULES[@]}" -q
      else
        (cd backend 2>/dev/null || true; pytest -q)
      fi
    elif [[ -f "go.mod" ]]; then
      go test ./...
    elif [[ -f "package.json" ]] && grep -q '"test:backend"' package.json; then
      npm run test:backend
    fi
  }
  run_step "[2/4] Backend integration tests ($MODE)" run_backend_tests
fi

# 3. Contract Sync
sync_contracts() {
  if [[ -f "package.json" ]] && grep -q '"contracts:sync"' package.json; then
    npm run contracts:sync
  fi
}
run_step "[3/4] Contract sync (Backend <-> Frontend)" sync_contracts

if [[ "$MODE" == "contracts-only" ]]; then
  exit 0
fi

# 4. Frontend Typecheck & Tests (Affected vs Full)
run_frontend_checks() {
  if [[ -f "frontend/package.json" ]]; then
    (
      cd frontend
      npm run typecheck
      if [[ "$MODE" != "full" && ${#AFFECTED_FRONTEND_FEATURES[@]} -gt 0 ]]; then
        npx vitest related "${AFFECTED_FRONTEND_FEATURES[@]#frontend/}" --run
      else
        npm test -- --run
      fi
    )
  elif [[ -f "package.json" ]]; then
    if grep -q '"typecheck"' package.json; then
      npm run typecheck
    fi
    if grep -q '"test"' package.json; then
      npm test -- --run
    fi
  fi
}
run_step "[4/4] Frontend typecheck & tests ($MODE)" run_frontend_checks
