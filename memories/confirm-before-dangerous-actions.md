---
name: confirm-before-dangerous-actions
description: "Always consult Faisal before dangerous/cost-incurring actions (creating cloud instances, deletions)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 59b183ee-9094-49a2-a48c-e9bfc185e875
---

Always consult the user first before performing dangerous actions — explicitly including creating GCE instances, and by extension anything cost-incurring (buckets, VMs) or destructive (deletions, teardowns).

**Why:** Cloud resources cost real money and destructive actions are hard to reverse; the user wants to stay in the loop on these even mid-task.

**How to apply:** Before running `gcloud compute instances create/delete`, bucket creation, or similar, stop and ask for explicit confirmation — even if the overall plan was already approved.
