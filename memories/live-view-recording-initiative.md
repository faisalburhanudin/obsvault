---
name: live-view-recording-initiative
description: "browser-trace HTTP live-view + recording initiative — task sequence, key CDP decision, research doc location"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4573052b-61d6-4604-814c-459333681459
---

Initiative to give browser-trace an HTTP surface so a single CDP screencast source feeds
BOTH recording (pull) and live view (stream), shrinking/retiring chrome-live's VNC stack.

Full research: `docs/live-view-recording-research.md` in the browser-trace repo.

Task sequence (Bin, Slack Jul 10 2026): 1) always record 2) migrate browser-trace to HTTP
service (plumbing only) 3) recording endpoint (pull) 4) migrate live view to that endpoint
(drop/shrink VNC) 5) upload to tigris (flyfleet pulls, not browser-trace push). Plus 1.5:
chrome-live perf check on fly (slow disk).

**Key unresolved decision:** does live view need Tier-C interactions — CapSolver extension
popup, native `<select>` dropdowns, browser/OS dialogs? CDP screencast captures only the
page viewport and CANNOT render those. If NO → retire VNC, run headful on bare Xvfb (like
steel-browser OSS). If YES → keep VNC or go OS-level capture. CapSolver popup (SOLVE_CAPTCHA
path) is the likely blocker.

Reference: steel-dev/steel-browser OSS uses CDP screencast + Input over a WebSocket
(`api/src/plugins/browser-socket/casting.handler.ts`), headful on Xvfb, no VNC. Its
WebRTC/MP4 is the COMMERCIAL product, not the repo. Recording there is rrweb, not screencast.

browser-trace already receives Page.screencastFrame centrally in main.py:handle_event and
records per-session on Target.attachedToTarget — so "always record" is largely already true.
Related: [[aiohttp-sidecar-test]].
