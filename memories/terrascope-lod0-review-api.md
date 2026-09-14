---
name: terrascope-lod0-review-api
description: The LOD 0 review API groups flagged footprints into cases; metrics alone cannot judge them, the imagery crop is required
metadata:
  type: project
---

The SAM 3 building footprints carry two defects the viewer flags: fragments cut
by a tile border and polygons split out of a fused proposal. `/api/review/...`
turns those into ~792 repairable *cases* over 4,259 polygons and takes verdicts
(merge / replace / keep / drop) back. Verdicts append to
`data/review/{layer}.sqlite`; the source GeoJSON is never edited.

**Why:** a metrics-only triage looks tempting and is wrong. On 2026-09-14 a
sweep using area, compactness and `merged_part_count` merged `cut:3944` — two
fragments that touch, 378 m², compactness 0.59. The crop showed the 38 m²
member sits on a *neighbouring* white roof, so the merge fused two buildings.
Shape numbers cannot tell a roof from the roof next door.

**How to apply:** judge cases from `/cases/{id}/crop.png`, not from metrics.
Use the metrics only to rank and to rule merges *out* (`merged_part_count > 1`
means the members do not touch). Real examples seen in the imagery: a 1,778 m²
"building" that was cleared ground with foundation lines (drop); an outer
polygon covering a walled plot with the two real roofs nested inside it
(replace); two complete buildings across a yard both flagged as cut (keep).

Only 5 of 792 cases were resolved; the rest are open. The exported layer at
`data/review/desa-peleyan-footprints-reviewed.geojson` has **not** been re-cut
into tiles, so the live map still shows the unreviewed draft.

See [[terrascope-homelab-deploy]].
