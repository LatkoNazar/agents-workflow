---
name: antislop
description: "Comprehensive Anti-Slop filter and Delivery Gate across UI, layout, copywriting, accessibility, reference matching, and code comments (synthesizing antislop.ai.id R-01..R-40, Anthropic frontend-design, and Vercel web-design-guidelines in one file)."
---

# Anti-Slop Filter & Delivery Gate (`/antislop`)

Apply this filter whenever building, editing, or reviewing UI, copywriting, or code.
Its job is two-fold:
1. **Eliminate recognizable AI slop** (visual clichés, dead controls, fake claims, buzzword copy, broken flex/mobile geometry, and noisy AI code comments).
2. **Prevent sterile defaults** by enforcing reference matching (Golden Exemplar or visual reference) and explicit **Liveliness Dials**.

---

## 1. Anchor Direction & Set Liveliness Dials (Before Writing Code)

Never build UI in a vacuum ("sterile default"). Before generating UI, establish direction from one of three sources (in priority order):

1. **Existing Project Exemplar (Golden Screen):** Match the exact layout density, spacing rhythm, component primitives, and palette of an existing screen in the repo.
2. **Visual Reference (`reference.png` / Figma / URL):** Match the reference's grid proportions, hierarchy, and spacing.
3. **Explicit Design Read & Three Dials:** Declare a one-line Design Read and set the three dials (`1 = Calm`, `2 = Balanced`, `3 = Bold`) based strictly on the project's own domain and user brief (never copy third-party brands):
   > `Design Read: <page/feature kind> for <audience>, style <project-specific direction>, dials ENERGY <1-3> / RHYTHM <1-3> / MOTION <1-3>.`
   - **ENERGY:** `1` (Quiet, utilitarian, high data density) · `2` (Balanced contrast and clear visual hierarchy) · `3` (Bold, expressive typography and strong focal contrast)
   - **RHYTHM:** `1` (Uniform, predictable grid) · `2` (Consistent grid with intentional focal breaks) · `3` (Asymmetric, varied section compositions)
   - **MOTION:** `1` (Static layout, hover/focus states only) · `2` (Subtle, purposeful micro-transitions) · `3` (Choreographed layout and state transitions)

---

## 2. Tier 1: Hard Gate (Absolute — Zero Exceptions)

Breaking any Hard Gate rule is an automatic **FAIL**:

### A. Functional Completeness, Real Data & Three Mandatory UI States
- **Zero Placeholders, Mocks, or "Coming Soon" in UI:**
  - Never hardcode mock arrays (`const mockOrders = [...]`), `[REAL DATA]`, `[PLACEHOLDER]`, `"Coming soon"`, or `// TODO: connect to API` inside UI components.
  - **No Backend = No UI Element:** Every metric, list, filter, tab, and button rendered on screen must be wired end-to-end to the real backend vertical slice. If a capability is out of scope for the current ticket, omit the control entirely rather than rendering a decoy.
  - **Seed the Sandbox DB Instead of Faking UI:** If the cloned dev sandbox database lacks rows needed to render or verify the feature, insert/seed realistic records into the sandbox database (or test fixture)—never fake them in frontend state.
- **Zero Dead Controls:** Every `<button>`, `<a href>`, tab, modal, filter, dropdown, or form must perform a real action. Never ship `onClick={() => {}}`, `href="#"`, or navbar links to non-existent pages.
- **Mandatory 3 Data States:** Every view that loads or displays data must implement:
  1. **Loading state:** Skeleton or spinner preserving layout geometry; submit buttons disable and show progress during in-flight requests (`Saving…`).
  2. **Empty state:** Short factual statement + primary action button (`"No projects yet."` + `[New project]`). Never write poetic filler (`"Your dashboard is a blank canvas!"`).
  3. **Error state:** Pattern: `[What failed]. [Why/cause]. [How to fix].` (e.g., `"Couldn't save changes. Connection lost. Check your connection and try again."`). Never blame the user (`"Invalid input"`), apologize (`"Oops! Something went wrong"`), or show raw error codes.

