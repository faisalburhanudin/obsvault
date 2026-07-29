---
name: chores
description: Manage projects/Chores.md, a recurring-chore log (daily/weekly/monthly) with per-day checkboxes and notes. Two modes — daily (stamp today's chores, capture notes, promote blockers to the Journal) and edit (change the Routine definitions, add/remove a chore, add a cadence). Invoke when the user types /chores, /chores edit, or asks to do their chores / check off a chore / add a recurring task.
---

# Chores

Manage `projects/Chores.md`, a recurring-chore log, newest-day-first. Do NOT rewrite history — only touch `## Routine` and the most recent day block(s). Preserve `[[wikilinks]]`, tab indentation, and completed `[x]` items exactly. Always ask before deleting a line.

Chores are the routine. One-off tasks and broken things belong in [[Journal]] — see the handoff rules below.

## Modes

- **Daily** (`/chores`, or no argument) — fast. Runs sections 1–4. Stamp today, ask what got done, capture notes, hand blockers to the Journal. Near-zero friction: no re-reading the Routine aloud, no restructuring.
- **Edit** (`/chores edit`) — change the routine itself: add or retire a chore, rewrite what a chore covers, open a new cadence section. Question-driven; the heavy work lives here so daily stays light.

Pick the mode from the user's invocation. If unclear, default to daily.

## File conventions

- Intro line at top states the Journal handoff rule. Keep it.
- `## Routine` — what each chore actually covers. Bold chore name, then plain (unchecked-box-free) sub-bullets for scope. These are definitions, NOT tasks: never add `- [ ]` here, never check anything off here. Daily entries reference these by name only, so a day block stays one line per chore.
- `## Log` — `### YYYY-MM-DD` per day, newest first, each with one `- [ ]` per daily chore plus a `**Notes:**` line.
- `## Weekly` / `## Monthly` below Log — currently placeholders. A cadence gets its own `### YYYY-MM-DD` log blocks only once it has real chores; never log a weekly chore inside a daily block (it reads as 6 days of misses).
- Empty cadence headings are fine to leave standing — unlike Journal subsections, they're the cadence buckets themselves.

---

# Daily flow

### 1. Stamp today
- Read the file. If there's no `### <today>` under `## Log` (date is in session context / `currentDate`), create one at the top of `## Log`, above the previous day.
- Copy one `- [ ]` line per chore listed under `## Routine`'s daily chores, plus a blank `**Notes:**` line. Use the chore's bold name verbatim — no sub-bullets, no re-typed scope.
- If today's block already exists, leave it alone and go to step 2.

### 2. Ask what got done
- Show today's chore lines and ask which are done. Batch it into one question, multi-select.
- Tick the chosen ones to `- [x]`. Leave the rest unchecked — an unchecked chore at day's end is data, not a failure to chase.
- Do NOT reconcile yesterday's misses. Chores don't carry over; a missed day stays missed. This is the key difference from the Journal.

### 3. Capture notes
- Ask whether anything came up worth noting — a blocker, something that broke, a decision found in a thread.
- Write it under today's `**Notes:**` as plain sub-bullets. Keep the user's wording; don't polish it into a task.
- If nothing came up, leave `**Notes:**` bare and say so. Don't invent an entry.

### 4. Hand blockers to the Journal
- Scan today's notes for anything that needs real follow-up work rather than just a record.
- For each, offer to add it to the [[Journal]] — today's block or the Backlog, ask which. Never write to the Journal without asking.
- The note stays in Chores.md as-is; the Journal gets the actionable version. Don't delete the note.
- Then stop. Summarize briefly. The repo auto-syncs, so only `git commit` if asked.

---

# Edit mode (`/chores edit`)

After the daily flow (or standalone if the user only wants to restructure), do the deeper pass.

### Adding a chore
- Ask which cadence it belongs to, and what it actually covers — the scope sub-bullets are the point; a chore named only "catch up" is easy to tick after a glance and means nothing.
- Add it to `## Routine` with bold name plus scope bullets. Then add its `- [ ]` line to today's log block if the cadence already has one.
- Adding the first chore to an empty cadence: create that cadence's `### <today>` block at the same time.

### Retiring a chore
- Remove it from `## Routine`. Ask before touching past log blocks — the usual move is to leave history intact and simply stop stamping it.
- If the user does something out of habit that no longer earns its slot, say so plainly and offer to retire it.

### Rewriting scope
- Reword the `## Routine` sub-bullets in place. Do not restate the change in past log blocks.
- If a chore's scope keeps growing, flag it: it may want to be two chores, or to become a `[[note]]` under `projects/` with the checklist living there.

### Watch for creep
- A chore that appears in one day block and never again was a one-off — offer to move it to the [[Journal]] Backlog and drop it from the Routine.
- A chore whose sub-bullets have become a research list or a multi-step project belongs in the Journal Backlog as a `[[note]]`, not here.

---

# Archiving (only when asked)
When day blocks pile up: cut the oldest from `## Log` (keep the recent handful) verbatim into `projects/Chores Archive.md`, appending after its existing content. Never delete — always move. Add a footer `Older entries → [[Chores Archive]]` below `## Log` if it isn't there.
