---
name: project-inboxcart-manual-testing
description: "How to manually test inboxcart sync/backfill locally, incl. Gmail after: timezone gotcha"
metadata: 
  node_type: memory
  type: project
  originSessionId: f9e03df1-8dae-4161-993b-321d37ee8cbd
---

Manual-testing workflow for inboxcart schedulers (used for PR #857, 2026-06-05):

- Local DB reset: `podman compose down -v` at repo root, then re-up + migrate; seed by copying prod `inboxcart_users` via `psql \copy` with an explicit column list (prod lacks newer columns), then `setval` the id sequence. Prod DB URL is the commented-out `INBOXCART_DATABASE_URL` in `apps/inboxcart/.env`.
- Force a sync/backfill claim instantly: `UPDATE inboxcart_users SET last_sync=NULL` (sync) or `backfill_complete=false, last_backfill=NULL` (backfill); intervals are 3600s/60s.
- Since PR #862 (2026-06-05, reworked same day to limit-based) sync uses a single `sync_cursor DATE` on inboxcart_users as a low watermark (NULL = backfill from 2023-01-01). One algorithm: walk *backward* from today in batches of `BACKFILL_MAX_RESULTS` (50), stepping `before:` to the batch's oldest internal_date +1d (min 1-day progress); batch < limit ends the walk; cursor checkpoints to *today* only on completion (crash = cursor stays put, redo is cheap via dedup; per-batch `last_sync` heartbeat gates re-claim). Force full re-backfill: `UPDATE inboxcart_users SET sync_cursor=NULL, last_sync=NULL WHERE id=...`. Sparse mailbox = ~3 queries/~11s; to stretch a walk for kill-testing, run with `INBOXCART_BACKFILL_MAX_RESULTS=5`. All queries log `after:X before:Y` (steady state is the degenerate `after:<today> before:<tomorrow>`).
- **Gmail `after:` gotcha**: Gmail evaluates `after:YYYY/MM/DD` at midnight Pacific Time, so forward sync's `after:date.today()` misses same-day mail arriving before ~14:00 UTC+7. Pre-existing gap as of PR #857; proposed fix `after:today-1d` (message-id dedup in `EmailIngestor.ingest` makes it safe).
- `{'backfilled': 0}` in backfill logs does NOT mean empty page — it's purchases_stored=0; a full page with zero extracted purchases logs the same.
- Test purchase emails must match `PURCHASE_EMAIL_SENDERS` in `app/core/constants.py` (whitelisted sender, or that address visible in a forwarded body).
- Known LLM failure mode under load: OpenRouter returns empty `choices` → "Email classification failed"/"Purchase extraction failed"; caught per-email, but backfill watermark advances past failed emails with no retry.
