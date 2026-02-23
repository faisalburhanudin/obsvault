# Ideas & Someday/Maybe

Random ideas, projects, and things to consider in the future.

## 🚀 Projects

## 🎯 Goals

## 📖 Books to Read

## 🛒 Things to Buy/Research

## 🤔 Questions to Explore

## 🛠️ Tool Ideas

### Task CLI Tool
A command-line interface for managing the entire organizer system without manual file editing.

**Commands:**
```bash
todo today              # View/generate today's todo
todo check <task-num>   # Mark task complete (auto-updates backlog too)
todo add "Task name" --priority P1 --due 2026-03-15 --category Personal
todo backlog            # View all backlog tasks, sorted by score
todo recurring          # List all ♻️ recurring tasks
todo stats              # Weekly completion stats
todo review             # Weekly review mode - prompts for planning
```

**Features:**
- Interactive TUI mode (like `vim`/`htop` for todos)
- Auto-complete for categories and priorities
- Recurring task scheduler (auto-create monthly tasks)
- Integration with calendar (import meetings as tasks)
- Sync with remote (GitHub/web service)
- YAML backend option (hardened schema vs brittle parsing)

**Technical thoughts:**
- Use `fzf` for interactive filtering
- YAML would eliminate regex parsing brittleness
- Could be a standalone Go/Rust binary
- Or extend existing bash scripts with better structured commands

---

*Add anything here without pressure. Review monthly.*
*Cleared: 2026-02-18*
