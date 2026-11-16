#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# worktree-up.sh — Spin up an isolated Git Worktree + Full Dev-State Sandbox
# Clones live dev databases (Postgres, Mongo, Redis), Docker volumes, and
# local profile/upload directories so the agent starts with 100% of dev data.
# ==============================================================================

TICKET_ID="${1:-}"
BASE_BRANCH="${2:-main}"

if [[ -z "$TICKET_ID" ]]; then
  echo "Usage: $0 <ticket-id> [base-branch]" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
WORKFLOW_JSON="$REPO_ROOT/.agents/workflow.json"

# Sanitize ID for Docker / DB names (alphanumeric + underscore only)
SAFE_ID="$(echo "$TICKET_ID" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g' | sed -E 's/^_|_$//g')"
WT_DIR="$REPO_ROOT/.worktrees/wt-$TICKET_ID"
BRANCH_NAME="feat/$TICKET_ID"
SANDBOX_PROJECT="wt_${SAFE_ID}"

mkdir -p "$REPO_ROOT/.worktrees"

# 1. Allocate a unique slot (1..20) for PORT_OFFSET and Redis DB isolation
SLOT_FILE="$REPO_ROOT/.worktrees/.slots"
touch "$SLOT_FILE"
WT_SLOT=1
while grep -q "^${WT_SLOT}:" "$SLOT_FILE" 2>/dev/null; do
  WT_SLOT=$((WT_SLOT + 1))
done
grep -v ":${TICKET_ID}$" "$SLOT_FILE" > "${SLOT_FILE}.tmp" || true
echo "${WT_SLOT}:${TICKET_ID}" >> "${SLOT_FILE}.tmp"
mv "${SLOT_FILE}.tmp" "$SLOT_FILE"

PORT_OFFSET=$((WT_SLOT * 100))

echo "==> [1/5] Creating Git worktree at $WT_DIR (branch: $BRANCH_NAME, slot: $WT_SLOT, port offset: +$PORT_OFFSET)"
if [[ ! -d "$WT_DIR" ]]; then
  if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    git worktree add "$WT_DIR" "$BRANCH_NAME"
  else
    git worktree add -b "$BRANCH_NAME" "$WT_DIR" "$BASE_BRANCH"
  fi
fi

# 2. Symlink heavy dependency directories (node_modules, .venv) for instant startup
echo "==> [2/5] Linking dependency caches into worktree..."
for SYMLINK_REL in "node_modules" "frontend/node_modules" "backend/.venv" ".venv"; do
  if [[ -e "$REPO_ROOT/$SYMLINK_REL" && ! -e "$WT_DIR/$SYMLINK_REL" ]]; then
    mkdir -p "$(dirname "$WT_DIR/$SYMLINK_REL")"
    ln -s "$REPO_ROOT/$SYMLINK_REL" "$WT_DIR/$SYMLINK_REL"
  fi
done

# 3. Copy local dev state (profiles, uploads, SQLite files) using CoW where supported
echo "==> [3/5] Cloning local dev files (profiles, uploads, .env)..."
for COPY_REL in "storage/profiles" "storage/uploads" "data"; do
  if [[ -e "$REPO_ROOT/$COPY_REL" && ! -e "$WT_DIR/$COPY_REL" ]]; then
    mkdir -p "$(dirname "$WT_DIR/$COPY_REL")"
    cp -a --reflink=auto "$REPO_ROOT/$COPY_REL" "$WT_DIR/$COPY_REL" 2>/dev/null || cp -a "$REPO_ROOT/$COPY_REL" "$WT_DIR/$COPY_REL"
  fi
done

if [[ -f "$REPO_ROOT/.env" && ! -f "$WT_DIR/.env" ]]; then
  cp "$REPO_ROOT/.env" "$WT_DIR/.env"
fi

# 4. Clone Stateful Dev Services (Postgres, MongoDB, Redis, Docker Volumes)
echo "==> [4/5] Cloning dev database & service state into sandbox '$SANDBOX_PROJECT'..."

# --- 4a. PostgreSQL Clone ---
PG_CONTAINER="${PG_CONTAINER:-$(docker ps --format '{{.Names}}' | grep -iE 'postgres|pg|db' | head -n1 || true)}"
PG_USER="${PG_USER:-postgres}"
PG_SOURCE_DB="${PG_SOURCE_DB:-app_dev}"
PG_TARGET_DB="${PG_SOURCE_DB}_${SANDBOX_PROJECT}"

if [[ -n "$PG_CONTAINER" ]]; then
  echo "    [Postgres] Cloning '$PG_SOURCE_DB' -> '$PG_TARGET_DB' in container '$PG_CONTAINER'..."
  docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$PG_TARGET_DB'" | grep -q 1 || {
    # Try fast TEMPLATE clone first; fallback to streaming pg_dump | psql if dev DB has active connections
    docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d postgres -c "CREATE DATABASE \"$PG_TARGET_DB\" WITH TEMPLATE \"$PG_SOURCE_DB\";" 2>/dev/null || {
      docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d postgres -c "CREATE DATABASE \"$PG_TARGET_DB\";"
      docker exec "$PG_CONTAINER" pg_dump -U "$PG_USER" -d "$PG_SOURCE_DB" --no-owner --no-acl \
        | docker exec -i "$PG_CONTAINER" psql -U "$PG_USER" -d "$PG_TARGET_DB" -q >/dev/null
    }
  }
fi

