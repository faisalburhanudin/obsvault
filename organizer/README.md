# Personal Organizer

A simple, powerful life organization system with smart recommendations.

## Structure

```
organizer/
├── todo/          # Daily todo lists (YYYY-MM-DD.md)
├── backlog/       # Future tasks & ideas
├── planning/      # Weekly & monthly plans
├── scripts/       # Helper tools
└── README.md      # This file
```

## Quick Start

1. **Morning**: Run `./scripts/today.sh` to create today's todo
2. **Daily**: Check `todo/YYYY-MM-DD.md` for your tasks
3. **Review**: Run `./scripts/recommend.sh` for task suggestions
4. **Backlog**: Store ideas in `backlog/` for later

## Files

- **Daily todos**: Named by date, auto-generated with recommendations
- **Backlog**: `backlog/tasks.md` (categorized), `backlog/ideas.md` (random ideas)
- **Planning**: `planning/weekly.md`, `planning/monthly.md`

## Recommendation System

The system suggests tasks based on:
- Priority (high/medium/low)
- Due dates
- Task age (older = more urgent)
- Category balance (work, personal, health, learning)
- Completion patterns

## Usage

```bash
# Create today's todo with recommendations
./scripts/today.sh

# Get task recommendations
./scripts/recommend.sh

# Add to backlog
./scripts/add-backlog.sh "Task name" priority category

# View stats
./scripts/stats.sh
```
