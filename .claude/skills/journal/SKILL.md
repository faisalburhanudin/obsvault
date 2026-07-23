---
name: journal
description: Manage projects/Journaling/Journal.md. Two modes — daily (fast standup: start today, pull a couple backlog items) and weekly groom (deep backlog re-sort, prune, promote items to notes). Invoke when the user types /journal (daily), /journal groom (weekly review), or asks to do their journal / standup / sort the backlog.
---

# Journal

Manage `projects/Journaling/Journal.md`, a personal daily task log, newest-day-first. Do NOT rewrite history — only touch the Backlog and the most recent day(s). Preserve `[[wikilinks]]`, `![[image embeds]]`, tab indentation, and completed `[x]` items exactly. Always ask before deleting a line.

## Modes

- **Daily** (`/journal`, or no argument) — fast. Runs sections 1–3 below. Near-zero friction: reconcile only genuinely stale tasks, start today, confirm today's picks. No re-sorting, no promotion suggestions.
- **Weekly groom** (`/journal groom`) — the deep review. Runs the daily flow PLUS Backlog Grooming (re-sort, prune, promote/demote). This is where the heavy question-driven work lives, so daily stays light.

Pick the mode from the user's invocation. If unclear, default to daily.

## File conventions

- `## Goals` at the very top: long-term goals (mostly financial), each a `[[note]]` that tracks progress, tagged with a status — `started` / `not started` / `done`. Goals are NOT tasks: never check them off, and never offer them as daily picks (section 3 pulls only from Backlog). Only their concrete next-actions belong in a day. Review and update their status during groom. Savings goals stay `not started` until [[Lunasi Hutang]] is done.
- `## Backlog` below Goals: untimed items, **ordered by priority — top = most important**. No priority tags.
- `## YYYY-MM-DD` per day, newest first, directly under Backlog.
- A `---` inside a day separates task groups. Keep it.
- Optional `### Work` / `### Personal` / `### English` subsections — add one only when that day has content for it. Never create empty subsections.
- Footer `Older entries → [[Journal Archive]]` links to `projects/Journaling/Journal Archive.md`.
- Work tasks generally do NOT belong in this Backlog — they live on the team board. Keep the Backlog personal.

---

# Daily flow

### 1. Reconcile stale tasks (only if any)
- Look at the most recent day(s) since the last entry. Collect `- [ ]` items.
- If there are none, say so and move on — no questions.
- If there are stale unchecked tasks, ask (batched) what to do with each: **carry to today**, **move to Backlog**, **keep in place**, or **drop**. Apply the edits.

### 2. Start today
- If there's no `## <today>` heading (date is in session context / `currentDate`), create one at the top, directly under the Backlog block, above the previous day.
- Don't force subsections; add `###` groups only as content arrives.

### 3. Confirm today's picks
- Show the top 3 Backlog items (order = priority).
- Ask which 1–3 to pull into today. Add the chosen ones under today's heading.
- Ongoing items stay in Backlog; one-shot items can be removed from it. Ask if unsure.
- Then stop. Summarize briefly. The repo auto-syncs, so only `git commit` if asked.

---

# Backlog Grooming (weekly / `groom` only)

After the daily flow, do the deeper pass. This is question-driven — it's fine to ask more here.

### Re-sort by priority
- Priority = high reward + urgent. Re-order the Backlog so the top reflects that.
- Ask about anything ambiguous rather than guessing. Confirm the proposed order before writing; never reword items.

### Prune
- Flag stale, done, or duplicate items and ask whether to drop or merge them.
- Flag any work tasks that crept in and offer to remove them (they belong on the team board).

### Promote / demote (inline vs note)
The Backlog holds two forms:
- **Inline** plain text — one-shot atomic items you'll check off and delete (e.g. `ganti ban`, `Dashcam`).
- **Linked** `[[wikilink]]` — items with substance (research, sub-tasks, ongoing themes); detail lives on the note page under `projects/`.

Suggest, don't act:
- Fat inline item (sub-tasks / research / recurring) → offer to promote to a `[[note]]`: on approval, create the page under `projects/`, move detail onto it, replace the line with the wikilink.
- Empty/trivial `[[linked]]` page → offer to demote back to inline.
- Always ask per-item; never auto-promote.

### When adding items
Backlog order encodes priority. When adding a new item (typed or promoted from a day), ask roughly where it ranks rather than defaulting to the bottom.

---

# Archiving (only when asked)
When days pile up and the user wants to trim: cut the oldest day-blocks (keep the recent handful) verbatim into `projects/Journaling/Journal Archive.md`, appending after its existing content. Never delete — always move.
