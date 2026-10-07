---
name: terrarupa-commit-to-main
description: In the terrarupa repo, commit straight to main; do not create feature branches
metadata:
  type: feedback
---
In terrarupa, commit directly on `main`. Do not make a feature branch first, even for a big revamp.

**Why:** The user asked "why not just merge it to main?" after I branched for the workflows spec (2026-10-07). The repo history is all direct commits to `main`, experiments included.
**How to apply:** Commit on `main` when asked to commit. Still never push unless asked, and never add co-author lines ([[feedback_no_coauthor]]).
