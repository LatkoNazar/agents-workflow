# Anti-Slop Reference: Code Comment Hygiene (`antislop-code`)

Filter out generic AI-generated comment noise while preserving high-value engineering notes.

## 1. Comments to Remove Immediately

- **Decorative ASCII Banners & Dividers:**
  - ❌ `// ==========================================`
  - ❌ `// -------- AUTHENTICATION ROUTES --------`
- **Step-by-Step Workflow Narration:**
  - ❌ `// Step 1: Validate input`
  - ❌ `// Step 2: Query database`
  - ❌ `// Step 3: Return response`
- **Restating the Obvious Line or Signature:**
  - ❌ `// Initialize counter` above `let count = 0;`
  - ❌ JSDoc/docstrings that merely echo parameter names without adding constraints.
- **Empty Category Labels & Vague TODOs:**
  - ❌ `// Main logic`, `// Helper function`, `// Error handling`
  - ❌ `// TODO: improve this later` (keep TODOs only when they state the exact task and reason)
- **Decorative Emojis & End Markers:**
  - ❌ `// 🚀 Fast lookup`, `// ✅ Validated`, `} // end if`

## 2. Comments That Earn Their Place (Keep & Write Concisely)

A comment earns its place **only** when it explains **WHY** (a constraint, invariant, external API quirk, performance trade-off, or non-obvious workaround) that the code itself cannot express.

- Keep it to **1–2 short lines** in plain developer voice:
  - ✅ `// Stripe retries webhooks for up to 72h; deduplicate by event.id.`
  - ✅ `// Postgres CREATE DATABASE WITH TEMPLATE fails if source DB has active connections; fallback to pg_dump.`
