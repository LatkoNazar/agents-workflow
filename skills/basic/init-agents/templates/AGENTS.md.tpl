# {{PROJECT_NAME}} — Agent Engineering Guidelines

> **Smart Zone Rule:** Keep context lean (<100k tokens). Delegate broad codebase searches to the `explorer` sub-agent so raw file dumps stay out of the main context window.

## 1. Architecture: Vertical Slices & Deep Modules

- **Vertical Slices Only (Tracer Bullets):** Every ticket and commit must deliver a complete, testable vertical path (`DB/State -> Deep Module Facade -> Contract -> UI/Client -> Test`). Never implement horizontal layers in isolation.
- **Deep Modules:** Domain logic lives inside vertical modules (`{{VERTICAL_ROOTS}}`).
  - Each module exposes **one narrow public interface** (`facade.py` / `facade.ts` / `index.ts`).
  - Everything else lives inside `internal/`.
  - **Strict Boundary Rule:** Never import from another module's `internal/*` directory. Always go through its public facade.
- **Testing at the Seam:** Write integration tests against the module's public facade using the sandboxed database/services. Never mock internal classes or repositories; only mock external third-party I/O adapters.

## 2. Workflow & Skills (Pull Model)

Config lives in `.agents/workflow.json`. Domain vocabulary lives in `GLOSSARY.md`.

1. **Alignment (`/grill-me`):** Relentless decision-tree interview before writing any spec or code.
2. **Specification (`/to-spec`):** Synthesize decisions into a PRD under `{{SPECS_DIR}}` (or configured tracker).
3. **Vertical Slicing (`/to-tickets`):** Break the PRD into tracer-bullet tickets with `blocked_by` edges and `afk` / `hitl` tags in `{{TICKETS_DIR}}`.
4. **Implementation (`/implement <ticket-id>`):**
   - Spins up an isolated Git worktree + cloned Docker dev sandbox (`./.agents/scripts/worktree-up.sh <id>`).
   - **Implementer** executes strict Red-Green-Refactor (`/tdd`) and runs `./.agents/scripts/verify.sh`.
   - **Reviewer** checks the diff in a fresh context window (`/code-review`) with pushed project standards.
   - **Merger** merges the branch, runs `./.agents/scripts/verify.sh`, and destroys the sandbox (`./.agents/scripts/worktree-down.sh <id>`).

## 3. Key Commands

- **Verify entire vertical loop:** `./.agents/scripts/verify.sh`
- **Create worktree + clone dev Docker state:** `./.agents/scripts/worktree-up.sh <ticket-id>`
- **Destroy worktree + purge Docker sandbox:** `./.agents/scripts/worktree-down.sh <ticket-id>`
- **Run autonomous AFK loop:** `./.agents/scripts/afk-loop.sh`
