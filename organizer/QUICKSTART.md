# 🚀 Quick Start Guide

## Daily Workflow

### Morning (5 minutes)
```bash
cd organizer
./scripts/today.sh          # Create today's todo with smart recommendations
```

### During the Day
1. Open `todo/YYYY-MM-DD.md`
2. Add new tasks as they come
3. Check off completed tasks: `- [x]`
4. Move unfinished tasks to backlog or tomorrow

### Evening (5 minutes)
1. Fill in completion stats
2. Run `./scripts/stats.sh` to see your progress
3. Run `./scripts/recommend.sh` for tomorrow's suggestions

## Common Commands

```bash
# Get smart task recommendations
./scripts/recommend.sh

# Add task to backlog with auto-categorization
./scripts/add-backlog.sh "Task name" P2 work

# See your stats
./scripts/stats.sh

# View today's todo
cat todo/$(date +%Y-%m-%d).md
```

## Tips

### Priorities
- **P1** = Do today (high priority)
- **P2** = Do this week (medium priority)  
- **P3** = Do when free (low priority)

### Due Dates
Add `📅 YYYY-MM-DD` to tasks that need deadlines. The recommendation system will prioritize them!

### Categories
The `add-backlog.sh` script auto-detects:
- 💼 Work: meetings, emails, reports
- 💪 Health: gym, doctor, sleep
- 📚 Learning: courses, books, skills
- 🔧 Maintenance: clean, fix, buy
- 🏠 Personal: everything else

## Example Day

```bash
# Morning
cd organizer
./scripts/today.sh

# New task comes in - add to backlog
./scripts/add-backlog.sh "Email client about project" P1 work

# Evening - check stats
./scripts/stats.sh
```

---

*Happy organizing! 🎯*
