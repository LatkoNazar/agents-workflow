---
name: handoff
description: "Save clean session state to a handoff file so you can /clear and keep <100k Smart Zone."
argument-hint: "[what will the next session focus on?]"
disable-model-invocation: true
---

# Clean Context Handoff (`/handoff`)

> **Why `/handoff` instead of `/compact`:** Compacting a long chat history accumulates "sediment" (abandoned hypotheses, old errors, and noisy logs). Instead, write a clean state artifact and run `/clear` (the Memento pattern).

## Process

1. Write a concise handoff file to `${TMPDIR:-/tmp}/handoff-$(date +%Y%m%d-%H%M%S).md` (never clutter the repo with ephemeral chat handoffs).
2. Structure the handoff document as:
   - **Goal for Next Session:** (Tailored to the user's argument if provided)
   - **Settled Decisions & Current State:** Bullet points of facts only (zero failed attempts or dead ends)
   - **Artifact Links (Do Not Duplicate Content):** Exact paths to specs (`.agents/specs/...`), tickets (`.agents/tickets/...`), branches, or commits
   - **Suggested Skills to Pull Next:** Which skill (`/to-spec`, `/to-tickets`, `/implement`, `/tdd`) the fresh session should invoke first
3. Redact any secrets or credentials.
4. Print the exact one-liner the user can paste after running `/clear`:
   ```text
   Read /tmp/handoff-<timestamp>.md and continue with <next-step>.
   ```
