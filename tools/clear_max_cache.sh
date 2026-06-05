#!/bin/bash
# clear_max_cache.sh
# Clears Max 9 compiled object/package cache.
# Forces Max to rescan and recompile on next launch (~1 min startup delay).
# Use when: stale gen code, missing objects, or after major package changes.

DB="$HOME/Library/Application Support/Cycling '74/Max 9/Database"

echo "Max 9 Cache Clear"
echo "-----------------"
echo "Target: $DB"
echo ""
echo "Files to delete:"
ls -lh "$DB"/*.maxdb 2>/dev/null | grep -v "ableton\|_lock\|journal" | awk '{print "  " $NF " (" $5 ")"}'
echo ""
read -p "Delete Max cache files? Max must be closed. [y/N] " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

# Check Max is not running
if pgrep -x "Max" > /dev/null; then
    echo "Error: Max is running. Close Max first."
    exit 1
fi

# Delete main Max cache files (not Ableton, not lock/journal)
deleted=0
for f in "$DB"/macintosh\ hd--applications-max.x64.maxdb \
          "$DB"/macintosh\ hd--applications-max.x64.maxdb.bak \
          "$DB"/macintosh\ hd--applications-max.x64.maxdb.old \
          "$DB"/userdata.maxdb; do
    if [ -f "$f" ]; then
        rm "$f" && echo "Deleted: $(basename "$f")" && ((deleted++))
    fi
done

echo ""
echo "Done — $deleted file(s) deleted."
echo "Max will rescan packages on next launch (expect ~1 min startup delay)."
