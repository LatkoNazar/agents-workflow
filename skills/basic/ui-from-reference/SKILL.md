---
name: ui-from-reference
description: "Build UI 1:1 from screenshot using 0..100% coordinate grid & parallel cluster sub-agents."
argument-hint: "<path-to-reference.png> [optional-elements-ref.png]"
disable-model-invocation: true
---

# Reference-First UI Builder (`/ui-from-reference`)

Eliminate AI UI slop and prevent skipped details by decomposing a visual reference image (`reference.png`, plus an optional component/container sheet `elements-ref.png`) into **3–5 macro-clusters**, building each cluster in an isolated parallel sub-agent, and verifying the live browser render against the same `0..100%` coordinate grid.

---

## Phase 1: Shared Foundation, Grid & Cluster Slicing (Main Agent Only)

To guarantee parallel sub-agents **never collide on files**, the main agent prepares the shared tokens, crops, and shell before spawning any workers:

1. **Overlay the `0..100%` Coordinate Grid:**
   ```bash
   ./.agents/scripts/ui-ref.py grid <reference.png>
   ```
   Inspect `<reference>-grid.png` to read the exact percentage bounds (`0%..100%` on X and Y) of the major layout zones.

2. **Extract Shared Design Tokens Once (`READ-ONLY` for Workers):**
   - Inspect `<reference>-grid.png` (and `elements-ref.png` if provided).
   - Extract the exact background surfaces, border colors, accent colors, border radii, shadows, and typography scale into the project's theme file (`tokens.css` / `tailwind.config`).
   - Once written, `tokens.css` and `components/ui/*` are **locked as READ-ONLY** for all parallel cluster workers.

3. **Crop into 3–5 Macro-Clusters ("Big Spots"):**
   - Identify 3–5 non-overlapping macro-zones on the screen (e.g., `sidebar`, `topbar`, `stats`, `table`). Do not over-fragment into 20 tiny pieces.
   - Run the cropper to generate high-resolution close-ups for each cluster:
     ```bash
     ./.agents/scripts/ui-ref.py crop <reference.png> /tmp/ui-clusters \
       sidebar=0,0,18,100 \
       topbar=18,0,100,9 \
       stats=18,9,100,28 \
       table=18,28,100,100
     ```

4. **Create the Outer Page Layout Shell & File Contracts:**
   - Create the parent layout file (e.g., `src/features/<feature>/<Feature>Page.tsx`) with the exact percentage/grid slots matching the `0..100%` grid.
   - Define the TypeScript `Props` interface for each cluster (wired to the real backend vertical-slice facade—no mock data) and assign each cluster a dedicated file path:
     - `src/features/<feature>/internal/clusters/SidebarCluster.tsx`
     - `src/features/<feature>/internal/clusters/TopbarCluster.tsx`
     - `src/features/<feature>/internal/clusters/StatsCluster.tsx`
     - `src/features/<feature>/internal/clusters/TableCluster.tsx`

---

## Phase 2: Parallel Cluster Sub-Agents (`1 Cluster = 1 Crop = 1 File`)

Spawn one sub-agent per cluster **in parallel** (each with a fresh context window).

Give each sub-agent this strict brief:
- **Assigned Crop:** `/tmp/ui-clusters/crop-<cluster>.png` (plus `elements-ref.png` if container styles are shown there).
- **File Lock:**
  - **WRITE ALLOWED ONLY TO:** `src/features/<feature>/internal/clusters/<ClusterName>Cluster.tsx`
  - **READ-ONLY:** `tokens.css`, `components/ui/*`, `contracts/`, `<Feature>Page.tsx`.
- **Mandatory Step A — 100% Element Inventory (Anti-Skip Rule):**
  Before writing JSX, inspect `crop-<cluster>.png` up close and write a numbered checklist of **every single visual element** inside this cluster (every button, icon, badge, status dot, border, divider, input, shortcut hint, and column header). Nothing in the crop may be omitted.
- **Mandatory Step B — Implement Cluster:**
  Build `<ClusterName>Cluster.tsx` matching the crop's exact container borders, spacing, and hierarchy, obeying all `/antislop` rules (real actions, Empty/Loading/Error states, zero fluff subtitles, `min-w-0` flex truncation, `tabular-nums`).
- **Return:** The completed file path and the numbered Element Inventory checklist.

---

## Phase 3: Stitch & Live Browser Grid Verification (`chrome-devtools-mcp`)

Once all parallel cluster sub-agents finish:

1. **Stitch & Static Check:**
   - Import all cluster components into `<Feature>Page.tsx`.
   - Run `./.agents/scripts/verify.sh --affected` (and `./.agents/scripts/lint-ui.sh` if enabled) to verify TypeScript contracts and token compliance.

2. **Live Browser Inspection & Grid Diff (`tester` / `chrome-devtools-mcp`):**
   - Open the rendered page in headless Chrome at the reference aspect ratio (`1440x900`) and mobile (`390x844`).
   - **DOM Element Inventory Check:** Verify against each cluster's numbered Element Inventory that **100% of listed elements are rendered in the live DOM** (`width > 0 && height > 0`). If any badge, icon, filter, or divider was skipped, fail and fix immediately.
   - **Visual Grid Comparison (`actual-grid.png` vs `<reference>-grid.png`):**
     Capture a screenshot `actual.png`, run:
     ```bash
     ./.agents/scripts/ui-ref.py grid actual.png
     ```
     Compare `actual-grid.png` against `<reference>-grid.png` using the `0..100%` grid lines:
     - Do the cluster boundaries align with the reference percentage lines?
     - Do container borders, radii, surface contrast, and spacing match?
     - Are there zero horizontal overflows or bounding-box collisions?
   - Adjust any seam or proportion mismatch until the rendered screen matches the reference.
