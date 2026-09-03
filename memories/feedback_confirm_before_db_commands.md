---
name: feedback-confirm-before-db-commands
description: Production DB commands require user confirmation; local DB is fine to run freely
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8c85417c-f272-472a-b945-79db6385bd20
---

The user instructed (2026-06-05, refined later the same day): local DB (localhost) commands may be run without asking; any command against the production DB (read or write) requires showing the exact command and getting explicit confirmation first.

**Why:** Prod is shared and live (the grabbit Postgres instance, reachable via the URL in the app's .env); local is disposable and seeded from prod, so mistakes there are cheap.

**How to apply:** Check the connection string before running `psql`/SQL — localhost → just run it; anything else (prod host / INBOXCART_DATABASE_URL from .env) → propose the exact command and wait for go-ahead. Verification steps that only touch local may also run without asking. Related: [[project-inboxcart-manual-testing]], [[project-migration-conventions]].