### B. Layout, Responsive & Engineering Rules (Vercel + Mobile Gate)
- **Zero Horizontal Overflow:** `document.documentElement.scrollWidth <= window.innerWidth` on both desktop (`1440px`) and mobile (`390px`).
- **Flex & Text Truncation:** Flex children holding text must have `min-w-0` so `truncate` or `line-clamp-*` works instead of overflowing the container.
- **Numeric Alignment:** Always apply `tabular-nums` (`font-variant-numeric: tabular-nums`) on numeric columns, prices, counters, and timers.
- **Tap Targets & Semantics:**
  - Minimum `44x44px` hit target on mobile controls.
  - Actions use `<button type="button">`; navigation uses `<a href>` / `<Link>`. Never use `<div onClick>` or `<span onClick>`.
  - Enabled interactive elements show `cursor: pointer`; disabled show `cursor: not-allowed`.
  - Every `<img>` and `<video>` specifies `width` and `height` (or `aspect-ratio`) to prevent layout shift (CLS).
  - Never use `transition: all` / `transition-all`—specify exact properties (`transition-colors`, `transform`, `opacity`) and honor `prefers-reduced-motion`.
- **Keyboard & Focus Accessibility:**
  - Full `Tab`, `Enter`, `Space`, and `Escape` (closes modals/drawers) support.
  - Visible `:focus-visible` indicator on all controls; never use `outline-none` without a `focus-visible:ring-*` replacement.
  - Minimum WCAG AA contrast (`4.5:1` normal text, `3:1` large text; never grey text on grey background).

### C. UX Writing, Microcopy Clutter & Data Honesty Gate
- **Zero Fluff Subtitles & Microcopy Clutter:**
  - **No Redundant Subheaders:** When a page, modal, card, tab, or input title is self-explanatory (`Settings`, `Export data`, `Orders`, `Email`), do **not** add a `text-xs` / `text-sm text-muted` subtitle underneath that repeats the header in longer words (`"Manage your account preferences..."`, `"View and track all your orders in one place"`, `"Easily download a copy of your records"`). Let the heading stand alone.
  - **No Poetic or Abstract Microcopy:** Never place motivational, mystical, or abstract filler near buttons, tabs, or headers (`"Dive into the magic of..."`, `"Your command center for..."`, `"Unlock your potential"`, `"Everything in one place"`).
  - **Strict Helper-Text Gate:** Helper text or tooltips are allowed **only** when they state a hard technical constraint or non-obvious consequence (`"Max 50 MB, PDF or PNG"`, `"Token is shown only once"`). Never write tooltips that repeat the button label (`"Click here to delete"`).
  - **Proportional Confirmations & Dialogs:**
    - Routine actions use a 1–2 word toast (`"Saved"`, `"Copied"`, `"Profile updated"`), never a full paragraph.
    - Destructive confirmation dialogs name the exact target and consequence: Title `"Delete 3 files?"`, Body `"This can't be undone."`, Buttons `"Delete files"` / `"Keep files"` (never `"Are you sure?"` with `"OK"` / `"Cancel"`).
- **Zero Em-Dashes (`—`) & Banned Filler Words:**
  - Never output `—` in UI headings, labels, tooltips, or prose. Use commas, colons, periods, or parentheses.
  - **FORBIDDEN filler & buzzwords:** `AI-Powered`, `Next-Generation`, `Revolutionary`, `Seamless`, `Seamlessly`, `Cutting-Edge`, `Ultimate`, `Effortless`, `Supercharge`, `Delve`, `Elevate`, `Empower`, `Easily`, `Simply`, `Just`.
- **Specific Verb + Noun CTAs (Sentence Case):**
  - **FORBIDDEN generic CTAs:** `Get Started`, `Learn More`, `Try Now`, `Explore`, `Discover`, `Submit`, `Continue`, `OK`, `Click here`.
  - **REQUIRED:** Active verb + specific object in sentence case (`Create order`, `Save API key`, `Export CSV`). Keep action naming identical between the button (`Publish`) and its feedback toast (`Published`).
- **Zero Fabricated Metrics or Claims:**
  - **FORBIDDEN:** Invented stats (`10K+ Users`, `99.9% Uptime`), fake testimonials, random avatars/names, or unverified security claims (`SOC 2`). If no real verifiable metric exists, omit the section entirely.
- **Zero Decorative Emojis in UI:** Never use `🚀`, `✨`, `🔥`, `💡` as UI icons or bullets.

### D. Code Comment Hygiene (`antislop-code`)
- **FORBIDDEN Comment Patterns:**
  - Decorative ASCII banners/dividers (`// ====================`, `// ---- ROUTES ----`)
  - Step-by-step workflow narration (`// Step 1: Validate`, `// Step 2: Save`, `// Step 3: Return`)
  - Restating the obvious line or function signature (`// Initialize count` above `let count = 0`)
  - Empty category labels (`// Main logic`, `// Helper function`) and vague TODOs (`// TODO: improve later`)
  - Decorative emojis in comments (`// 🚀 Fast path`, `// ✅ Done`) and closing brace markers (`} // end if`)
