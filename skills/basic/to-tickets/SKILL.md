---
name: to-tickets
description: "Break an approved PRD or conversation into a Kanban DAG of vertical tracer-bullet tickets with explicit blocked_by dependencies and AFK/HITL execution markers."
disable-model-invocation: true
---

# Slice PRD into Vertical Kanban DAG (`/to-tickets`)

Convert a PRD or spec into a directed acyclic graph (DAG) of independently grabbable **Vertical Slice (Tracer Bullet)** tickets and publish them to the Kanban storage configured in `.agents/workflow.json`.

---

## Iron Law: Vertical Slices Only (Zero Horizontal Tickets)

**FORBIDDEN (Horizontal Layers):**
- ❌ Ticket 1: "Create database tables and migrations"
- ❌ Ticket 2: "Implement backend repository and service methods"
- ❌ Ticket 3: "Add API endpoints"
- ❌ Ticket 4: "Build React UI page"

Why horizontal slicing fails: if an integration or contract assumption is wrong in Ticket 1, you only discover it in Ticket 4 after burning 300k+ tokens and have to rewrite the entire chain from scratch.

**MANDATORY (Vertical Tracer Bullets):**
- ✅ **Ticket 01 (The Tracer Bullet):** Cuts a thin, complete path through **every** layer (`DB migration -> Deep Module facade method -> Contract export -> Frontend UI/client call -> End-to-end integration test`) for the core happy path. Proves the entire vertical pipeline works on iteration #1.
- ✅ **Tickets 02..N:** Each subsequent ticket adds a complete vertical capability or scenario end-to-end (DB -> Facade -> Contract -> UI -> Test), leaving `./.agents/scripts/verify.sh` 100% green after every single ticket.
- **Sized for the Smart Zone:** Each ticket must be completable inside a single fresh context window (<100k tokens).

*(Exception: Only a mechanical codebase-wide rename/refactor may use an Expand -> Migrate -> Contract sequence.)*

---

## Process

1. **Read the PRD & `.agents/workflow.json`:** Identify the configured Kanban provider (`local`, `github`, `trello`, `linear`) and target directories.
2. **Draft the Vertical Slice DAG:**
   - Assign each ticket:
     - `id`: e.g., `001-<slug>`, `002-<slug>`
     - `mode`: `afk` (autonomous worktree agent can execute without human intervention) or `hitl` (requires human-in-the-loop taste/UX review)
     - `blocked_by`: list of ticket IDs that must reach `done` before this ticket can start (`[]` if unblocked)
3. **Present the DAG to the User for Approval:**
   Show a concise summary table and Mermaid DAG (`flowchart LR`) of the proposed vertical slices and their `blocked_by` edges. Ask the user to confirm before writing the tickets.
4. **Publish Tickets to Configured Kanban:**
   - **If `kanban.provider == "local"`:** Write one Markdown file per ticket in `.agents/tickets/<NNN>-<slug>.md` using the template below.
   - **If `kanban.provider == "github"`:** Create issues via `gh issue create` in dependency order, applying `ready-for-agent` and `afk`/`hitl` labels.
   - **If `kanban.provider == "trello"` / `"linear"` / `"jira"`:** Create cards/issues using the configured MCP or CLI adapter, and optionally mirror the DAG in `.agents/tickets/` for the local worktree runner.

### Local Ticket File Template (`.agents/tickets/<NNN>-<slug>.md`)

```markdown
---
id: "<NNN>-<slug>"
title: "<Short Vertical Slice Title>"
status: ready-for-agent
mode: afk
blocked_by: []
spec: ".agents/specs/<spec-file>.md"
---

# <NNN>: <Short Vertical Slice Title>

## Vertical Slice Behavior (End-to-End)
Describe the user-observable behavior this slice makes work from start to finish.

## Layers Touched in This Slice
- **State / DB:** <migration / schema / seed changes>
- **Backend Deep Module Facade:** <module & public facade signature>
- **Contract Sync:** <OpenAPI / Protobuf schema changes>
- **Frontend Feature:** <feature component / hook / client usage>

## Seam Tests & Acceptance Criteria
- [ ] Failing facade integration test written first (Red -> Green) against cloned sandbox DB
- [ ] Contract exported and frontend types regenerated (`verify.sh --contracts-only`)
- [ ] Frontend feature test / typecheck green
- [ ] Full `./.agents/scripts/verify.sh` passes with zero errors
```
