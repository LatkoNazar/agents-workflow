---
name: diagnosing-bugs
description: "Reproduce, isolate, and fix bugs inside an isolated Git worktree backed by a full clone of the live dev database, Redis, Mongo, and user profiles."
disable-model-invocation: true
---

# Diagnose & Fix Bugs in Cloned Dev Sandbox (`/diagnosing-bugs`)

Never debug destructive state issues directly on the main dev database, and never waste time manually seeding fake reproduction data when the bug already reproduces against your dev state.

## Process

1. **Spin Up a Bugfix Worktree + Full Dev-State Clone:**
   ```bash
   ./.agents/scripts/worktree-up.sh bug-<short-slug>
   ```
   This gives you an exact, isolated copy of all dev users, profiles, Postgres/Mongo tables, and Redis caches.
2. **Write a Failing Regression Test at the Public Seam (`RED`):**
   - Reproduce the bug by writing an integration test against the vertical module's public facade (`facade.*` / `index.*`) using the cloned state.
   - Confirm the test fails with the exact reported symptom.
3. **Fix & Verify (`GREEN`):**
   - Fix the root cause inside the module's `internal/` implementation.
   - Run `./.agents/scripts/verify.sh` to verify the regression test passes and no contracts or neighbor modules broke.
4. **Review, Merge & Purge Sandbox:**
   - Run `/code-review`, merge into the base branch, and execute `./.agents/scripts/worktree-down.sh bug-<short-slug> true`.
