---
name: never-read-dotenv-use-censored-script
description: Faisal forbids reading .env directly; inspect it only via a script that prints key names/status and censors values.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7f28f2e4-9af8-40b0-8311-84acc38b2fd6
  modified: 2026-07-29T06:09:34.107Z
---

Do not read `.env` files directly (no Read, `cat`, `grep`, or reading them back
"just to verify"). Inspect them only through a script that prints key names,
set/missing status, and character counts — never the values.

**Why:** these files hold live production secrets, and Faisal does not want them
entering the conversation transcript at all. Stated explicitly: "don't read it
again, but you can parse it using script but sensor the value."

**How to apply:** write or reuse a checker (e.g. `check-env.sh` in the
inbox-zero-deployment repo) and run that instead. Let deploy scripts consume the
secrets themselves so nothing else has to. If a task truly cannot proceed
without a value, stop and ask rather than reading the file. Applies to any
secret-bearing file, not just `.env`.
