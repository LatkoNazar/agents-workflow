---
name: grill-me
description: "Relentlessly interview the user about a feature, plan, or architecture design one decision frontier at a time, offering recommended answers until shared understanding is reached."
disable-model-invocation: true
---

# Grill Me (`/grill-me`)

Interview the user relentlessly until you reach a 100% shared design understanding before writing any spec or code.

> **Language Rule:** Always conduct the interview in the user's language (e.g., Ukrainian), while keeping technical identifiers accurate.

## Process

1. **Map the Design Tree:** Treat every feature or architectural idea as a decision tree. The **frontier** is the set of decisions whose prerequisites are already settled.
2. **Delegate Fact-Finding to Sub-Agents:** Never ask the user a question that can be answered by reading the codebase! Spawn an `explorer` sub-agent in a fresh context window to inspect existing modules, schemas, or contracts first.
3. **Work in Focused Rounds:**
   - Ask 1–2 frontier questions per round.
   - Always provide a concrete **recommended answer** (`➡️ Recommended: ...`) grounded in **Vertical Slices (Tracer Bullets)** and **Deep Modules** so the user can simply reply "так" / "yes" to accept it.
   - If your runtime provides a native interactive question tool (such as `ask_question`), use it with `(Recommended)` on the first option; otherwise format the round as:

```markdown
❓ **Q1 — <Question Title>**: <Concise question & options>

➡️ **Recommended**: <Your recommended choice and 1-sentence rationale>
```

4. **Recompute the Frontier:** Each answer unlocks the next layer of decisions (module boundaries, public facade signatures, contract changes, test seams, edge cases, out-of-scope boundaries).
5. **Completion:** Stop grilling only when every branch of the design tree is settled. Then ask the user if they want to run `/to-spec` to generate the PRD.
