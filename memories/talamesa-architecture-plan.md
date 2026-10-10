---
name: talamesa-architecture-plan
description: Planned talamesa monorepo split (tools / orchestration / studio), canonical R2 layout, and Studio viewer reading local or R2
metadata:
  type: project
---

Plan agreed 2026-10-11, not built yet. Only `talamesa/orchestration` (Dagster) exists.

- One monorepo `talamesa/` with `tools/` (CLI + worker, one GDAL/PDAL image), `orchestration/` (Dagster), `studio/` (upload UI, viewer, starts runs).
- Client files of any type go to `projects/<p>/upload/`. Converters in `tools` write the rigid canonical files: `cog/ortho.tif`, `raw/lidar/*.copc.laz`. The contract is in orchestration's README.
- Tools never run on upload; they are expensive. Studio starts Dagster runs (launchPartitionBackfill).
- Fast on-demand jobs (converters) do not go through Dagster or the pipeline jobs queue. Use an API process, or a separate convert queue for long jobs like ECW to COG.
- One viewer only, in Studio. It reads from a switchable base URL: R2 by default, or local `./data/projects/...` served by Caddy (needs HTTP Range + CORS; `python -m http.server` has no Range).
- ECW reading needs GDAL built with the Hexagon SDK. Check the server license terms.

**Why:** small team; the user found multi-repo plus a separate viewer too complex.
**How to apply:** keep new work inside this plan; local tool output uses the same layout as R2.
