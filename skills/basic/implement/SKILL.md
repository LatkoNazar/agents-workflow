---
name: implement
description: "Execute a ticket or DAG of tickets inside isolated Git worktrees with full Docker dev-state sandboxing, strict TDD, clean-context code review, and automated merging."
disable-model-invocation: true
---

# Implement Ticket(s) in Worktree Sandbox (`/implement`)

Execute one ticket (`/implement <ticket-id>`) or run the unblocked AFK ticket DAG (`/implement --all`) using isolated Git worktrees and cloned Docker dev sandboxes.

Supports **two execution engines** automatically:
1. **Native Sub-Agents (In-Chat Orchestration):** Uses your current AI environment's native sub-agent tool (Claude Code `Task`, Antigravity `invoke_subagent` / `swarm`, Codex/Cursor sub-agents) so every step (`Implementer`, `Reviewer`, `Merger`) runs in a fresh <100k token Smart Zone context window.
2. **Headless CLI Loop:** Delegates to `./.agents/scripts/afk-loop.sh` when requested for unattended terminal runs.

---

## Process for Native Sub-Agent Execution

### Step 1: Resolve Target Ticket(s)
- Read `.agents/workflow.json` and check `.agents/tickets/` (or configured Kanban tracker).
- If the user passed a `<ticket-id>`, verify its `blocked_by` dependencies are `done`.
- If the user passed `--all` (or no argument), find all unblocked tickets marked `status: ready-for-agent` (up to `maxParallelWorktrees`).

### Step 2: Spin Up Isolated Worktree + Cloned Docker Dev Sandbox
For each active `<ticket-id>`, run:
```bash
./.agents/scripts/worktree-up.sh <ticket-id>
```
This creates `.worktrees/wt-<ticket-id>` on branch `feat/<ticket-id>`, clones the live dev databases (Postgres, MongoDB, Redis), Docker volumes, and local profile/upload folders into sandbox `wt_<ticket-id>`, and writes `.env` with isolated ports.

### Step 3: Spawn Implementer Sub-Agent (Fresh Context)
Dispatch a fresh sub-agent rooted at `.worktrees/wt-<ticket-id>` with the instructions from `.agents/agents/implementer.md`:
- Build the complete **Vertical Slice** (`DB -> Deep Module Facade -> Contract Sync -> Frontend Feature -> Test`).
- Follow `/tdd` (Red -> Green against the public facade using the cloned sandbox DB).
- Run `./.agents/scripts/verify.sh` inside `.worktrees/wt-<ticket-id>` until 100% green.
- Commit all changes to `feat/<ticket-id>`.

### Step 4: Spawn Reviewer Sub-Agent (Fresh Context)
Dispatch a fresh sub-agent with the instructions from `.agents/agents/reviewer.md` and `/code-review`:
- Inspect `git diff main...HEAD` inside `.worktrees/wt-<ticket-id>`.
- If `REVIEW_DECISION: CHANGES_REQUESTED`, send the exact feedback to a fresh Implementer sub-agent and re-verify (up to `maxReviewIterations`).

### Step 5: Spawn Merger Sub-Agent & Destroy Sandbox
Once `REVIEW_DECISION: APPROVED`:
- Merge `feat/<ticket-id>` into the base branch (or open a PR if `mergeStrategy == "pr"`).
- Run `./.agents/scripts/verify.sh` on the base branch to verify integration.
- Mark the ticket as `done` in `.agents/tickets/<ticket-id>.md` (or tracker).
- Tear down the worktree and purge all cloned Docker databases/containers/volumes:
```bash
./.agents/scripts/worktree-down.sh <ticket-id> true
```
