---
name: desktop-only-uis
description: Build internal/experiment UIs for desktop only; skip responsive and mobile work
metadata:
  type: feedback
---

Target desktop. Do not spend effort on responsive layouts, breakpoints, or
mobile versions for internal tools and experiments.

**Why:** These UIs are used on a desktop browser over Tailscale. Responsive
work is cost with no user.

**How to apply:** Use a fixed desktop grid (toolbar rail, viewport, inspector)
and assume a wide window. Do not add media queries unless asked. Fits the
[[working_style_deploy_first]] habit of shipping the rough thing first.
