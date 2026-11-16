---
name: security-audit
description: "Security audit & trust boundary check: hunt for IDOR, auth bypass, race & injection bugs."
argument-hint: "[target endpoint, module or PR]"
disable-model-invocation: true
---

# Security Audit & Hardening (`/security-audit`)

Find vulnerabilities that violate a real trust boundary, prove them with source evidence (or a safe test in the cloned worktree sandbox), and apply the smallest effective fix.
A candidate without a concrete **affected principal**, **target resource**, and **security outcome** is noise—not a confirmed finding.

---

## 1. Map Trust Boundaries & Assets First (Threat Model)

Before scanning files randomly, map where untrusted data enters the vertical modules:
1. **Untrusted Entrypoints:** HTTP params/bodies/headers, file uploads, webhooks, message queues, third-party API responses, URL query strings, and **LLM outputs**.
2. **Protected Assets:** User credentials/sessions, tenant-scoped records (`user_id`, `org_id`), billing/balances, admin actions, internal network/filesystem.
3. **Quick STRIDE Lens per Boundary:**
   - **Spoofing / Auth Bypass:** Missing auth middleware, weak token/webhook signature verification.
   - **Tampering / Injection:** Raw SQL string interpolation, command execution (`exec`/`spawn`), mass assignment / unvalidated DTO fields, path traversal (`..`).
   - **Information Disclosure:** Returning internal stack traces, leaking other tenants' rows, logging secrets/tokens.
   - **Elevation of Privilege (IDOR / BOLA):** Fetching or mutating a record by `id` without scoping the query by the authenticated `user_id` / `org_id`.
   - **Race Conditions / Financial Double-Spend:** Check-then-act (`SELECT` balance then `UPDATE`) without `SELECT ... FOR UPDATE` or atomic DB constraints.

---

## 2. Three-Tier Hardening Rules

### Always Enforce (Zero Exceptions)
- **Validate all external input** at the HTTP/router boundary using strict schema validation (Pydantic, Zod, Go validator) before passing to the Deep Module facade.
- **Scope every data query by principal (`user_id` / `tenant_id`):** Never query `WHERE id = :id` alone on user-owned resources.
- **Parameterize 100% of queries:** Zero string concatenation in SQL, NoSQL, or shell commands.
- **Secrets Hygiene:** Zero API keys, tokens, or credentials in code, git history, or client-exposed env vars (`NEXT_PUBLIC_*` / `VITE_*`).
- **Safe Session & Cookie Defaults:** `httpOnly`, `Secure`, `SameSite=Lax/Strict`.

### Never Do during an Audit
- Never probe production endpoints, external third-party infrastructure, or live user data. Run all reproduction tests strictly inside the isolated worktree Docker sandbox (`./.agents/scripts/worktree-up.sh`).

---

## 3. Audit Report Format

For every confirmed vulnerability, report:
1. **Severity & Location:** `[CRITICAL | HIGH | MEDIUM | LOW]` — `path/to/file:line`
2. **Trust Boundary Violated:** `Principal` -> `Entrypoint` -> `Resource` -> `Impact`
3. **Exploit / Reproduction Scenario:** Concrete input or sequence of calls that triggers the flaw.
4. **Minimal Fix + Seam Test:** Exact code fix + a regression test at the module facade proving the attack is blocked.
