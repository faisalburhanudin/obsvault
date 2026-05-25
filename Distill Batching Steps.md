Goal: reach full distill batching through a sequence of small, reviewable changes.

## Current state

- Step 1 is done: `batch_check_visibility()` is a direct extraction of the old inline
  visibility logic.
- Step 2 is done: `distill()` target collection now flows through a small typed helper.
- `distill()` still does per-selector follow-up work with `page_query_selector()`.
- The current branch still has an iframe-specific follow-up path; do not expand that behavior as
  part of the batching work.

## Landed today

- Committed Step 2 refactor on `feat/optimize-batch-call`.
- Added direct unit coverage for `collect_distill_targets()`.
- Kept the docs file out of the commit so tomorrow can start from these notes.

## Start here tomorrow

- Begin Step 3.
- Add a new helper that performs batched extraction in one `page.evaluate(...)` call.
- Do not wire `distill()` to that helper yet.
- Do not change iframe behavior.
- Do not change selector parsing rules.
- Keep the helper result shape small and explicit so Step 4 can swap it into `distill()`
  without reworking the contract.

## Proposed Step 3 helper contract

- Input: ordered selector entries with:
  - `selector`
  - `is_xpath`
- Output: ordered plain dict payloads keyed by selector index, each containing:
  - `found`
  - `visible`
  - `tag`
  - `text`
  - `html`
  - `value`

## Step 3 test scope

- Add helper-only unit tests with a stub page returning evaluate payloads.
- Cover:
  - CSS selector success
  - XPath selector success
  - missing element
  - hidden element
  - input/select/textarea value extraction
  - invalid evaluate result fallback
- Do not add browser-backed tests in Step 3.

## Step 4 reminder

- Step 4 is the first point where `distill()` should switch from:
  - batched visibility + per-selector `page_query_selector()`
- To:
  - one batched extraction helper for normal selectors
  - existing iframe follow-up path left in place until a later dedicated change
- Before editing `distill()` in Step 4, add or keep stub-based tests for:
  - required vs optional targets
  - `gg-match`
  - `gg-match-html`
  - form value hydration

## Rules for each step

- Keep one behavior change per PR.
- Add or update focused tests for that step only.
- Do not mix extraction batching with selector behavior changes.
- Do not change iframe behavior unless the PR is specifically about iframe behavior.

## Step 1

- Done: extract the old batch visibility code into `batch_check_visibility()`.
- Done: add direct unit tests for the helper.

## Step 2

- Done: refactor `distill()` target collection into a small helper with typed target state.
- Kept the runtime behavior the same:
  - same visibility helper
  - same `page_query_selector()` follow-up
  - same text/html/value extraction path
- No extra tests added for this refactor.

## Step 3

- Add a new helper for batched extraction payloads, but do not switch `distill()` to use it yet.
- The helper should return plain dict data keyed by selector index:
  - `found`
  - `visible`
  - `tag`
  - `text`
  - `html`
  - `value`
- Start with the same selector behavior as the old code:
  - XPath uses `document.evaluate(...)`
  - CSS uses top-document `querySelector(...)`
- Keep iframe selectors out of this helper for now. They can stay on the existing follow-up path
  until a later dedicated change.
- Add focused unit tests for this helper only.

## Step 4

- Switch `distill()` from:
  - batch visibility
  - then per-selector `page_query_selector()`
- To:
  - one batched extraction call
  - then hydrate the BeautifulSoup pattern from returned dict data
- Keep the output behavior the same for:
  - required vs optional targets
  - `gg-match`
  - `gg-match-html`
  - input/select/textarea value handling
- Add focused `distill()` tests with a stub page before running broader browser-backed tests.

## Step 5

- Compare old and new behavior on browser-backed distillation tests.
- Run the existing distillation test file.
- If behavior differs, fix regressions before adding more optimization.

## Step 6

- Only after the full batch extraction path is stable, evaluate follow-up optimizations:
  - iframe-aware batching
  - removing duplicate selector parsing
  - simplifying `distill()` data structures
- Each of these should be separate changes.

## Acceptance point for “full batching”

We can say the batching optimization is complete when:

- `distill()` no longer calls `page_query_selector()` for normal extraction
- one browser-side batch call returns the data needed for hydration
- focused unit tests pass
- browser-backed distillation tests still pass
