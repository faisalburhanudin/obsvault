---
name: project_backfill_underfetch
description: "In-progress investigation + fix for Gmail backfill under-fetch; paused 2026-07-04, resume with oracle-vs-stored validation"
metadata: 
  node_type: memory
  type: project
  originSessionId: e4530b1b-d7f9-4639-9745-11dafe10534d
---

Investigating why older-year email counts in `inboxcart_emails` looked low. Paused 2026-07-04 mid-validation; **changes are uncommitted in the working tree** (not on a branch yet).

**Code changes made (uncommitted):**
- `app/services/gmail.py` — `_fetch_ids_from_query` now paginates via `nextPageToken` (was single-page, the root-cause bug); extracted `_list_page` helper holding the 429 retry.
- `app/services/sync.py` — `_walk_backfill`/`_sync_window` terminator fixed to stop only on an **empty** window (was `emails_synced < BACKFILL_MAX_RESULTS`, which a short page tripped early → `checkpoint_sync(today)` orphaned older history). Added a `dry_run` seam: skips classify/extract/save + all DB writes, returns `messages` as `(message_id, internal_date)` pairs.
- `scripts/backfill_coverage_check.py` — new live-Gmail harness (oracle full-pagination vs NEW dry_run walk vs OLD stored, per year).

**Key finding that changes the diagnosis:** Gmail's `resultSizeEstimate` (which the original "we only stored 12% of 2019" claim relied on, via `scratchpad/gmail_year_probe.py`) **massively overestimates — ~25× in a 3-user smoke test** (est ~199/user vs true ~8/user for 2019). So the "under-fetch" magnitude is unconfirmed; 2019 may just genuinely have fewer purchases/user. Ground truth = full pagination (oracle), NOT the estimate.

**RESOLVED 2026-07-05 — there is NO under-fetch bug.** Lighter re-run (`scripts/backfill_coverage_check.py`, Phase A) on 100 users: production **stored == oracle(full pagination) == 100% for every year**, incl. 2019 (2347==2347). True purchase emails/user by year: 2019≈23.5, 2020≈43, 2021-24≈70-74, 2025≈80.7, 2026≈36 (partial). So 2019 is **genuinely low** — fewer purchases/user in earlier years — exactly the original pre-probe conclusion. The alarming "12% / 8.4× gap" was **entirely a Gmail `resultSizeEstimate` artifact** (it overestimates ~8-10×; 2019 est ~199/user vs true 23.5/user). Fixed walk validated == oracle 100% (3 smoke + 5 Phase-B users).

**Status of the uncommitted changes:** they fix a *theoretical* fragility (single-page fetch + short-page early-break) that does NOT cause data loss in practice — Gmail returns full pages for these mailboxes, so the early-break never fires. Defensible hardening, but NOT a bug fix. **Awaiting user decision** on whether to keep/commit them or revert. Do not commit/push/deploy without asking (user flagged dangerous commands). See [[project_inboxcart_manual_testing]] for the resultSizeEstimate/PT-timezone gotchas.