# --- 4b. MongoDB Clone ---
MONGO_CONTAINER="${MONGO_CONTAINER:-$(docker ps --format '{{.Names}}' | grep -iE 'mongo' | head -n1 || true)}"
MONGO_SOURCE_DB="${MONGO_SOURCE_DB:-app_dev}"
MONGO_TARGET_DB="${MONGO_SOURCE_DB}_${SANDBOX_PROJECT}"

if [[ -n "$MONGO_CONTAINER" ]]; then
  echo "    [MongoDB] Cloning '$MONGO_SOURCE_DB' -> '$MONGO_TARGET_DB' in container '$MONGO_CONTAINER'..."
  docker exec "$MONGO_CONTAINER" sh -c \
    "mongodump --archive --db=\"$MONGO_SOURCE_DB\" 2>/dev/null | mongorestore --archive --drop --nsFrom=\"${MONGO_SOURCE_DB}.*\" --nsTo=\"${MONGO_TARGET_DB}.*\" 2>/dev/null" || true
fi

# --- 4c. Redis Sandbox Clone ---
REDIS_CONTAINER="${REDIS_CONTAINER:-$(docker ps --format '{{.Names}}' | grep -iE 'redis' | head -n1 || true)}"
REDIS_SANDBOX_PORT=$((6379 + PORT_OFFSET))

if [[ -n "$REDIS_CONTAINER" ]]; then
  echo "    [Redis] Cloning state from '$REDIS_CONTAINER' into isolated sandbox container '${SANDBOX_PROJECT}_redis' on port $REDIS_SANDBOX_PORT..."
  docker exec "$REDIS_CONTAINER" redis-cli SAVE >/dev/null 2>&1 || true
  if ! docker ps -a --format '{{.Names}}' | grep -q "^${SANDBOX_PROJECT}_redis$"; then
    docker run -d --name "${SANDBOX_PROJECT}_redis" -p "${REDIS_SANDBOX_PORT}:6379" redis:alpine >/dev/null
    # Copy dump.rdb from main dev Redis so cached sessions/profiles/queues exist immediately
    TMP_RDB="$(mktemp)"
    if docker cp "${REDIS_CONTAINER}:/data/dump.rdb" "$TMP_RDB" 2>/dev/null; then
      docker stop "${SANDBOX_PROJECT}_redis" >/dev/null
      docker cp "$TMP_RDB" "${SANDBOX_PROJECT}_redis:/data/dump.rdb" 2>/dev/null || true
      docker start "${SANDBOX_PROJECT}_redis" >/dev/null
    fi
    rm -f "$TMP_RDB"
  fi
fi

# --- 4d. Optional Docker Named Volume Cloning ---
if [[ -n "${CLONE_DOCKER_VOLUMES:-}" ]]; then
  for SRC_VOL in $CLONE_DOCKER_VOLUMES; do
    DST_VOL="${SANDBOX_PROJECT}_${SRC_VOL}"
    echo "    [Volume] Cloning Docker volume '$SRC_VOL' -> '$DST_VOL'..."
    docker volume create "$DST_VOL" >/dev/null
    docker run --rm -v "${SRC_VOL}:/from:ro" -v "${DST_VOL}:/to" alpine sh -c "cd /from && cp -a . /to"
  done
fi

# 5. Wire sandboxed endpoints & port offsets into the worktree's .env
echo "==> [5/5] Writing sandbox configuration to $WT_DIR/.env.worktree and updating $WT_DIR/.env..."
cat > "$WT_DIR/.env.worktree" <<EOF
# Auto-generated by worktree-up.sh for ticket: $TICKET_ID
WORKTREE_ID=$TICKET_ID
SANDBOX_PROJECT=$SANDBOX_PROJECT
WT_SLOT=$WT_SLOT
PORT_OFFSET=$PORT_OFFSET
PG_TARGET_DB=$PG_TARGET_DB
MONGO_TARGET_DB=$MONGO_TARGET_DB
REDIS_SANDBOX_PORT=$REDIS_SANDBOX_PORT
EOF

if [[ -f "$WT_DIR/.env" ]]; then
  # Replace database name in DATABASE_URL / MONGO_URI and update REDIS_URL port
  if [[ -n "$PG_CONTAINER" ]]; then
    sed -i -E "s|(postgresql[^:]*://[^/]+/)${PG_SOURCE_DB}|\1${PG_TARGET_DB}|g" "$WT_DIR/.env" || true
    sed -i -E "s|^DB_NAME=.*|DB_NAME=${PG_TARGET_DB}|g" "$WT_DIR/.env" || true
  fi
  if [[ -n "$MONGO_CONTAINER" ]]; then
    sed -i -E "s|(mongodb[^:]*://[^/]+/)${MONGO_SOURCE_DB}|\1${MONGO_TARGET_DB}|g" "$WT_DIR/.env" || true
    sed -i -E "s|^MONGO_DB=.*|MONGO_DB=${MONGO_TARGET_DB}|g" "$WT_DIR/.env" || true
  fi
  if [[ -n "$REDIS_CONTAINER" ]]; then
    sed -i -E "s|(redis://[^:]+):6379|\1:${REDIS_SANDBOX_PORT}|g" "$WT_DIR/.env" || true
    sed -i -E "s|^REDIS_PORT=.*|REDIS_PORT=${REDIS_SANDBOX_PORT}|g" "$WT_DIR/.env" || true
  fi
fi

echo "✅ Worktree + Full Dev Sandbox ready at: $WT_DIR"
