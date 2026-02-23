---
name: task
description: Taskwarrior CLI task management. Use for adding, viewing, completing, and organizing tasks. Helps with daily task workflow, recurring tasks, and backlog management.
---

# Taskwarrior Skill

Taskwarrior is a command-line task manager that handles recurring tasks, priorities, and due dates automatically.

## Project-Local Storage

This skill uses a project-local task database stored in `.pi/task/` within the current project directory. This keeps tasks isolated per project.

### Setup

Use one of these approaches to avoid typing the path every time:

**Option 1: Shell alias (recommended)**
```bash
alias t='task rc.data.location:.pi/task'
t add "Fix bug" priority:H
t next
```

**Option 2: Environment variable (per session)**
```bash
export TASKDATA="$PWD/.pi/task"
task add "Fix bug" priority:H
task next
```

**Option 3: Inline for one-off commands**
```bash
task rc.data.location:.pi/task add "Quick task"
```

## Quick Reference

### Add Tasks (using `t` alias)
```bash
t add "Pay utility bills" due:eom recur:monthly
t add "Fix AC leak" priority:H project:maintenance
t add "Review PR" due:friday +work
```

### View Tasks
```bash
t                 # pending tasks (default: next report)
t next            # most urgent
t list            # pending with details
t ready           # actionable (not blocked)
t overdue         # overdue
t recurring       # recurring tasks
t all             # all including completed
t completed       # completed tasks
t 42 info         # full details of task 42
```

### Complete/Modify
```bash
t 1 done                    # mark complete
t 1 delete                  # delete task
t 1 modify priority:H       # set priority
t 1 modify project:work     # set project
t 1 modify due:2026-03-01   # set due date
t 1 modify +tag             # add tag
t 1 start                   # start tracking time
t 1 stop                    # stop tracking
```

## Common Workflows

### Daily Standup
```bash
t ready              # what can I do now?
t due:today          # what's due today?
t due.before:today   # what's overdue?
```

### Weekly Review
```bash
t completed end.after:-7days   # what did I finish?
t add "Weekly review" recur:weekly due:sunday
```

### Monthly Tasks
```bash
t add "Review budget" recur:monthly due:eom
t add "Pay bills" recur:monthly due:28th
```

## Attributes & Modifiers

| Attribute | Example | Description |
|-----------|---------|-------------|
| `priority` | `priority:H` | H/M/L (High/Medium/Low) |
| `project` | `project:work` | Group tasks |
| `due` | `due:friday` | Due date |
| `scheduled` | `scheduled:tomorrow` | When to show up |
| `wait` | `wait:2weeks` | Hide until date |
| `until` | `until:eoy` | Expire if not done |
| `recur` | `recur:weekly` | Recurrence |
| `tags` | `+work +urgent` | Keywords |

### Date Keywords
- `today`, `tomorrow`, `yesterday`
- `monday`, `tue`, etc.
- `eow` (end of week), `eom` (end of month), `eoy` (end of year)
- `sow`, `som`, `soy` (start of)
- `now`, `later`, `someday`
- Relative: `2weeks`, `3days`, `1month`

### Filter Modifiers
- `due.before:friday` — due before Friday
- `due.after:today` — due after today
- `due.by:eom` — due by end of month
- `project.is:work` — exact match
- `description.contains:budget` — substring match

## Filters & Reports

```bash
# Filters combine with AND
t project:work +urgent due.before:friday list

# Multiple IDs
t 1 2 3 done
t 1-5 delete

# Complex filters
t '( /urgent/ or /critical/ )' list
t 'project:work or project:personal' list
```

## Tips

1. **Urgency is automatic** — based on due date, priority, age
2. **Use `wait` for someday tasks** — keeps list clean
3. **Projects with subprojects** — `project:work.meeting`
4. **Contexts** — save common filters as contexts
5. **Undo available** — `task undo` after mistakes

## Configuration

Project-local config: `.pi/task/taskrc` (optional)

```bash
# Default report when running 't'
rc.default.command=next

# Contexts (preset filters)
context.work=project:work
t context work    # apply work filter to all commands
```

## Backup & Sync

Data location: `.pi/task/` (project-local)

```bash
# Export all tasks
t export > tasks-backup.json

# Import
t import tasks-backup.json
```
