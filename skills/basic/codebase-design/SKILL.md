---
name: codebase-design
description: "Deep Module architecture rules: narrow public facades, hidden internals, seams & locality."
---

# Codebase Design: Deep Modules & Vertical Slices

Consult this reference whenever designing new modules, slicing features, or reviewing architecture.

## Core Vocabulary

1. **Module & Depth:**
   - A **Deep Module** has a narrow, simple **public interface** (`facade.py`, `facade.ts`, `index.ts`) hiding substantial internal functionality (`internal/`).
   - A **Shallow Module** has an interface nearly as complex as its implementation (e.g., fragmented `UserValidator`, `SubscriptionRepo`, `QuotaCalculator` classes called directly by a router). Avoid shallow modules; merge them behind a single domain facade.
2. **Vertical Slice vs. Horizontal Layer:**
   - Group files by **business vertical** (`backend/src/modules/orders/`, `frontend/src/features/orders/`), never by horizontal technical layer (`controllers/`, `services/`, `repositories/`).
   - Every vertical slice connects `DB/State -> Deep Module Facade -> Contract -> Frontend Feature`.
3. **Seam & Gray-Box Testing:**
   - A **Seam** is the public facade boundary where tests observe behavior without knowing internal file structure.
   - Treat every Deep Module as a **Gray Box**: specify only its public facade inputs/outputs and database invariants; let the implementer freely refactor `internal/` as long as facade integration tests pass.
4. **Adapter:**
   - Only true external systems (Stripe, S3, LLM APIs, external exchanges) get injected as ports/adapters for in-memory test fakes. Internal databases run for real inside the cloned Docker sandbox.
5. **Locality & The Deletion Test:**
   - Understanding or changing one domain concept should happen inside one vertical module directory (**high locality**).
   - **Deletion Test:** If deleting an internal layer/wrapper concentrates complexity rather than scattering it, delete the wrapper.
