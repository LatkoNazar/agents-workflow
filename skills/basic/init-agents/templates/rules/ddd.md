---
name: ddd
description: "Doubt-Driven Development: fresh-context adversarial review to find concurrency & edge bugs."
argument-hint: "[target claim, design or diff]"
---

# Doubt-Driven Development (`/ddd`)

A confident agent is not a correct one. Long coding sessions quietly turn unverified assumptions into "facts."
While **TDD (`/tdd`)** verifies behavior you thought to write a test for, **DDD (`/ddd`)** suspects your own assumptions and forces a fresh-context adversarial check—**biased to disprove, not approve**—on everything the compiler and happy-path tests miss.

---

## When to Trigger `/ddd`

Run the Doubt Cycle whenever a decision or change is **non-trivial**:
- Crosses a module, database transaction, queue, or external API boundary
- Relies on an invariant the compiler cannot prove (idempotency, concurrency/race conditions, retry safety, ordering, partial failure recovery, tenant/user isolation)
- Modifies authentication, billing, permissions, or destructive data migrations
- Before claiming *"this is safe"*, *"this handles edge cases"*, or *"this matches the spec"*

*(Skip for purely mechanical edits, renames, or trivial 1-line formatting changes.)*

---

## The 5-Step Doubt Cycle (`CLAIM -> EXTRACT -> DOUBT -> RECONCILE -> STOP`)

### Step 1: CLAIM — State What You Believe Is True
Write down the exact assumption or safety claim in 2–3 lines:
- *Example:* `"BillingModule.charge_for_render is idempotent and cannot double-charge a user if the webhook or job retries."`

### Step 2: EXTRACT — Strip Your Own Justification
Package **only**:
1. The raw code / diff (`ARTIFACT`)
2. The required invariant / spec (`CONTRACT`)
**Strip out** your own narrative explaining *why* you think it works, so you don't bias the verifier.

### Step 3: DOUBT — Adversarial Cross-Examination (Fresh Context)
Spawn a fresh-context sub-agent (or run an explicit adversarial pass with a hard mental reset) with this exact posture:
> **"You are an adversarial verifier biased to DISPROVE, not approve. Assume the code below has a bug that violates the contract. Find the exact input, race condition, partial failure, null/empty state, or auth bypass that breaks it."**

Check these 6 blind spots specifically:
1. **Concurrency & Idempotency:** What happens if two identical requests arrive 5ms apart, or the job retries halfway through?
2. **Partial Failure & Rollback:** If step 2 of 3 fails (e.g., external API succeeds, DB write fails, or vice versa), is state left corrupted?
3. **Tenant / Principal Isolation (IDOR):** Can `user_A` pass `user_B`'s resource ID and mutate or read it?
4. **Boundary & Empty Inputs:** What happens on `0`, negative numbers, `null`, empty arrays `[]`, huge payloads, or missing optional fields?
5. **Silent Error Swallowing:** Does a `try/catch` or fallback silently hide a real failure and return fake success?
6. **Test Tautology:** Did the TDD test actually test this failure mode, or did it only test the sunny-day path?

### Step 4: RECONCILE — Classify Every Finding Against the Code
For every flaw surfaced by Step 3:
- **Real flaw:** Turn it into a **failing TDD test (`RED`)** at the module facade, then fix the implementation (`GREEN`).
- **False alarm:** Prove it is impossible by citing the exact line, database constraint, or type guard in the code.

### Step 5: STOP
Exit the loop once the adversarial pass finds only trivial/non-existent issues (or after max 3 cycles).
