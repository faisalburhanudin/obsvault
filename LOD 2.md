LOD 0 checklist

0. Prerequisites

- [ ] Install PDAL on 100.122.215.60 (not present). Needed for COPC writing and polygon-filtered reads.
- [ ] Add steps/lidar/ and steps/lod0/ with their own .venv (repo convention: one venv per step).
- [ ] Decide site name for the lidar data — suggest data/mini-project/ becomes a proper site dir like peleyan/.

1. Get footprints for mini-project (blocker)

LOD 0 has no input until this is done.
- [ ] Step 1: ECW → COG on Orthophoto_Mini_Projects_AA9_UTM49S.ecw (the .prj is there, step reads it)
- [ ] Steps 2–8: sam3 → builtup → ramp → split → merge → regularize → topology
- [ ] Confirm buildings-clean.geojson and features.ndjson.grid.json exist

2. Prepare the point cloud (steps/lidar/)

- [ ] Check vertical agreement: median Z difference between the three passes on class-2 points, 1 m grid. Do this before merging. If a pass is offset > ~5 cm, drop it.
- [ ] Filter gps_time == 0 points (present in AA450 and AA9)
- [ ] Filter noise: drop points above a Z ceiling (ground ~119 m, maxima reach 231 m — birds)
- [ ] Decide the merge: start with AA6D alone (615 pts/m², best multi-return). Only merge the other two if a measured gap justifies it.
- [ ] Thin to ~50 pts/m² (LOD 0 cannot use 920)
- [ ] Write COPC: site/lidar/cloud.copc.laz (expect < 1 GB from ~55 M points)
- [ ] Record what was dropped and why — the step should print counts like the others do

3. DTM (optional but useful)

- [ ] Class 2 → 0.5 m raster, TIN or IDW fill, as site/lidar/dtm.tif
- [ ] Use it only as fallback for footprints whose outside ring is empty

4. LOD 0 attributes (steps/lod0/)

Per footprint in buildings-clean.geojson:
- [ ] h_ground — p20 of class-2 Z in the ring: buffer(+2 m) minus buffer(+0.5 m). Never inside the footprint.
- [ ] Fallback to DTM when the ring holds too few ground points; flag it with ground_source
- [ ] Roof points — class 6 inside footprint eroded by 0.5 m
- [ ] h_roof_min, h_roof_p50, h_roof_p70, h_roof_max
- [ ] height = h_roof_p70 − h_ground
- [ ] ground_slope across the ring — flags hillside buildings
- [ ] n_roof_pts, roof_coverage (share of eroded footprint with points)
- [ ] Output buildings-lod0.geojson, geometry unchanged, WGS84, same as every other step

5. Validation (the free win)

- [ ] Report roof_coverage distribution split by source (sam3, sam3-new, sam3-split)
- [ ] Confirm the expectation: sam3-new polygons under 25 m² show near-zero roof points → those are tarps, ponds, bright ground
- [ ] Set a rejection threshold from that distribution, do not guess it
- [ ] Sanity check heights: single-storey village houses should land ~3–5 m. If the median is far off, h_ground is wrong.
- [ ] Spot-check 5 buildings against the orthophoto by eye

6. Write-up

- [ ] steps/lidar/README.md and steps/lod0/README.md in the pipeline's house style
- [ ] Add both rows to the root README.md layout table
- [ ] Add sections 9 and 10 to pipeline/README.md with reference numbers from the real run
- [ ] Note that LOD 0 is optional — peleyan has no lidar

Open questions to settle later

- [ ] Should footprints come from the class-6 mask instead of SAM? (better wall p