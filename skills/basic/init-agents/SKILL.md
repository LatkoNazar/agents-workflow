---
name: init-agents
description: "Scaffold .agents/ workflow: setup Docker sandboxes, worktrees, multi-agent hooks, sub-agents, and AGENTS.md."
disable-model-invocation: true
---

# Initialize Project Agents (`/init-agents`)

Scaffold a tailored, project-specific agentic engineering system inside the current repository.

> **Language Rule:** Keep generated system prompts, `SKILL.md` files, and `AGENTS.md`/`CLAUDE.md` instructions in **English** for maximum LLM precision, but conduct the interactive interview with the user in the **user's language** (e.g., Ukrainian).

---

## Core Architectural Pillars (Always Enforce)

1. **Smart Zone Context (<100k tokens):** Never bloat `CLAUDE.md` or `AGENTS.md`. Use a **Pull model** for implementers (they load skills on demand) and a **Push model** for reviewers (project standards and architecture rules are injected directly into the reviewer's clean context).
2. **Vertical Slices (Tracer Bullets) Over Horizontal Layers:** Work and code must be organized around complete vertical slices (`DB/State -> Deep Module Facade -> API Contract -> Frontend/UI -> Integration Test`), never isolated horizontal layers (`all DB first, then all API, then all UI`).
3. **Deep Modules Over Shallow Modules:** Each domain vertical exposes a narrow public facade (`facade.py`, `index.ts`, etc.) and hides internal complexity (`internal/`). Tests live exclusively at the public facade seam against real (cloned sandbox) databases, mocking only external third-party I/O.
4. **Git Worktree + Full Dev-State Docker Sandbox:** Every ticket executes in an isolated Git worktree (`.worktrees/wt-<id>`) backed by an ephemeral clone of the main dev environment's state (Postgres, MongoDB, Redis, S3/MinIO, Docker volumes, local uploads/user profiles, `.env` with offset ports). When merged, the entire sandbox is destroyed.

---

## Process

### Phase 1: Silent Codebase Reconnaissance

Spawn an **Explorer sub-agent** with a fresh context window (or inspect directly if the repo is brand new/empty) to gather facts before asking the user any questions:

1. **Languages & Frameworks:** Detect backend and frontend stacks (e.g., Python/FastAPI, Go, Node/NestJS, Rust, TypeScript/React/Next.js) and whether this is a polyglot repo or monorepo.
2. **Existing Module Structure:** Check whether code is grouped vertically by domain/feature (`modules/*`, `features/*`) or horizontally (`controllers/`, `services/`, `models/`).
3. **Dev Environment & Stateful Services:** Inspect `docker-compose*.yml`, `.env*`, and local data directories to list all stateful services used by the main dev app:
   - Relational DBs (Postgres, MySQL, SQLite)
   - Document/KV/Search stores (MongoDB, Redis, Elasticsearch, Qdrant)
   - Storage/Queues (MinIO/S3, RabbitMQ, Kafka, local `uploads/` or `profiles/` directories)
4. **Verification Toolchain:** Find existing test runners (`pytest`, `vitest`, `go test`, `playwright`), typecheckers (`tsc`, `mypy`, `pyright`), linters (`ruff`, `biome`, `eslint`), and contract generators (`openapi`, `orval`, `openapi-typescript`, `buf`/`protobuf`, `graphql-codegen`).
5. **Installed Skills Check & Stack Skill Discovery (`find-skills`):** Check `.agents/skills/` and `.claude/skills/` to see which `basic` skills are already installed, and optionally run `npx skills find <detected-framework>` (via the `find-skills` workflow) to see if official stack-specific skills (e.g. `vercel-labs/agent-skills` for React/Next.js) match the project's stack.

---

### Phase 2: Focused Grill-Me Interview

Present a concise summary of what you discovered in Phase 1. Then interview the user in rounds (using the `grill-me` format: numbered questions with `➡️ Recommended answer` based on your reconnaissance).

Cover these four decision branches (skip any question already answered by the user):

```markdown
❓ **Q1 — Kanban & Spec Tracker**: Where should specs (PRDs) and the vertical-slice ticket DAG (`blocked_by`, `AFK` / `HITL`) live for this project?
- `local` — Markdown files inside `.agents/specs/` and `.agents/tickets/` (zero external setup, ideal for solo/local flow)
- `github` — GitHub Issues via `gh` CLI
- `trello` / `linear` / `jira` — External board (via MCP/CLI or synced markdown)

➡️ Recommended: <your recommendation based on repo setup>

---

❓ **Q2 — Full Dev-State Sandbox for Worktrees**: When spinning up `.worktrees/wt-<id>`, which stateful services and data folders from your main dev app should `worktree-up.sh` clone and isolate?
(Detected: <list detected Postgres/Mongo/Redis/volumes/folders>)

➡️ Recommended: Clone <detected DBs, Redis, volumes, and profile/upload dirs> into an isolated `docker compose -p wt_<id>` sandbox with automatic `PORT_OFFSET`, and destroy them in `worktree-down.sh` after merge.

---

❓ **Q3 — Vertical Modules, Contract Bridge & Frontend Verification (`lint-ui.sh` + `chrome-devtools-mcp`)**:
1. **Vertical Modules & Contracts:** How should we enforce vertical slices (`modules/<domain>/facade.*` + `features/<domain>/index.*`) and automatic Backend <-> Frontend contract sync?
2. **Optional UI Design-Token & Anti-Slop Linter (`lint-ui.sh`):** Should we generate a deterministic UI linter tailored to this project's styling stack (`<detected: Tailwind/CVA, CSS Modules, SCSS, etc.>`)?
   - **Why it helps (Benefits):**
     - **0 prompt tokens wasted:** Enforces your design tokens, UI primitives (`components/ui/*`), and anti-slop rules deterministically in 0.1s during `verify.sh` instead of bloating prompts with a huge `DESIGN.md`.
     - **Blocks style chaos in `features/*`:** Prevents agents from hardcoding `#hex`/`rgb()` colors, inline `style={{}}`, arbitrary `[...]` values, dead `href="#"` links, or mock arrays in UI components.
   - *(If you decline, we will set `architecture.uiLinter.enabled: false` in `workflow.json` and skip CSS/token linting completely.)*
3. **Browser Verification via Chrome DevTools MCP (`.mcp.json`):** For frontend projects, should we wire `chrome-devtools-mcp` into `.mcp.json` so the `tester` sub-agent can inspect live Console, Network requests, Computed CSS/Geometry, and compare screenshots (`1440x900` & `390x844`) against your UI references?

➡️ Recommended: <Define target vertical module paths + enable `lint-ui.sh` + configure `chrome-devtools-mcp` in `.mcp.json`>.

---

❓ **Q4 — Focused Agent Roles, Models & Orchestration Mode**: Which specialized sub-agents and default execution pipeline should we configure in `.agents/workflow.json`?
- **Core Roles:**
  1. `explorer` (fast/cheap model for codebase reconnaissance; returns 100% contracts/paths and 0% internal code bodies)
  2. `implementer` (vertical-slice builder: DB -> Deep Module Facade -> Contract -> UI + strict TDD with fast `verify.sh --affected`)
  3. `tester` (smart verification & log-shield sub-agent: picks test blast radius from `git diff`, absorbs raw logs, returns concise diagnosis)
  4. `reviewer` (fresh context, stronger model, pushed coding & architecture standards)
  5. `merger` (merges worktree branch, resolves conflicts, runs final `verify.sh --full`, tears down Docker sandbox)
  6. *(Optional domain-specific agents based on repo)*
- **Orchestration Mode:** `single-ticket`, `sequential-with-review`, or `parallel-dag-with-review`

➡️ Recommended: Configure the 5 core roles (+ <any project-specific role>), route `implementer`/`tester` to <Sonnet/default> and `reviewer` to <Opus/top reasoning model>, with `parallel-dag-with-review` as the default mode.
```

Wait for the user's confirmation or adjustments before generating files.

---

### Phase 3: Ensure Basic Skills Are Present

Ensure the core workflow skills exist in `.agents/skills/` (and are linked into `.claude/skills/` if `.claude` is used):
- `init-agents`
- `find-skills`
- `grill-me`
- `handoff`
- `antislop`
- `ui-from-reference`
- `to-spec`
- `to-tickets`
- `tdd`
- `ddd`
- `code-review`
- `implement`
- `codebase-design`
- `improve-architecture`

If the user installed only `init-agents` via `npx skills add <repo> --skill init-agents`, copy or install the remaining basic skills from the same repository source (or run `npx skills add <repo-url>`).

---

### Phase 4: Generate Project `.agents/` Infrastructure

Using the templates in `./templates/` as your baseline, customize and write the following files into the target repository:

1. **`.agents/workflow.json`** (from `templates/workflow.json.tpl`):
   - Record the chosen Kanban provider (`local`, `github`, `trello`, `linear`), paths, and label conventions.
   - Configure the `sandbox` section: main dev compose project/containers, volumes/databases to clone (`postgres`, `mongo`, `redis`, `volumes`, `copyPaths`), base ports, and `portOffsetStep`.
   - Configure `architecture`: vertical module directories, facade file patterns, internal directory restrictions, and contract sync commands.
   - Configure `orchestration`: default template (`single-ticket`, `sequential-with-review`, `parallel-dag-with-review`), max parallel worktrees, max review retries, merge strategy (`auto-merge` or `pr`), and per-role provider/model routing (`explorer`, `planner`, `implementer`, `reviewer`, `merger`).

2. **`.agents/scripts/worktree-up.sh`** (from `templates/scripts/worktree-up.sh`, `chmod +x`):
   - Creates `.worktrees/wt-<ticket-id>` on branch `feat/<ticket-id>`.
   - Links/installs dependencies (`node_modules`, `.venv`, etc.).
   - Allocates a unique `WT_SLOT` and `PORT_OFFSET`.
   - Clones the full dev state (Postgres template/dump, Mongo archive clone, Redis RDB snapshot, Docker volume copy, and CoW copy of local profile/upload folders) into an isolated `wt_<ticket-id>` Docker sandbox.
   - Generates `.worktrees/wt-<ticket-id>/.env` pointing to the sandboxed services and ports.

3. **`.agents/scripts/worktree-down.sh`** (from `templates/scripts/worktree-down.sh`, `chmod +x`):
   - Stops and removes all containers, networks, and cloned volumes for `wt_<ticket-id>` (`docker compose -p wt_<ticket-id> down -v --remove-orphans` + drops any template-cloned DBs).
   - Removes the Git worktree `.worktrees/wt-<ticket-id>` and cleans up temporary resources.

4. **`.agents/scripts/verify.sh`** (from `templates/scripts/verify.sh`, `chmod +x`):
   - Customized to the project's actual stack.
   - Runs in strict vertical order:
     1. Module boundary check (no cross-imports into another module's `internal/`).
     2. Backend integration/facade tests against the sandbox DB/services.
     3. Contract export & frontend client/mock codegen (if multi-language / full-stack).
     4. Frontend typecheck (`tsc --noEmit`), linter, and feature tests.

5. **`.agents/scripts/afk-loop.sh`** (from `templates/scripts/afk-loop.sh`, `chmod +x`):
   - Terminal orchestrator for AFK execution (`./.agents/scripts/afk-loop.sh [ticket-id | --all]`).
   - Supports `single-ticket`, `sequential-with-review`, and `parallel-dag-with-review` across unblocked `AFK` tickets using the CLI commands and models configured in `.agents/workflow.json`.

6. **Focused Sub-Agents in `.agents/agents/*.md`** (from `templates/agents/*.md`):
   - Generate `explorer.md`, `implementer.md`, `tester.md`, `reviewer.md`, `merger.md`, plus any agreed domain-specific sub-agents.
   - Inject the project's exact coding standards, deep-module rules, and vertical-slice requirements directly into `reviewer.md` (**Push model**).
   - Symlink or copy `.agents/agents/*.md` into `.claude/agents/` so Claude Code, Antigravity, and other tools discover them natively.

7. **Agent Hooks Auto-Setup (`setup-hooks.sh`) & Chrome DevTools MCP (`.mcp.json`)**:
   - Copy `hook-pre-bash.sh`, `hook-stop-verify.sh`, and `setup-hooks.sh` from `templates/scripts/` into `.agents/scripts/` (`chmod +x`).
   - Run `./.agents/scripts/setup-hooks.sh`: it checks if native agent hooks exist for **Claude Code** (`.claude/settings.json`), **Codex CLI** (`.codex/hooks.json`), **Gemini CLI** (`.gemini/settings.json`), and **Cursor** (`.cursor/hooks.json`), and creates/merges all 4 simultaneously if missing:
     - **`PreToolUse` (`hook-pre-bash.sh`):** Hard-blocks (`deny`) destructive commands (`git push --force`, `git reset --hard`, `git clean -f`, `git add .env`, `rm -rf ..`) and prompts the user (`ask`) before any normal `git push` so you always control remote pushes.
     - **`Stop` (`hook-stop-verify.sh`):** Automatically runs `./.agents/scripts/verify.sh --affected` when code was modified before allowing the agent to finish its turn.
   - If the project has a frontend and `browserMcp.enabled == true`, create or merge `chrome-devtools` (`npx -y chrome-devtools-mcp@latest --headless --isolated`) into `.mcp.json` at the repo root.

8. **Kanban Directories & Glossary**:
   - If `kanban.provider == "local"`, create `.agents/specs/` and `.agents/tickets/`.
   - Create or update `GLOSSARY.md` at the repo root with core domain terms discovered during reconnaissance.
   - Ensure `.worktrees/` is added to `.gitignore`.

9. **Concise `AGENTS.md`** (from `templates/AGENTS.md.tpl`):
   - Create or update `AGENTS.md` at the repository root (supported natively by Claude Code, Codex, Antigravity, Cursor, and Windsurf—no duplicate `CLAUDE.md` needed).
   - Keep it **under 100 lines** so every session starts cleanly inside the Smart Zone (<100k tokens).
