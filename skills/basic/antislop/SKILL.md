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
3. **Explicit Design Read & Three Dials:** Declare a one-line Design Read and set the three dials (`1 = Calm`, `2 = Balanced`, `3 = Bold`):
   > `Design Read: <page/feature kind> for <audience>, style <direction>, dials ENERGY <1-3> / RHYTHM <1-3> / MOTION <1-3>.`
   - **ENERGY:** `1` (Linear / GOV.UK) · `2` (Stripe / Vercel) · `3` (Editorial / bold brand)
   - **RHYTHM:** `1` (Uniform dense grid) · `2` (Consistent with intentional breaks) · `3` (Asymmetric mixed compositions)
   - **MOTION:** `1` (Hover/focus states only) · `2` (Purposeful transitions) · `3` (Choreographed motion)

---

## 2. Tier 1: Hard Gate (Absolute — Zero Exceptions)

Breaking any Hard Gate rule is an automatic **FAIL**:

### A. Functional Completeness & Three Mandatory UI States
- **Zero Dead Controls:** Every `<button>`, `<a href>`, tab, modal, filter, dropdown, or form must perform a real action wired into the vertical slice. Never ship `onClick={() => {}}`, `href="#"`, or navbar links to non-existent pages.
- **Mandatory 3 Data States:** Every view that loads or displays data must implement:
  1. **Loading state:** Skeleton or spinner preserving layout geometry; submit buttons disable and show progress during in-flight requests (`Saving…`).
  2. **Empty state:** Clear explanation and primary action when a list/query is empty (never a blank box).
  3. **Error state:** Concrete explanation of what failed and how to retry/fix (inline field errors on forms; never vague `"Oops! Something went wrong"`).

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

### C. Copywriting & Data Honesty Gate
- **Zero Em-Dashes (`—`) in UI Copy:** Never output `—` in UI headings, labels, tooltips, or prose. Use commas, colons, periods, or parentheses.
- **Specific Verb + Noun CTAs:**
  - **FORBIDDEN generic CTAs:** `Get Started`, `Learn More`, `Try Now`, `Explore`, `Discover`, `Submit`, `Continue`.
  - **REQUIRED:** Name the exact action (`Create Order`, `Save API Key`, `Export CSV`). Keep action naming identical between the button (`Publish`) and its feedback toast (`Published`).
- **Zero AI Marketing Buzzwords:**
  - **FORBIDDEN:** `AI-Powered`, `Next-Generation`, `Revolutionary`, `Seamless`, `Cutting-Edge`, `Ultimate`, `Effortless`, `Supercharge`.
- **Zero Fabricated Metrics or Claims:**
  - **FORBIDDEN:** Invented stats (`10K+ Users`, `99.9% Uptime`), fake testimonials, random avatars/names, or unverified security claims (`SOC 2`). Use real data or explicit `[REAL DATA]` placeholders.
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

## 4. Mandatory Delivery Gate (Check Before Completing Task or Review)

Before finishing any UI or code task, verify all items pass:

- [ ] **Hard Gate PASS:** Zero dead controls (`href="#"` / empty `onClick`), all 3 states (Empty/Loading/Error) implemented, zero em-dashes/buzzwords/generic CTAs, mobile & flex overflow clean (`min-w-0`, `tabular-nums`, no `transition-all`), semantics & `:focus-visible` verified, zero AI-slop code comments.
- [ ] **Purpose-Gate PASS:** No card-in-card nesting, no unmotivated gradients/glows, no eyebrow pills, no single-word headline highlights, no decorative arrow/sparkle spam.
- [ ] **Reference & Liveliness PASS:** Matches the project's Golden Exemplar or `reference.png` layout density and holds the declared `ENERGY / RHYTHM / MOTION` dials.
