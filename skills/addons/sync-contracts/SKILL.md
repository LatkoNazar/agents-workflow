---
name: sync-contracts
description: "Set up or run the Single Source of Truth contract bridge between Backend and Frontend (OpenAPI / Protobuf / GraphQL -> generated TypeScript client & typed MSW mocks) and wire it into verify.sh."
disable-model-invocation: true
---

# Synchronize Multi-Language Contracts (`/sync-contracts`)

When Backend (Python/FastAPI, Go, Rust, C#, Node) and Frontend (TypeScript/React/Next.js) live in two languages, agents must **never** write frontend DTOs or API client types by hand.

## Process

1. **Single Source of Truth Schema Export:**
   - Configure the backend to export its schema deterministically without needing external network calls (e.g. `contracts/openapi.json` or `contracts/*.proto`).
2. **Automated Frontend Codegen & Typed Mocks:**
   - Generate TypeScript API clients/types (`openapi-typescript`, `orval`, `buf`, or `graphql-codegen`) directly from `contracts/`.
   - Wire typed MSW (`openapi-msw`) handlers for fast frontend feature tests so any backend schema change immediately breaks frontend `tsc` and MSW tests if out of sync.
3. **Wire into `.agents/scripts/verify.sh`:**
   Ensure Step 3 of `verify.sh` runs:
   `backend schema export -> frontend client codegen -> git diff check / frontend tsc`
   so no vertical slice can pass `verify.sh` with a broken Backend <-> Frontend contract.
