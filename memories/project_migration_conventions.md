---
name: project-migration-conventions
description: "How DB migrations work in this repo — shared dev DB, CI snapshot test, idempotency convention, renumber-on-rebase pitfall"
metadata: 
  node_type: memory
  type: project
  originSessionId: cff9a5bb-2c42-4c1b-8362-4782c3920591
---

Migrations live in `packages/database/src/migrations/` (kysely-ctl, `pnpm --filter @ario/database db:migrate:up`). Tracking table: `kysely_migration`.

- **Shared dev/prod DB ("grabbit")** is migrated automatically ~1–2 min after each merge to main. Many apps (grabbit, inboxcart, tap-amazon, tap-connect…) share this one database.
- **Convention: write idempotent migrations** (`ifNotExists` / `DO $$ IF NOT EXISTS` guards). Migrations 050–063 all follow it; unguarded ones break the CI snapshot test if re-run.
- **CI `test-migrations.yml`** restores a Snaplet subset snapshot of prod into a fresh Postgres, then runs migrations. As of 2026-06-04, the subset config gave every table `rowLimit: 50`, truncating `kysely_migration` (>50 rows) → kysely re-ran old migrations → "column already exists" at the first unguarded one (064). Fixed in PR #858 (`generate-snaplet-config.js` full-copies kysely_migration). Workflow only triggers on `migrations/**` paths, not `scripts/**`.
- **Renumber-on-rebase**: feature branches must renumber migrations when main gains new ones (e.g. backfill migration went 064→065 in PR #857). If a branch migration already ran on the shared DB under an old name, re-running under the new name errors unless guarded.
