---
name: daytona-lifetime-baseline
description: Measure Daytona cost from the billing dashboard, not the audit log; 2026-08-25 baseline
metadata:
  type: project
---

Measure Daytona sandbox cost and lifetime from the **billing dashboard** (per-sandbox table: id, price, CPU seconds, RAM GB-seconds, disk GB-seconds). Full baseline and analysis live in `research/daytona-cost-baseline.md`.

Baseline, 24h to 2026-08-25 04:00 UTC: 200 sandboxes, **$5.64**, 42.4 sandbox-hours. 21 sandboxes ran past the 15-min auto-stop and are **85% of the bill**; the single worst ran 854 min and is 34% alone.

Conversions that check out against the data (2 vCPU / 2 GiB / 10 GiB snapshot): `running_min = cpu_s/2/60`, `existed_min = disk_GB_s/10/60`; the difference is exactly `TTL_MINUTES = 60`. Rate ≈ $0.0668 per (vCPU+GB-RAM) hour.

**Why:** Two other sources give wrong answers. The org audit log only pairs create→delete inside the window, so it drops the long-lived sandboxes that carry the cost — it reported max 14.3 min when the truth was 854 min. `daytona sandbox list` held only 2 rows for the whole account. Neither is usable for cost.

**How to apply:** For any Daytona cost question, read the billing dashboard. Use the audit API only for event sequencing, and see [[daytona-cdp-ping-experiment]] for the open ping/auto-stop hypothesis.
