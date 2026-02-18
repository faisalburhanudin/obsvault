#!/bin/bash

# Show completion statistics and insights

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG_DIR="$(dirname "$SCRIPT_DIR")"
TODO_DIR="$ORG_DIR/todo"
BACKLOG="$ORG_DIR/backlog/tasks.md"

echo "📊 Personal Organizer Stats"
echo "=========================="
echo ""

# Count todos
todo_count=$(find "$TODO_DIR" -name "*.md" -type f ! -name "template.md" 2>/dev/null | wc -l)
echo "📅 Daily todos created: $todo_count"

# Analyze this week's todos
echo ""
echo "📈 This Week's Activity"
echo "----------------------"

for i in 0 1 2 3 4 5 6; do
    date_str=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "-${i} days" +%Y-%m-%d)
    file="$TODO_DIR/$date_str.md"
    
    if [ -f "$file" ]; then
        total=$(grep -c "^\- \[ \]" "$file" 2>/dev/null || echo "0")
        done=$(grep -c "^\- \[x\]" "$file" 2>/dev/null || echo "0")
        
        # Get day name
        day_name=$(date -j -f "%Y-%m-%d" "$date_str" +%a 2>/dev/null || date -d "$date_str" +%a)
        
        # Calculate percentage
        if [ "$total" -gt 0 ] || [ "$done" -gt 0 ]; then
            total_all=$((total + done))
            pct=$((done * 100 / total_all))
            echo "  $day_name $date_str: $done/$total_all completed ($pct%)"
        else
            echo "  $day_name $date_str: No tasks"
        fi
    fi
done

# Backlog stats
echo ""
echo "🗂️  Backlog Overview"
echo "--------------------"

if [ -f "$BACKLOG" ]; then
    # Count by priority
    p1=$(grep -c '\[P1\]' "$BACKLOG" 2>/dev/null || echo "0")
    p2=$(grep -c '\[P2\]' "$BACKLOG" 2>/dev/null || echo "0")
    p3=$(grep -c '\[P3\]' "$BACKLOG" 2>/dev/null || echo "0")
    
    echo "  High priority (P1): $p1"
    echo "  Medium priority (P2): $p2"
    echo "  Low priority (P3): $p3"
    
    # Count with due dates
    with_due=$(grep -c '📅' "$BACKLOG" 2>/dev/null || echo "0")
    echo "  Tasks with due dates: $with_due"
    
    # Overdue tasks
    today=$(date +%Y-%m-%d)
    overdue=0
    while IFS= read -r line; do
        if [[ $line =~ 📅\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            due_date="${BASH_REMATCH[1]}"
            if [[ "$due_date" < "$today" ]]; then
                overdue=$((overdue + 1))
            fi
        fi
    done < "$BACKLOG"
    
    if [ $overdue -gt 0 ]; then
        echo ""
        echo "⚠️  OVERDUE TASKS: $overdue"
    fi
fi

echo ""
echo "💡 Run ./recommend.sh for task suggestions"
