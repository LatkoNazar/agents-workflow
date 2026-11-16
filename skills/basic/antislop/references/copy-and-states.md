# Anti-Slop Reference: Copywriting, Data Honesty & UI States

## 1. Copywriting & Microcopy Rules

- **Zero Em-Dashes (`—`) in UI Copy:**
  - Never output `—` in headings, descriptions, tooltips, or labels. Use a comma, colon, period, or parentheses instead.
- **Specific Verb + Noun CTAs:**
  - **FORBIDDEN generic CTAs:** `Get Started`, `Learn More`, `Try Now`, `Explore`, `Discover`, `Submit`, `Continue`.
  - **REQUIRED:** State exactly what happens when clicked (`Create Project`, `Save API Key`, `Export CSV`, `Delete Workspace`).
  - Keep action naming consistent across the flow: a button labeled `Publish` triggers a toast saying `Published`.
- **Zero Marketing Buzzwords:**
  - **FORBIDDEN:** `AI-Powered`, `Next-Generation`, `Revolutionary`, `Seamless`, `Cutting-Edge`, `Ultimate`, `Effortless`, `Supercharge`.
  - Describe concrete capabilities and user outcomes in plain language.
- **Zero Decorative Arrows & Emojis in UI:**
  - Do not append `→` or `↗` to every button/link.
  - Never use emojis (`🚀`, `✨`, `🔥`, `💡`) as UI icons or bullet points in application interfaces.

## 2. Honesty & Unverified Data

- **Never Fabricate Metrics or Social Proof:**
  - **FORBIDDEN:** Invented stats (`10K+ Users`, `99.9% Uptime`, `300% Faster`), fictional testimonials, random names/avatars, or fake security badges (`SOC 2 Certified`).
  - If real data is not provided, omit the section or use an explicit `[REAL DATA]` marker.

## 3. Mandatory Three UI States & Form UX

Every data-driven component or screen must handle all three states before a vertical slice is complete:

1. **Loading State:** Skeleton or spinner that preserves layout geometry; submit buttons disable and show progress during in-flight requests (`Saving…`).
2. **Empty State:** When a list/query returns zero items, render an intentional empty view with a clear explanation and primary action (not a blank box).
3. **Error State:** Explain what failed and how to recover (e.g., retry button or inline field error next to the input), without apologizing (`Oops! Something went wrong`).
