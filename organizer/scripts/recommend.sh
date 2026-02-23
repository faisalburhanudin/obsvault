#!/bin/bash

# Smart task recommendation system
# Analyzes backlog and suggests tasks based on priority, due dates, and patterns

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG_DIR="$(dirname "$SCRIPT_DIR")"
BACKLOG="$ORG_DIR/backlog/tasks.md"
TODO_DIR="$ORG_DIR/todo"

# Output formats
FORMAT_LIST=false
if [ "$1" = "--format-list" ]; then
    FORMAT_LIST=true
fi

# Function to extract and score tasks
score_tasks() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return
    fi
    
    local current_date=$(date +%s)
    local category=""
    
    while IFS= read -r line; do
        # Track category
        if [[ $line =~ ^##\ .* ]]; then
            category=$(echo "$line" | sed 's/^## //' | sed 's/^[💼🏠💪📚🔧] //')
        fi
        
        # Parse task lines (skip empty template tasks)
        if [[ $line =~ ^-\ \[\ \] ]] && [[ ! $line =~ ^-\ \[\ \]\ $ ]]; then
            local task="$line"
            local score=0
            local priority="P3"
            local due_date=""
            local add_date=""
            
            # Extract priority
            if [[ $task =~ \[P1\] ]]; then
                priority="P1"
                score=$((score + 100))
            elif [[ $task =~ \[P2\] ]]; then
                priority="P2"
                score=$((score + 50))
            else
                score=$((score + 10))
            fi
            
            # Extra weight for recurring tasks (♻️ emoji)
            if [[ $task =~ ♻️ ]]; then
                score=$((score + 30))
            fi
            
            # Extract due date
            if [[ $task =~ 📅\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
                due_date="${BASH_REMATCH[1]}"
                local due_ts=$(date -j -f "%Y-%m-%d" "$due_date" +%s 2>/dev/null || echo "$current_date")
                local days_until=$(( (due_ts - current_date) / 86400 ))
                
                # Higher score for urgent due dates
                if [ $days_until -lt 0 ]; then
                    score=$((score + 200))  # Overdue!
                elif [ $days_until -lt 2 ]; then
                    score=$((score + 150))  # Due soon
                elif [ $days_until -lt 7 ]; then
                    score=$((score + 75))   # Due this week
                fi
            fi
            
            # Extract add date (older tasks get bonus)
            if [[ $task =~ ➕\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
                add_date="${BASH_REMATCH[1]}"
                local add_ts=$(date -j -f "%Y-%m-%d" "$add_date" +%s 2>/dev/null || echo "$current_date")
                local days_old=$(( (current_date - add_ts) / 86400 ))
                
                # Small bonus for old tasks (prevent indefinite procrastination)
                if [ $days_old -gt 30 ]; then
                    score=$((score + 25))
                elif [ $days_old -gt 14 ]; then
                    score=$((score + 15))
                fi
            fi
            
            # Output format: score|category|task
            echo "$score|$category|$task"
        fi
    done < "$file"
}

# Get all scored tasks
scored_tasks=$(score_tasks "$BACKLOG")

# Sort by score (descending) and take top 5
recommended=$(echo "$scored_tasks" | sort -t'|' -k1 -rn | head -5)

# Format output
if $FORMAT_LIST; then
    # For use in daily todo template
    if [ -z "$recommended" ]; then
        echo "- [ ] No pending tasks in backlog"
    else
        echo "$recommended" | while IFS='|' read -r score category task; do
            # Clean up task line for todo format
            clean_task=$(echo "$task" | sed 's/- \[ \] //' | sed 's/\[P[123]\] //' | sed 's/📅 [0-9-]* //' | sed 's/➕ [0-9-]* //')
            echo "- [ ] [$category] $clean_task"
        done
    fi
else
    # Human-readable output
    echo "🤖 Smart Task Recommendations"
    echo "=============================="
    echo ""
    
    if [ -z "$recommended" ]; then
        echo "No pending tasks found in backlog."
        exit 0
    fi
    
    echo "Top 5 recommended tasks (based on priority, due dates, and age):"
    echo ""
    
    counter=1
    echo "$recommended" | while IFS='|' read -r score category task; do
        # Extract components for display
        priority=$(echo "$task" | grep -o '\[P[123]\]' || echo "[P3]")
        due=$(echo "$task" | grep -o '📅 [0-9-]*' || echo "")
        age=$(echo "$task" | grep -o '➕ [0-9-]*' || echo "")
        
        # Clean task text
        clean_task=$(echo "$task" | sed 's/- \[ \] //' | sed 's/\[P[123]\] //' | sed 's/📅 [0-9-]* //' | sed 's/➕ [0-9-]* //')
        
        echo "$counter. $priority $category: $clean_task"
        [ -n "$due" ] && echo "   Due: $due"
        [ -n "$age" ] && echo "   Added: $age"
        echo ""
        
        counter=$((counter + 1))
    done
    
    echo "💡 Tip: Add a due date (📅 YYYY-MM-DD) to tasks that need it!"
fi
