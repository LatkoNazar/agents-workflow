---
name: design-an-interface
description: "Apply John Ousterhout's 'Design It Twice' principle: spawn parallel sub-agents to propose radically different Deep Module facade interfaces before choosing the deepest, cleanest boundary."
disable-model-invocation: true
---

# Design an Interface — "Design It Twice" (`/design-an-interface`)

Before locking in a new vertical module's public facade (`facade.py`, `facade.ts`, `index.ts`), explore multiple radically different designs in parallel sub-agents.

## Process

1. **Frame the Capability & Constraints:**
   State what domain problem the vertical module solves and what callers need from it.
2. **Spawn 2–3 Parallel Sub-Agents in Fresh Contexts:**
   Ask each sub-agent to design a **radically different** public interface for the module:
   - **Option A (Minimalist Deep Facade):** Maximum hidden complexity behind 1–2 high-level declarative functions/methods.
   - **Option B (Data-Driven / Pipeline Interface):** Composable value-object or batch contract.
   - **Option C (Stateful / Event-Driven Boundary):** Alternative seam trade-off.
3. **Compare Trade-Offs & Grill:**
   Present the candidate signatures side by side, comparing:
   - **Depth** (how much complexity is hidden from callers?)
   - **Seam Testability** (how easy is it to write gray-box integration tests against this facade?)
   - **Locality** (does changing internal rules require changing the signature?)
   Recommend the strongest design and confirm with the user.
