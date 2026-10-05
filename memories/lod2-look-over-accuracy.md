---
name: lod2-look-over-accuracy
description: terrarupa LOD 2 values a realistic look over survey accuracy; plan is roofer base + AI judge + Astra look layer
metadata:
  type: project
---

For terrarupa's LOD 2 (2026-10-05), accuracy is not the priority; the look is. LOD 0 / footprints stay the GIS truth.

Agreed direction (idea stage, nothing built):
- roofer dense stays the geometry base, after the PDAL canopy cleanup (math is kept, not replaced).
- Math flags candidates; Jev (text-only, cheap typed decisions) labels them from measured facts; vision LLM for low confidence; a person in lidar-edit last. Labels become lidar-edit rules.
- GPT-6 Astra (writes Blender Python) adds the look on top of the roofer model, inside a harness loop that measures the result against LiDAR with loose tolerances.

**Why:** the user's hypothesis is "AI creativity, hardened by LiDAR data". Pure PDAL rules needed a new patch per failure type and cannot name objects (wire, mast, spire).

**How to apply:** do not push accuracy work on LOD 2 visuals; keep geometry anchored to footprint and height so the GIS overlay still lines up. Test set: the 29 cap footprints of the lidar-pdal-canopy chunk run. See [[terrascope-lod0-review-api]].
