---
name: no-ui-automation-on-faisal-laptop
description: "Never drive the Mac GUI with AppleScript/osascript or screencapture — Faisal is using the laptop"
metadata:
  type: feedback
---

Never automate the macOS GUI: no `osascript`/AppleScript keystrokes, no clicking menu items, no activating or focusing windows, no `screencapture`. Applies to every project, not just database-ui.

**Why:** Faisal is working on the same laptop while sessions run. Stealing focus or sending keystrokes interrupts what they are doing.

**How to apply:** Build and test headlessly (`xcodebuild`, unit tests). When something has to be seen on screen, tell the user what to open and ask them for the screenshot. Related: [[confirm-before-dangerous-actions]].
