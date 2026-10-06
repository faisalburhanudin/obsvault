Before the deploy

- [x] inboxcart_clean_purchases_enabled is ON in prod. After this PR, new code only writes to inboxcart_purchases when this flag is on. If it is off, the table that clients read gets no new rows.
- [x] The backfill is done. Run uv run python scripts/backfill_inboxcart_purchases_clean.py as a dry run and check that the verify counts match.
- [x] Find every other service that reads or writes inboxcart_purchases or inboxcart_purchases_clean (the inboxcart app, BI tools, other repos). Readers will see one row per order after the swap. Any writer will break.
- [x] Check if fly.daytona.toml (corelens-backstage-daytona) uses the prod DB. If yes, stop it too.
- [x] CI is green, including check-schema-drift.
- [x] Tell the team: the dashboard totals in app/db/users.py will go down, because that code now reads the per-order table. This is expected.
- [x] Take a DB snapshot or backup.

Cut off traffic

- [x] Stop the prod app: dokku ps:stop app. This stops HTTP traffic and the scheduler/worker
- [x] Stop the dev Fly app: fly scale count 0 -a corelens-backstage-dev. The dev migration runs first.
- [x] Check that no connections still use the tables:
SELECT pid, application_name, state, query FROM pg_stat_activity
WHERE query ILIKE '%inboxcart_purchases%';

Deploy

- [x] Merge PR #158.
- [x] Watch "Run Database Migrations": dev passes, then prod passes.
- [x] Check prod:
SELECT to_regclass('inboxcart_purchases'), to_regclass('inboxcart_purchases_raw'), to_regclass('inboxcart_purchases_clean');
-- expect: table, table, NULL
- [x] Check that inboxcart_purchases has the per-order row count (the same as the old clean count).
- [x] Run the "Deploy Dokku" workflow for prod. Dev Fly deploys by itself on merge.
- [x] Start the apps again (dokku ps:start, and scale the Fly app back up).

After the deploy

- [x] /health is OK.
- [x] Run one inboxcart sync for a test user. Check that new rows appear in both inboxcart_purchases_raw and inboxcart_purchases.
- [x] Logfire shows no clean purchase upsert failed errors and no relation ... does not exist errors.
- [x] purchase_extracted_total counters still update.
- [ ] Tell client teams that the swap is done.

Rollback

- [ ] Stop the apps → run the down migration on prod (manual kysely migrate:down) → redeploy the previous commit → start the apps. Do not roll back the code without rolling back the DB. That gives the same mix-up as above, in reverse.