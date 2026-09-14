---
name: no-over-commenting
description: "Faisal wants sparse comments in code — only where the reason isn't obvious from the code"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b21f5bf7-df7a-4883-a039-0fbc11285cd2
  modified: 2026-07-31T08:26:15.044Z
---

Keep comments sparse. Don't narrate what the code already says, don't write multi-paragraph docstrings, and don't add a comment to every block. One short line where the *reason* is genuinely non-obvious (a workaround, a lifetime/ownership subtlety, a protocol quirk) is enough.

**Why:** Faisal pushed back with "remember don't over comment" while I was adding proxy routes to chromefleet with a comment on nearly every statement. Note that some existing code in these repos (e.g. chrome-live's `browser-trace/recording.py`) is heavily commented — that is not the standard to match for new code.

**How to apply:** Default to no comment. Prefer a one-line docstring over a multi-paragraph one. Before adding a comment, check whether a clearer name or the code itself already conveys it.

My bar for "the reason is non-obvious" is still too low. On 2026-09-14 in terrascope I wrote flake.nix and .envrc with five comments I judged to be why/trap notes; Faisal said "I hate comment, the code already self explanation remove it" and all five went. Config and infra files (flake.nix, .envrc, Makefile, compose) get **zero** comments — write them bare. He did decline a repo-wide purge when offered, so this is about what I add, not about stripping code that already exists.
