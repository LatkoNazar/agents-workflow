---
name: code-simplification
description: "Refactor working, green-tested code for maximum clarity and flat control flow while preserving 100% of external behavior, types, and test results."
disable-model-invocation: true
---

# Code Simplification (`/code-simplification`)

Use this skill after a vertical slice passes all tests (`./.agents/scripts/verify.sh`), or during review when `internal/` implementation has accumulated deep nesting, duplication, or convoluted control flow.

> **Core Test:** *"Would a new engineer understand this module in half the time without changing a single external behavior?"*

---

## The 5 Rules of Simplification

1. **Preserve Behavior 100%:**
   - Inputs, outputs, side effects, error types, and public facade signatures (`facade.py`, `facade.ts`, `index.ts`) must remain **identical**.
   - Existing facade integration tests must pass **without modifying the tests**.
2. **Flatten Control Flow (Guard Clauses Over Arrow Anti-Pattern):**
   - Replace 3–4 levels of nested `if / else` blocks with early returns (`if (!valid) return ...`).
   - Extract complex boolean conditions into well-named local variables or small private helpers inside `internal/`.
3. **Prefer Clarity Over Cleverness:**
   - Replace nested ternaries (`a ? (b ? x : y) : z`) and cryptic reduce chains with readable, linear statements.
4. **Delete Speculative Dead Weight (YAGNI):**
   - Remove unused parameters, single-implementation wrapper classes (Shallow Middle Men), and premature configuration flags not required by the spec.
5. **Match Repository Conventions:**
   - Align naming, error handling, and import ordering with the rest of the repository and `GLOSSARY.md`.
   - Re-run `./.agents/scripts/verify.sh --affected` after every simplification step.
