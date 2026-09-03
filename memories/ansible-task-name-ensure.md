---
name: ansible-task-name-ensure
description: "Name state-asserting Ansible tasks as noun phrases naming the end state, not \"Ensure X\" or imperatives"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a185f6fb-3a7d-4cba-a0eb-7725a1b2add5
  modified: 2026-08-24T04:18:37.300Z
---

Name an Ansible task that asserts a desired end state as a noun phrase naming
that state — "Remotebrowser cloned at /opt/remotebrowser", "Git installed",
"Virtualenv matching lockfile" — not "Ensure remotebrowser is cloned…" and not
the imperative "Clone remotebrowser". Tasks that genuinely just read or perform
a one-shot action keep a verb ("Check installed uv version").

**Why:** The name is consumed in play output on every run. "Ensure" on every
line is a constant prefix carrying no information, and it drags copular padding
("is installed", "is cloned at") in front of the words that actually differ
between tasks. The declarative framing was the point; the prefix was not.

**How to apply:** Two ansible-lint rules in the production profile constrain the
phrasing, so write to them rather than configuring them away:
- `name[casing]` — first letter uppercase, so lowercase tool names get
  capitalized in task names ("Uv installed at version …", "Git installed") even
  though the tools brand themselves lowercase.
- `name[template]` — a Jinja expression may only appear at the *end* of a name,
  so put the templated value last ("Uv installed at version {{ ver }}", never
  "Uv {{ ver }} installed").
