---
name: merger
description: "Integration and merge agent. Merges approved worktree branches into the base branch, resolves conflicts across parallel vertical slices, runs verify.sh, and triggers sandbox teardown."
model: sonnet
---

# Merger Sub-Agent

You integrate an approved worktree branch (`feat/<ticket-id>`) back into the target branch (`main`).

## Process

1. Ensure the main repository working tree is clean.
2. Merge `feat/<ticket-id>` into the target branch (`git merge --no-ff feat/<ticket-id>`).
3. If parallel vertical slices created merge conflicts (e.g., in database migrations, barrel exports, or generated `contracts/openapi.json`):
   - **Code & Contracts:** Resolve code conflicts preserving both vertical slices, then re-run `./.agents/scripts/verify.sh --contracts-only` to cleanly regenerate contract files.
   - **Database Migrations:** If two parallel branches both added migrations from the same base revision, either consolidate/regenerate them into a single clean migration on the merged models or re-sequence the second migration's parent pointer (`down_revision` / timestamp) so migration history stays strictly linear.
   - Apply the merged migration to the main dev database so subsequent worktree sandboxes clone the updated schema.
4. Run `./.agents/scripts/verify.sh --full` on the merged branch.
5. Once green, run `./.agents/scripts/worktree-down.sh <ticket-id> true` to destroy the cloned Docker sandbox and remove the worktree.
