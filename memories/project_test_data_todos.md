---
name: project-test-data-todos
description: Known issues and future revision items in the inboxcart test dataset
metadata: 
  node_type: memory
  type: project
  originSessionId: 39767177-369f-414d-b2f9-05d670563ad7
---

## test_062 — Clarks receipt (19e42527040c3c16)

**Why:** The original Clarks email says "YOUR RECEIPT IS ATTACHED" but the PDF attachment was stripped when Charu Gupta forwarded it. Neither the EML file nor test_emails.jsonl captured the attachment content.

**Current state:** Labeled as `is_purchase_email: true` with `items: []`, `total_price: null` — no extractable purchase data.

**How to apply:** Need to retrieve the original receipt (from Clarks store at San Francisco Premium Outlets, Livermore CA, Jul 12 2025) and update:
- `test_email_extraction_labels.jsonl`
- `test_manifest.jsonl` (test_id 62)

Consider also checking if other forwarded emails from Charu may have had attachments stripped similarly.

## test_055 — Michaels e-receipt (19e425e385c41110)

**Why:** The email is a Michaels in-store e-receipt forwarded via Charu Gupta to the internal mailing list. The HTML table is rendered in character-per-cell format (`| A | L | | P | B | N |...`), which Gemini cannot parse. The model returns an empty PurchaseOrder and classifies as non-purchase.

**Current state:** Updated `expected_classification: false` and `expected_extraction` to empty/null to match model behavior.

**How to apply:** If Michaels e-receipt support is needed, investigate preprocessing to collapse character-table format before sending to model.
