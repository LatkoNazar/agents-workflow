#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# worktree-down.sh — Destroy isolated Docker Sandbox + remove Git Worktree
# ==============================================================================

TICKET_ID="${1:-}"
DELETE_BRANCH="${2:-true}"

if [[ -z "$TICKET_ID" ]]; then
  echo "Usage: $0 <ticket-id> [delete-branch:true|false]" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SAFE_ID="$(echo "$TICKET_ID" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g' | sed -E 's/^_|_$//g')"
WT_DIR="$REPO_ROOT/.worktrees/wt-$TICKET_ID"
BRANCH_NAME="feat/$TICKET_ID"
SANDBOX_PROJECT="wt_${SAFE_ID}"

# Load worktree metadata if present
if [[ -f "$WT_DIR/.env.worktree" ]]; then
  # shellcheck disable=SC1090
  source "$WT_DIR/.env.worktree"
fi

PG_CONTAINER="${PG_CONTAINER:-$(docker ps --format '{{.Names}}' | grep -iE 'postgres|pg|db' | head -n1 || true)}"
PG_USER="${PG_USER:-postgres}"
PG_SOURCE_DB="${PG_SOURCE_DB:-app_dev}"
PG_TARGET_DB="${PG_TARGET_DB:-${PG_SOURCE_DB}_${SANDBOX_PROJECT}}"

MONGO_CONTAINER="${MONGO_CONTAINER:-$(docker ps --format '{{.Names}}' | grep -iE 'mongo' | head -n1 || true)}"
MONGO_SOURCE_DB="${MONGO_SOURCE_DB:-app_dev}"
MONGO_TARGET_DB="${MONGO_TARGET_DB:-${MONGO_SOURCE_DB}_${SANDBOX_PROJECT}}"

echo "==> [1/4] Purging cloned databases & sandbox containers for '$SANDBOX_PROJECT'..."

# 1. Drop cloned PostgreSQL database
if [[ -n "$PG_CONTAINER" ]]; then
  echo "    [Postgres] Dropping database '$PG_TARGET_DB'..."
  docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d postgres \
    -c "DROP DATABASE IF EXISTS \"$PG_TARGET_DB\" WITH (FORCE);" >/dev/null 2>&1 || \
  docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d postgres \
    -c "DROP DATABASE IF EXISTS \"$PG_TARGET_DB\";" >/dev/null 2>&1 || true
fi

# 2. Drop cloned MongoDB database
if [[ -n "$MONGO_CONTAINER" ]]; then
  echo "    [MongoDB] Dropping database '$MONGO_TARGET_DB'..."
  docker exec "$MONGO_CONTAINER" mongosh "$MONGO_TARGET_DB" --quiet --eval "db.dropDatabase()" >/dev/null 2>&1 || \
  docker exec "$MONGO_CONTAINER" mongo "$MONGO_TARGET_DB" --quiet --eval "db.dropDatabase()" >/dev/null 2>&1 || true
fi

# 3. Stop & remove sandbox Redis container, compose stack, and cloned Docker volumes
if docker ps -a --format '{{.Names}}' | grep -q "^${SANDBOX_PROJECT}_redis$"; then
  echo "    [Redis] Removing container '${SANDBOX_PROJECT}_redis'..."
  docker rm -f "${SANDBOX_PROJECT}_redis" >/dev/null 2>&1 || true
fi

docker compose -p "$SANDBOX_PROJECT" down -v --remove-orphans >/dev/null 2>&1 || true

for VOL in $(docker volume ls -q | grep "^${SANDBOX_PROJECT}_" || true); do
  echo "    [Volume] Removing cloned volume '$VOL'..."
  docker volume rm -f "$VOL" >/dev/null 2>&1 || true
done

# 4. Remove Git worktree and release slot
echo "==> [2/4] Removing Git worktree '$WT_DIR'..."
if [[ -d "$WT_DIR" ]]; then
  git worktree remove --force "$WT_DIR"
fi
git worktree prune

SLOT_FILE="$REPO_ROOT/.worktrees/.slots"
if [[ -f "$SLOT_FILE" ]]; then
  grep -v ":${TICKET_ID}$" "$SLOT_FILE" > "${SLOT_FILE}.tmp" || true
  mv "${SLOT_FILE}.tmp" "$SLOT_FILE"
fi

echo "==> [3/4] Cleaning branch '$BRANCH_NAME' (delete=$DELETE_BRANCH)..."
if [[ "$DELETE_BRANCH" == "true" ]] && git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  git branch -D "$BRANCH_NAME" >/dev/null 2>&1 || true
fi

echo "✅ Sandbox & Worktree '$TICKET_ID' completely removed."
