---
name: to-spec
description: "Synthesize the current conversation and grill-me decisions into a destination PRD (Product Requirements Document) defining User Stories, Deep Module facades, Contract changes, Test Seams, and Out of Scope."
disable-model-invocation: true
---

# Generate PRD / Destination Spec (`/to-spec`)

Synthesize the alignment reached during `/grill-me` into a structured Product Requirements Document (PRD) and save it to the tracker configured in `.agents/workflow.json` (default: `.agents/specs/<YYYY-MM-DD>-<feature-slug>.md`).

Do **not** re-interview the user; summarize the settled decisions cleanly.

## Process

1. **Check `.agents/workflow.json` and `GLOSSARY.md`:** Use the project's exact domain vocabulary and configured spec destination (`kanban.specsDir` or external issue tracker).
2. **Verify Gray-Box Seams:** Specify only **public module facade signatures** (`facade.py`, `facade.ts`, `index.ts`) and **cross-language contracts** (`openapi.json`, `.proto`). Never dictate how the implementer should split internal helper files inside `internal/` (**Rule of Gray Box**).
3. **Write the Spec using the Template Below:**

```markdown
# PRD: <Feature Title>

- **Status:** ready-for-tickets
- **Created:** <YYYY-MM-DD>

## 1. Problem Statement
What problem the user is facing, from the user's perspective.

## 2. Solution Overview
High-level end-to-end solution and how the user experiences it.

## 3. User Stories
1. As a <actor>, I want <capability>, so that <benefit>.
2. ...

## 4. Deep Module & Contract Decisions (Rule of Gray Box)
- **Target Vertical Modules:** Which modules under `modules/` and `features/` will be created or modified.
- **Public Facade Signatures:** Input/output contracts and invariants at the module boundary (do not prescribe `internal/` file layouts).
- **Data & State Changes:** Database schema/migrations, Redis/Mongo keys, or storage changes.
- **Cross-Language Contract Bridge:** OpenAPI / Protobuf / GraphQL schema updates that stitch Backend and Frontend together.

## 5. Planned Vertical Slices (Tracer Bullets Preview)
Outline how this feature will be sliced vertically (starting with Slice #1: the thinnest end-to-end Tracer Bullet from DB to UI) so no horizontal layer is ever built in isolation.

## 6. Testing Decisions & Seams
- **Primary Test Seam:** Which public facade methods and frontend feature entrypoints will be integration-tested against the cloned Docker dev sandbox.
- **External Adapters to Mock:** Only true external third-party APIs (Stripe, LLM, external webhooks). Internal DBs and repositories are NEVER mocked.

## 7. Out of Scope
Explicit list of features, edge cases, or optimizations intentionally excluded from this PRD.
```

4. **Doc-Rot Prevention:** Remind the user that once all tickets from this PRD are implemented and merged, temporary specs can be archived or closed so future agents never read stale requirements.
