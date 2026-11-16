---
name: code-review
description: "Two-axis clean-context code review: checks (1) Vertical Spec Completeness and (2) Pushed Project Standards & Deep Module Boundaries using isolated sub-agents."
---

# Independent Two-Axis Code Review (`/code-review`)

Review the changes between `HEAD` and a base ref (default: `main`) along two independent axes in **fresh sub-agent context windows**:

1. **Spec & Vertical Completeness Axis:** Does the diff implement the complete vertical slice requested by the ticket without scope creep or half-finished horizontal layers?
2. **Standards & Deep Module Axis (Push Model):** Does the diff obey all project coding standards, Deep Module boundaries, and Gray-Box testing rules?

---

## Process

### 1. Pin the Diff & Locate the Ticket/Spec
- Verify the diff command: `git diff <base>...HEAD` and commit history `git log <base>..HEAD --oneline`.
- Locate the originating ticket in `.agents/tickets/` (or configured tracker) and `.agents/agents/reviewer.md`.

### 2. Spawn Two Parallel Sub-Agents (Fresh Contexts)

#### Sub-Agent A: Spec & Vertical Slice Reviewer
Pass the ticket/spec and `git diff <base>...HEAD`:
- Verify every acceptance criterion in the ticket is met end-to-end (`DB/State -> Facade -> Contract -> Frontend/UI -> Test`).
- Flag any horizontal half-layer (e.g., schema or endpoint added without wiring or tests, or backend changed without updating `contracts/` and frontend types).
- Flag any scope creep (features or abstractions not requested in the ticket).

#### Sub-Agent B: Standards & Deep Architecture Reviewer (Push Model)
Push the project's `.agents/agents/reviewer.md` rules and the Fowler Code Smells baseline directly into its prompt:
- **Hard Architectural Violations:**
  1. Importing from another module's `internal/*` directory instead of its public facade.
  2. Mocking internal repositories/classes instead of testing the public facade against the sandbox DB.
  3. Breaking the Backend <-> Frontend contract bridge.
- **Judgement Calls / Code Smells:**
  - Shallow Module / Pass-Through Middle Man
  - Shotgun Surgery / Divergent Change
  - Mysterious Name / Primitive Obsession / Data Clumps
  - Duplicated Logic / Speculative Generality

### 3. Aggregate & Emit Verdict
Present `## 1. Spec & Vertical Completeness` and `## 2. Standards & Deep Module Architecture` side by side.
Conclude with:
- `REVIEW_DECISION: APPROVED` (if zero hard violations and spec is 100% satisfied)
- `REVIEW_DECISION: CHANGES_REQUESTED` (with a prioritized checklist of required fixes)