- **ALLOWED Comments:** Keep only 1–2 short lines explaining **WHY** (non-obvious business constraints, protocol quirks, security invariants, or workarounds).

---

## 3. Tier 2: Purpose-Gate (Forbidden as Default; Allowed Only with Purpose & Dose Caps)

Reject these common AI visual clichés whenever they appear as unmotivated defaults:

- **Default AI Color Palettes & Gradients:**
  - No default blue-to-purple / indigo-to-pink gradients, neon-on-black `#0B0B0B`, or Claude's default warm cream `#F4F1EA` + terracotta `#D97757` unless explicitly mandated by the project's brand.
  - Limit active palette to **2–3 core colors + 1 deliberate accent** (neutrals excluded).
- **No Unrequested Brand Clones (R-30):**
  - Never default to cloning the look of Linear, Stripe, Vercel, Notion, or Apple unless the user explicitly asked for that reference. Build around the project's own identity and Golden Exemplars.
- **Card-in-Card & The SaaS-Card Kit:**
  - Never nest a bordered/shadowed card inside another bordered/shadowed card (`border rounded-xl` inside `border rounded-xl`). Use whitespace, table rows, or `divide-y` dividers instead.
  - Do not chop every section into identical 3-column rounded cards with identical icons and shadows.
  - Do not make every element pill-shaped (`rounded-full` on buttons, cards, inputs, and badges at once).
- **Typographic Clichés:**
  - Never italicize, bold, or gradient-color a single "magic" word inside a heading.
  - Never park an `ALL-CAPS` wide-tracked eyebrow pill badge above every `H1`/`H2`.
  - Never use `01 / 02 / 03` numbering unless the content is genuinely a step-by-step sequence.
  - Do not append decorative arrows (`→`, `↗`) to every button.
- **Effect Dose Caps:**
  - **Glassmorphism / Blur:** Max 1–2 elements per screen (never navbar + cards + sidebar + modal simultaneously).
  - **Glows & Large Shadows:** Max 1–2 focal elements for elevation hierarchy; never make the whole page float.
  - **Generic AI Icons:** No Sparkle, Magic Wand, Robot, Orb, or Diamond icons unless directly relevant to the domain.

---

## 4. Deterministic UI Token & Anti-Slop Linter (`lint-ui.sh` — Opt-In)

To enforce design tokens and anti-slop rules deterministically at **0 prompt token cost**:

1. **Check `.agents/workflow.json` (`architecture.uiLinter.enabled`):**
   - If `architecture.uiLinter.enabled` is explicitly `false`, **respect the user's choice**: do NOT run or suggest CSS/token linting.
   - If `.agents/scripts/lint-ui.sh` exists and is enabled, run `./.agents/scripts/lint-ui.sh` before completing any frontend task.
2. **If `.agents/scripts/lint-ui.sh` Does Not Exist Yet (and `uiLinter.enabled` is not `false`):**
   - **Propose creating it to the user and state the concrete benefits:**
     - **Saves context window tokens:** Validates semantic design tokens, UI kit primitives (`components/ui/*`), and anti-slop rules in 0.1s via script instead of loading a large `DESIGN.md` into the LLM prompt.
     - **Prevents hardcoded style drift:** Automatically catches hardcoded `#hex`/`rgb()` colors, inline `style={{}}`, arbitrary `[...]` values, dead `href="#"` controls, and hardcoded mock arrays in `features/*`.
   - **If the user accepts:** Detect the project's styling setup (Tailwind + CVA, CSS Modules, SCSS, etc.), generate `.agents/scripts/lint-ui.sh` tailored to that stack, and set `"uiLinter": { "enabled": true }` in `.agents/workflow.json`.
   - **If the user declines:** Set `"uiLinter": { "enabled": false }` in `.agents/workflow.json` so future runs never nag or run CSS linting.

---

## 5. Mandatory Delivery Gate (Check Before Completing Task or Review)

Before finishing any UI or code task, verify all items pass:

- [ ] **Hard Gate PASS:** Zero dead controls (`href="#"` / empty `onClick`), all 3 states (Empty/Loading/Error) implemented, zero em-dashes/buzzwords/generic CTAs, mobile & flex overflow clean (`min-w-0`, `tabular-nums`, no `transition-all`), semantics & `:focus-visible` verified, zero AI-slop code comments.
- [ ] **Purpose-Gate PASS:** No card-in-card nesting, no unmotivated gradients/glows, no eyebrow pills, no single-word headline highlights, no decorative arrow/sparkle spam.
- [ ] **Reference & Liveliness PASS:** Matches the project's Golden Exemplar or `reference.png` layout density and holds the declared `ENERGY / RHYTHM / MOTION` dials.
