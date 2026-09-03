---
name: tigris-report-debugging
description: How to pull historical test reports from Tigris to debug failed remote-browser-tests runs
metadata: 
  node_type: memory
  type: reference
  originSessionId: fac4689b-90e2-4ba2-aec2-4b6335a7accb
  modified: 2026-07-20T05:10:21.211Z
---

Test machines in `remote-browser-tests` are one-shot Fly machines destroyed after each run, so `fly logs` (live-tail only) and `fly machines list` give nothing after the fact. Debug historical failures via the uploaded Playwright reports in Tigris (S3).

**Get Tigris creds:** `remote-browser-tests` has no running machine, so `fly-secret remote-browser-tests` fails. Use the always-on manager app instead:
`fly-secret remote-browser-tests-manager` — has the same `AWS_BUCKET_NAME` / `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_ENDPOINT_URL_S3` (currently `https://t3.storage.dev`, bucket `test-reports`). Load into env with `eval "$(fly-secret ... | grep -E '^(AWS_...)=' | sed 's/^/export /')"` so values never print.

**Report layout:** `s3://<bucket>/<JOB_NAME>/<FLY_MACHINE_ID>.zip`, one per run (schedules run every ~2h). JOB_NAME is the schedule name, e.g. `tap-connect (daytona)`. Zip contains `report.json` (parse `.suites[].specs[].tests[].results[]` for status + `.stdout` console.log trail + `.errors`) plus `trace/`.

**Zip size = pass/fail proxy** (config has `trace: "retain-on-failure"`): ~200KB zip = passed (no trace), ~4-6MB zip = failed (trace retained). Lets you reconstruct a full pass/fail timeline from `aws s3 ls` sizes without downloading. Extract just the report: `unzip -q -o -p <zip> report.json`.

**RTK gotcha:** the RTK hook truncates `aws s3 ls` terminal output to ~30 lines (`... +N more items`), but full data still flows through pipes — pipe straight into `python3`/`awk` to process all rows, or use `rtk proxy aws ...` to a file. Also RTK sometimes mangles `tail`; generate key lists with python instead.

Related: [[sms-otp-outage-jul2026]]
