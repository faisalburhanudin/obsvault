---
name: sms-otp-outage-jul2026
description: "Two separate tap-connect OTP problems — Amazon OTP never retrievable (config bug), plus a real SMS-gateway outage from ~2026-07-18"
metadata: 
  node_type: memory
  type: project
  originSessionId: fac4689b-90e2-4ba2-aec2-4b6335a7accb
  modified: 2026-07-20T05:35:00.845Z
---

TWO DISTINCT problems, easily conflated (the error signature tells them apart):

**Problem A — Amazon OTP never retrievable (test/config bug, NOT a phone outage).**
Across all 213 `tap-connect (daytona)` (=Amazon brand) runs Jul 3–20, Amazon obtained **0 OTPs ever**. Amazon only started being *challenged* for OTP on **2026-07-14 ~15:33** (before that it signed in without OTP → green). Every challenge fails with `TimeoutError: aborted due to timeout` (~155s = relay long-polled the full 120s, no matching SMS arrived). The `amazon` brand in `tests/tap-connect.spec.ts` has no short code and no `brandTotpSecret`, so `getOtpFromSmsRelay` (`lib/otp-sms.ts`) falls back to searching SMS bodies for the literal sender `"Amazon"` — nothing matches. Amazon's OTP is almost certainly **email-based** (or a short code whose body can't be matched), so the SMS relay is the wrong mechanism. Proven Amazon-specific because **Walmart** (`tap-connect-walmart (daytona)`, short code `57513`) was PASSING with real OTPs the same days (Jul 14–18; e.g. Jul 18 10:40 got code 175383).

**Problem B — the SMS→test OTP pipeline broke 2026-07-18 between 10:40 and 12:35 UTC.**
PROVEN (from reports): the two phone-dependent suites (poll every 2h) both flip pass→fail at the same tick — Walmart last real OTP Jul 18 10:40 UTC (175383) → first `Failed to get OTP`/null Jul 18 12:40 UTC; Safeway last real OTP Jul 18 10:35 UTC (963597) → first null Jul 18 12:35 UTC. Codes unique per run = live SMS (not mocked); simultaneous gateway-unreachable errors = shared-gateway outage. From Jul 19 relay crash-loops `SMS gateway is not reachable, exiting`.
NOT PROVEN: that the physical phone *died* at that time. This is inferred from test logs only. The gateway is a **Pixel 7a**, Tailscale IP `100.80.236.62` (the `:8080` target `sms-relay` dials, org `yuxi-yao`), but Tailscale `lastseen=2026-07-01T10:01:21Z` CONTRADICTS the Jul 18 story and is unreconciled (real OTPs flowed through Jul 18 despite the Jul-1 lastseen). Relay had NO deploy on Jul 18 (ran the Jun 10 v8 image; machine `4d89770da09948` created Jul 18 11:54 UTC was just a Fly restart) so a reconfig didn't cause it either. To time the *physical* phone death, check the phone/SMS-gateway directly — test logs only show when codes stopped arriving. Do NOT use Amazon's timeout→null flip (21:07) to time this — Amazon never matches an SMS regardless of phone health.
CAUTION: the Pixel 7a's Tailscale `lastseen=2026-07-01T10:01:21Z` is a RED HERRING (it fooled an initial "phone died Jul 1" read via the 450h figure) — real unique OTPs flowed through Jul 18, so the phone reaches the relay over a subnet-router/LAN path that doesn't refresh its Tailscale coordination timestamp. Ground truth for the death time is the OTP traffic, not the Tailscale lastseen.

**Fixes:** (A) Amazon needs a real OTP source — investigate what daytona Amazon actually sends; likely needs email-OTP handling or a `brandTotpSecret` (template already runs `getTotpCode` when set, `templates/tap-amazon-like.ts:206`). (B) Bring the SMS gateway/phone back for Walmart/Safeway (`46395`) and other SMS brands.

Debug workflow: [[tigris-report-debugging]]
