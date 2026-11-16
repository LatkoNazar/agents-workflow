# Anti-Slop Reference: UI, Layout, Mobile & Accessibility

Combined rules from `antislop.ai.id` (R-01..R-40), Anthropic `frontend-design`, and Vercel `web-design-guidelines`.

## 1. Visual Clichés & Default Tells to Reject

- **Default AI Color Palettes:**
  - Blue-to-purple / indigo-to-pink gradients, neon-on-black `#0B0B0B`, or Claude's default warm cream `#F4F1EA` + terracotta `#D97757` unless explicitly part of the project's brand tokens.
  - Limit the active palette to **2–3 core colors + 1 deliberate accent** (neutrals excluded).
- **Card-in-Card & SaaS Card Grids:**
  - Never place a bordered/shadowed card inside another bordered/shadowed card. Use section dividers (`divide-y`), table rows, or spacing instead.
  - Never make all feature cards identical in height, padding, icon circle, and shadow without hierarchy.
  - Do not make every element pill-shaped (`rounded-full` on buttons, inputs, cards, and badges simultaneously).
- **Typographic Tells:**
  - Do not highlight a single word in a heading with a gradient, italic, or accent color.
  - Do not park an `ALL-CAPS` tracked-out eyebrow pill badge above every heading.
  - Do not use numbered markers (`01 / 02 / 03`) unless the content is genuinely a sequential step-by-step flow.
  - Use `font-variant-numeric: tabular-nums` (`tabular-nums` in Tailwind) on all numeric columns, prices, counters, and timestamps.
  - Use `text-wrap: balance` on headings and keep body line length under ~75ch.
- **Dose Caps on Effects:**
  - **Glassmorphism / Blur:** Max 1–2 elements per view. Never blur navbar, cards, sidebar, and modals at once.
  - **Shadows & Glows:** Use elevation only to signal hierarchy (e.g., floating popover/modal), never on every card.
  - **Motion:** Never use `transition: all` (list explicit properties: `transition-colors`, `transform`, `opacity`). Honor `prefers-reduced-motion`. Avoid putting `fade-up` entrance animations on every section.

## 2. Layout, Responsive & DOM Geometry

- **Zero Horizontal Overflow:** `document.documentElement.scrollWidth <= window.innerWidth` across both desktop (`1440px`) and mobile (`390px`).
- **Flex & Grid Truncation:** Flex children holding text must include `min-w-0` so `truncate` or `line-clamp-*` works instead of blowing out the container width.
- **Tap Targets & Interactive Affordances:**
  - Minimum `44x44px` hit target on mobile controls.
  - Every interactive element (`<button>`, `<a href>`, `<select>`, `<summary>`) must show `cursor: pointer`; disabled controls show `cursor: not-allowed`.
  - Never use `<div onClick>` or `<span onClick>`—use `<button type="button">` for actions and `<a href>` / `<Link>` for navigation.
- **URL State Sync:** Filters, active tabs, search queries, and pagination should sync with URL query params where applicable so refresh/share preserves state.
- **Media Dimensions:** Every `<img>` and `<video>` must specify `width` and `height` (or `aspect-ratio`) to prevent layout shift (CLS).
