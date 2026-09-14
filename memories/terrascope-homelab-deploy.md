---
name: terrascope-homelab-deploy
description: TerraScope runs on the homelab at faisal@100.122.215.60; ~/terrascope is an rsync target, not a git checkout, and has traps
metadata:
  type: project
---

TerraScope's real data and running API live on the homelab, not the Mac:
`faisal@100.122.215.60` (Ubuntu 26.04, 32 cores, no GPU, passwordless sudo).
The COGs, the SAM 3 runs under `data/lod0/`, and the serving API are all there.
The Mac has only source and a dead partial COG.

**Why:** checking the Mac alone gives wrong answers about what exists. As of
2026-09-14 the local `data/processed/` held only a 660 MB `.partial.tif` from a
preprocess that died, while the homelab had the finished 692 MB
`desa-peleyan-ecw.tif`. Any question about imagery must be answered there.

**How to apply:**

- Deploy with rsync over ssh. `~/terrascope` is **not a git repo** — it is an
  rsync target, and it can be several commits behind the Mac.
- Never rsync with `--delete`: it would wipe `vendor/sam3` and `data/`, which
  exist only on the homelab. Use `--backup --backup-dir=...` instead.
- macOS ships `openrsync`, which silently truncates `--itemize-changes` dry-run
  listings. Use GNU rsync (`nix shell nixpkgs#rsync --command rsync ...`) before
  trusting a dry run.
- `~/terrascope` holds stale root-level duplicates of `scripts/*.py` from the
  old flat layout. The root `inspect.py` shadows the stdlib module and breaks
  every numpy import when the repo root is on `sys.path`. It was moved to
  `~/terrascope-backup-20260914-144510/`; the other seven duplicates
  (benchmark, dev, check_drivers, ingest, preprocess, validate_cog,
  build-gdal-image) are still there and still byte-identical to `scripts/`.
- Two servers compete for port 8000: a manual `uv run uvicorn` and a
  `terrascope.service` systemd unit stuck in an auto-restart loop. Do not
  restart either without asking; run a second instance on another port instead.
- `uv` is not on PATH over ssh. Use `~/terrascope/.venv/bin/python` directly.

See [[terrascope-lod0-review-api]].
