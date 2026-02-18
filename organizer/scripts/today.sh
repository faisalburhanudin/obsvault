#!/bin/bash

# Create today's todo list with smart recommendations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG_DIR="$(dirname "$SCRIPT_DIR")"
TODO_DIR="$ORG_DIR/todo"
DATE=$(date +%Y-%m-%d)
FILENAME="$TODO_DIR/$DATE.md"

# Check if already exists
if [ -f "$FILENAME" ]; then
    echo "Today's todo already exists: $FILENAME"
    echo "Opening..."
    cat "$FILENAME"
    exit 0
fi

# Get recommendations
RECOMMENDATIONS=$("$SCRIPT_DIR/recommend.sh" --format-list 2>/dev/null || echo "")

# Create the file
cat > "$FILENAME" << EOF
# Daily Todo - $DATE

## 🌅 Morning Routine
- [ ] 

## 🎯 Top 3 Priorities
1. [ ] 
2. [ ] 
3. [ ] 

## 📋 Recommended Tasks from Backlog
$RECOMMENDATIONS

## 🍃 Evening Routine
- [ ] Review tomorrow's schedule
- [ ] Reflect on the day

## 📝 Notes


## ✅ Completion
- **Total Tasks:** 
- **Completed:** 
- **Completion Rate:** %

---

*Created: $DATE*
EOF

echo "✅ Created today's todo: $FILENAME"
echo ""
echo "📋 Recommended tasks from backlog:"
echo "$RECOMMENDATIONS"
