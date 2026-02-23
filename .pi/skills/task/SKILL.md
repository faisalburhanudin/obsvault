---
name: task
description: Taskwarrior CLI task management. Use for adding, viewing, completing, and organizing tasks. Helps with daily task workflow, recurring tasks, and backlog management.
---

# Taskwarrior Skill

Taskwarrior is a command-line task manager that handles recurring tasks, priorities, and due dates automatically.

### Setup

Use one of these approaches:

**Option 1: Environment variable (per session)**

```bash
export TASKDATA="$HOME/.task"
task add "Fix bug" priority:H
task next
```

**Option 2: Inline for one-off commands**

```bash
task rc.data.location:$HOME/.task add "Quick task"
```

## Quick Reference

### Add Tasks

```bash
task add "Pay utility bills" due:eom recur:monthly
task add "Fix AC leak" priority:H project:maintenance
task add "Review PR" due:friday +work
```

### View Tasks

```bash
task                 # pending tasks (default: next report)
task next            # most urgent
task list            # pending with details
task ready           # actionable (not blocked)
task overdue         # overdue
task recurring       # recurring tasks
task all             # all including completed
task completed       # completed tasks
task 42 info         # full details of task 42
```

### Complete/Modify

```bash
task 1 done                    # mark complete
task 1 delete                  # delete task
task 1 modify priority:H       # set priority
task 1 modify project:work     # set project
task 1 modify due:2026-03-01   # set due date
task 1 modify +tag             # add tag
task 1 start                   # start tracking time
task 1 stop                    # stop tracking
```

## Common Workflows

### Daily Standup

```bash
task ready              # what can I do now?
task due:today          # what's due today?
task due.before:today   # what's overdue?
```

### Weekly Review

```bash
task completed end.after:-7days   # what did I finish?
task add "Weekly review" recur:weekly due:sunday
```

### Monthly Tasks

```bash
task add "Review budget" recur:monthly due:eom
task add "Pay bills" recur:monthly due:28th
```

## Attributes & Modifiers

| Attribute   | Example              | Description             |
| ----------- | -------------------- | ----------------------- |
| `priority`  | `priority:H`         | H/M/L (High/Medium/Low) |
| `project`   | `project:work`       | Group tasks             |
| `due`       | `due:friday`         | Due date                |
| `scheduled` | `scheduled:tomorrow` | When to show up         |
| `wait`      | `wait:2weeks`        | Hide until date         |
| `until`     | `until:eoy`          | Expire if not done      |
| `recur`     | `recur:weekly`       | Recurrence              |
| `tags`      | `+work +urgent`      | Keywords                |

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
task project:work +urgent due.before:friday list

# Multiple IDs
task 1 2 3 done
task 1-5 delete

# Complex filters
task '( /urgent/ or /critical/ )' list
task 'project:work or project:personal' list
```

## Tips

1. **Urgency is automatic** — based on due date, priority, age
2. **Use `wait` for someday tasks** — keeps list clean
3. **Projects with subprojects** — `project:work.meeting`
4. **Contexts** — save common filters as contexts
5. **Undo available** — `task undo` after mistakes

## Configuration

User config: `~/.taskrc`

```bash
# Default report when running 'task'
rc.default.command=next

# Contexts (preset filters)
context.work=project:work
task context work    # apply work filter to all commands
```

## Backup & Sync

Data location: `~/.task/`

```bash
# Export all tasks
task export > tasks-backup.json

# Import
task import tasks-backup.json
```
