---
name: tdd
description: "Strict Red-Green-Refactor Test-Driven Development at the Deep Module facade boundary against real cloned sandbox databases."
---

# Strict Test-Driven Development (`/tdd`)

TDD is the non-negotiable guardrail that prevents AI agents from writing superficial tests that merely mirror broken implementation code.

## Core Rules

1. **Test at the Public Facade Seam Only:**
   - Every vertical module exposes a narrow public interface (`facade.py`, `facade.ts`, `index.ts`).
   - Write integration tests directly against that public facade. Never write unit tests for internal helper files (`internal/validator.py`, `internal/mapper.py`, `internal/repository.py`).
2. **Real Sandbox State Over Internal Mocks:**
   - Run tests against the worktree's cloned Docker sandbox (Postgres, MongoDB, Redis, local storage).
   - **Never mock internal repositories, ORM models, or neighbor modules.**
   - **Only mock external third-party I/O boundaries** (e.g., Stripe API, external LLMs, third-party webhooks) via in-memory fake adapters injected into the facade.
3. **Vertical Red -> Green Loops (One Tracer Bullet at a Time):**
   - Do **not** write 15 failing tests up front (horizontal testing).
   - Write **one** failing behavioral test (`RED`), run the test runner to confirm it fails for the expected reason, write the minimal vertical implementation to pass it (`GREEN`), and repeat.
4. **No Tautological Assertions:**
   - Never recompute the expected value using the same formula as the production code. Assert against concrete, independent expected values from the spec.
