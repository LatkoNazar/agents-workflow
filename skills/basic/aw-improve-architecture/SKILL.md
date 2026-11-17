---
name: aw-improve-architecture
description: "Audit codebase architecture: detect shallow horizontal layers and refactor into deep modules."
argument-hint: "[target module or directory]"
disable-model-invocation: true
---

# Improve Codebase Architecture (`/aw-improve-architecture`)

Scan the repository for architectural friction—especially **shallow modules**, **horizontal layer scattering**, and **internal-mocked unit tests**—and guide the user through consolidating them into **Deep Vertical Modules**.

## Process

1. **Delegate Exploration to `explorer` Sub-Agent:**
   - Inspect recent git hotspots (`git log --oneline -n 50`) and module directories.
   - Look for:
     - **Horizontal Scattering:** One feature requiring edits across global `controllers/`, `services/`, `repositories/`, `validators/`, `mappers/`.
     - **Shallow Modules:** Classes/files whose interface is as complex as their implementation (failing the Deletion Test).
     - **Leaky Boundaries:** Cross-module imports reaching directly into another module's internal models or helpers.
     - **Mock-Heavy Tests:** Unit tests that mock internal repositories instead of testing a public facade against the sandbox DB.
2. **Present Candidates Ranked by Leverage:**
   For each candidate, show:
   - **Files Involved**
   - **Friction (Shallow / Horizontal Problem)**
   - **Proposed Deep Vertical Module (`facade` + `internal/` + Seam Test)**
   - **Before vs. After Mermaid Diagram**
3. **Grill & Convert to Tickets:**
   Once the user selects a candidate, use `/aw-grill-me` to confirm the new public facade signature and `/aw-to-tickets` to plan the safe refactor.
