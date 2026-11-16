---
name: antislop
description: "Comprehensive Anti-Slop filter and Delivery Gate across UI, layout, copywriting, accessibility, reference matching, and code comments (synthesizing antislop.ai.id R-01..R-40, Anthropic frontend-design, and Vercel web-design-guidelines)."
---

# Anti-Slop Filter & Delivery Gate (`/antislop`)

Use this skill whenever building, editing, or reviewing UI, copywriting, or code comments.
Its job is two-fold:
1. **Kill recognizable AI slop** (visual clichés, dead controls, fake claims, buzzword copy, and noisy AI code comments).
2. **Prevent sterile defaults** by enforcing reference matching (Golden Exemplar or visual reference) and explicit **Liveliness Dials**.

To keep context lean (<100k Smart Zone), this skill is modular—load the specific reference file you need:
- [references/ui-and-layout.md](references/ui-and-layout.md) — Visual, layout, mobile, accessibility, and Vercel/Anthropic engineering rules.
- [references/copy-and-states.md](references/copy-and-states.md) — Copywriting, CTAs, data honesty, and mandatory Empty/Loading/Error states.
- [references/code-comments.md](references/code-comments.md) — Code comment hygiene (`antislop-code`).

---

## Step 1: Anchor Direction & Set Liveliness Dials (Before Writing Code)

Never build UI in a vacuum ("sterile default"). Before generating UI, establish direction from one of three sources (in priority order):

1. **Existing Project Exemplar (Golden Screen):** Match the exact layout density, spacing rhythm, component primitives, and palette of an existing screen in the repo.
2. **Visual Reference (`reference.png` / Figma / URL):** Match the reference's grid proportions, hierarchy, and spacing.
3. **Explicit Design Read & Three Dials:** Declare a one-line Design Read and set the three dials (`1 = Calm`, `2 = Balanced`, `3 = Bold`):
   > `Design Read: <page/feature kind> for <audience>, style <direction>, dials ENERGY <1-3> / RHYTHM <1-3> / MOTION <1-3>.`
   - **ENERGY:** `1` (Linear / GOV.UK) · `2` (Stripe / Vercel) · `3` (Editorial / bold brand)
   - **RHYTHM:** `1` (Uniform dense grid) · `2` (Consistent with intentional breaks) · `3` (Asymmetric mixed compositions)
   - **MOTION:** `1` (Hover/focus states only) · `2` (Purposeful transitions) · `3` (Choreographed motion)

---

## Step 2: Three-Tier Filter Rules

### Tier 1: Hard Gate (Absolute — Zero Exceptions)
Breaking any Hard Gate rule is an automatic **FAIL**:

1. **Functional Completeness (No Dead Controls):** Every `<button>`, `<a href>`, tab, modal, filter, or form must perform a real action wired into the vertical slice. No `onClick={() => {}}`, `href="#"`, or ghost navbar links.
2. **Mandatory 3 Data States:** Every view that loads or displays data must implement **Empty state** (with a clear action), **Loading state**, and **Error state** (with a fix/retry action).
3. **Mobile & Flex Resilience:** Zero horizontal overflow (`scrollWidth <= innerWidth`), `min-w-0` + `truncate`/`line-clamp` on flex children, minimum `44px` tap targets on mobile, and `tabular-nums` on numeric columns/tables.
4. **Honesty & Zero Fabricated Content:** Never invent fake statistics (`10K+ users`, `99.9% uptime`), fake testimonials, fake avatars, or unverified compliance claims (`SOC 2`). Use real data or explicit `[REAL DATA]` placeholders.
5. **Copy Hygiene (No Em-Dashes or Buzzwords):**
   - Never use the em dash (`—`) in UI copy; use commas, colons, or periods.
   - Never use generic CTAs (`Get Started`, `Learn More`, `Submit`, `Continue`); use specific verb+noun actions (`Create Order`, `Save API Key`).
   - Never use AI buzzwords (`AI-Powered`, `Seamless`, `Revolutionary`, `Next-Gen`, `Cutting-Edge`).
6. **Accessibility & Semantics:** `<button>` for actions, `<a href>`/`<Link>` for navigation (never `<div onClick>`), WCAG AA contrast (4.5:1 normal, 3:1 large), visible `:focus-visible`, `cursor: pointer` on interactive controls, and `Escape` closes modals/drawers.
7. **Code Comment Hygiene:** No decorative ASCII banners (`// ======`), no `// Step 1:` workflow narration, no comments restating the code, and no decorative emojis (`// 🚀`). Keep only 1–2 line comments explaining *why* (constraints, edge cases, non-obvious protocol rules).

### Tier 2: Purpose-Gate (Forbidden as Default; Allowed Only with Written Purpose & Dose Caps)
Reject these common AI tells whenever they appear without an explicit brand/hierarchy reason:

- **Default Blue-Purple / Neon Gradients & Glows:** Max 1–2 focal glow/blur elements on a page; never blur navbar + cards + modals + sidebar simultaneously.
- **The SaaS-Card Kit & Card-in-Card Slop:** Do not chop every piece of content into identical rounded cards with the same shadow, or nest bordered cards inside bordered cards (`border rounded-xl` inside `border rounded-xl`). Use whitespace or `divide-y` rules instead.
- **Eyebrow Pills & Decorative Arrows:** No tracked-out `ALL CAPS` pill badge parked above every `H1`, no decorative `→` appended to every button, and no `01 / 02 / 03` numbering on non-sequential items.
- **Single-Word Headline Highlight:** Do not italicize, bold, or gradient-color a single "magic" word inside a headline.
- **Generic AI Icons:** No default Sparkle, Magic Wand, Robot, Rocket, or Lightning icons unless directly dictated by the domain.

### Tier 3: Liveliness & Craftsmanship Locks
- **One Focal Point Per Screen:** Every screen must have one clear primary element; everything else defers to it in size, contrast, and weight.
- **Palette Discipline:** Max 2–3 core colors + 1 deliberate accent color (excluding neutrals).
- **Logo Swap Test:** If swapping the logo and title makes the UI indistinguishable from a generic AI template, rework the hierarchy and layout density.

---

## Step 3: Mandatory Delivery Gate (Before Shipping or Approving Review)

Before marking any UI or code task complete, verify and report:

- [ ] **Hard Gate PASS:** Zero dead controls, all 3 states (Empty/Loading/Error) implemented, zero em-dashes/buzzwords, mobile & flex overflow clean, semantics & `:focus-visible` verified, zero AI-slop code comments.
- [ ] **Purpose-Gate PASS:** No unmotivated gradients, card-in-card nesting, eyebrow pills, or decorative sparkle/arrow spam.
- [ ] **Reference & Liveliness PASS:** Matches the project's Golden Exemplar or `reference.png` proportions, and holds the declared `ENERGY / RHYTHM / MOTION` dials.
