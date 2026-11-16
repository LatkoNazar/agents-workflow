#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# verify.sh — Unified Vertical Slice Feedback Loop
# Runs:
#   1. Deep Module Boundary Check (forbid cross-module internal/ imports)
#   2. Backend Typecheck, Lint & Facade Integration Tests
#   3. Contract Export & Frontend Client Generation (Single Source of Truth)
#   4. Frontend Typecheck (tsc) & Feature Tests
# ==============================================================================

CONTRACTS_ONLY=false
if [[ "${1:-}" == "--contracts-only" ]]; then
  CONTRACTS_ONLY=true
fi

echo "==> [1/4] Checking Deep Module boundaries (no cross-module imports from */internal/*)..."
# Detect any import referencing another module's internal/ directory
if git grep -nE '(from|import).*modules/[^/]+/internal' -- ':!*.agents/*' 2>/dev/null; then
  echo "❌ Architectural Violation: Direct import from a module's internal/ directory detected. Import only from the module's public facade!" >&2
  exit 1
fi

if [[ "$CONTRACTS_ONLY" == "false" ]]; then
  echo "==> [2/4] Running Backend Checks & Integration Tests..."
  # Customize during /init-agents for your backend stack (pytest / go test / vitest / cargo test)
  if [[ -f "pyproject.toml" || -f "backend/pyproject.toml" ]]; then
    (cd backend 2>/dev/null || true; pytest)
  elif [[ -f "go.mod" ]]; then
    go test ./...
  elif [[ -f "package.json" ]] && grep -q '"test:backend"' package.json; then
    npm run test:backend
  fi
fi

echo "==> [3/4] Synchronizing Backend <-> Frontend Contracts..."
# Customize during /init-agents (e.g., export OpenAPI schema -> generate TypeScript client)
if [[ -f "package.json" ]] && grep -q '"contracts:sync"' package.json; then
  npm run contracts:sync
fi

if [[ "$CONTRACTS_ONLY" == "true" ]]; then
  echo "✅ Contracts synchronized."
  exit 0
fi

echo "==> [4/4] Running Frontend Typecheck & Feature Tests..."
if [[ -f "frontend/package.json" ]]; then
  (cd frontend && npm run typecheck && npm test -- --run)
elif [[ -f "package.json" ]]; then
  if grep -q '"typecheck"' package.json; then
    npm run typecheck
  fi
  if grep -q '"test"' package.json; then
    npm test -- --run
  fi
fi

echo "✅ Vertical verification loop passed!"
