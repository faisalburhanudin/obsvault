---
name: gis-saas-ecw-to-cog
description: Faisal is building a GIS SaaS whose core loop is upload ECW → convert to COG → view; MVP accepts ECW only
metadata:
  type: project
---

As of 2026-09-29, Faisal is building a GIS SaaS product around one loop: users
upload raster data, the service converts it, and a built-in viewer shows the
result. Upload accepts **ECW only** for now; processing produces a **COG**
(Cloud Optimized GeoTIFF); the viewer reads that COG.

**Why:** it fixes the MVP scope — the dashboard's dominant surface is the upload
+ conversion job state, not general GIS editing. Related but separate from
[[terrascope-homelab-deploy]], which also serves COGs.

**How to apply:** design and feature work should keep the ECW → COG → viewer
pipeline visible (job stages, CRS validation, overviews, tile endpoint). More
input formats (GeoTIFF, JP2) are future scope, not current. The dashboard design
lives in the pen.dev doc `85d33503-d84c-4864-9231-9ed9169875eb/pencil-new.pen`.
