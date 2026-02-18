#!/bin/bash

# Add a task to backlog with smart categorization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG_DIR="$(dirname "$SCRIPT_DIR")"
BACKLOG="$ORG_DIR/backlog/tasks.md"

# Usage
if [ $# -lt 1 ]; then
    echo "Usage: $0 \"Task description\" [priority] [category]"
    echo ""
    echo "Priority: P1 (high), P2 (medium), P3 (low) - default: P2"
    echo "Category: work, personal, health, learning, maintenance - default: auto-detect"
    echo ""
    echo "Examples:"
    echo "  $0 \"Complete project report\" P1 work"
    echo "  $0 \"Buy groceries\" P2 personal"
    echo "  $0 \"Learn Python\" P3 learning"
    exit 1
fi

TASK="$1"
PRIORITY="${2:-P2}"
CATEGORY="${3:-}"
DATE=$(date +%Y-%m-%d)

# Auto-detect category if not specified
if [ -z "$CATEGORY" ]; then
    task_lower=$(echo "$TASK" | tr '[:upper:]' '[:lower:]')
    
    if [[ $task_lower =~ (meeting|email|project|report|deadline|client|boss|work) ]]; then
        CATEGORY="work"
    elif [[ $task_lower =~ (gym|workout|run|exercise|health|doctor|dentist|sleep) ]]; then
        CATEGORY="health"
    elif [[ $task_lower =~ (course|learn|study|book|read|tutorial|skill) ]]; then
        CATEGORY="learning"
    elif [[ $task_lower =~ (clean|fix|repair|buy|backup|update|maintain) ]]; then
        CATEGORY="maintenance"
    else
        CATEGORY="personal"
    fi
fi

# Map category to emoji
case $CATEGORY in
    work) EMOJI="💼" ;; 
    personal) EMOJI="🏠" ;;
    health) EMOJI="💪" ;;
    learning) EMOJI="📚" ;;
    maintenance) EMOJI="🔧" ;;
    *) EMOJI="📌" ;;
esac

# Format priority
if [[ $PRIORITY =~ ^[Pp][123]$ ]]; then
    PRIORITY=$(echo "$PRIORITY" | tr '[:lower:]' '[:upper:]')
else
    PRIORITY="P2"
fi

# Check if section exists, if not create it
if ! grep -q "^## $EMOJI $CATEGORY" "$BACKLOG" 2>/dev/null; then
    # Find the line with "---" before Notes and insert new category there
    # For now, just append to end before the footer
    echo "" >> "$BACKLOG"
    echo "## $EMOJI $CATEGORY" >> "$BACKLOG"
fi

# Find the category section and add task
# This is a simple implementation - adds after the category header
temp_file=$(mktemp)
while IFS= read -r line; do
    echo "$line" >> "$temp_file"
    
    # If we find the category header, add the task after it
    if [[ $line =~ ^##\ $EMOJI\ $CATEGORY ]]; then
        echo "- [ ] [$PRIORITY] ➕ $DATE $TASK" >> "$temp_file"
    fi
done < "$BACKLOG"

mv "$temp_file" "$BACKLOG"

echo "✅ Added to backlog:"
echo "   Task: $TASK"
echo "   Priority: $PRIORITY"
echo "   Category: $EMOJI $CATEGORY"
echo "   Added: $DATE"
