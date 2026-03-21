#!/bin/sh
# PreCompact hook: copies context read+cleanup command to clipboard
# After compaction, user can paste to read and delete the context file

BREADCRUMB=".claude/tmp/context-path.txt"

if [ ! -f "$BREADCRUMB" ]; then
    echo "⚠️ PreCompact hook: No context breadcrumb found. Run /shrink first." >&2
    exit 0
fi

CONTEXT_FILE=$(cat "$BREADCRUMB")

if [ ! -f "$CONTEXT_FILE" ]; then
    echo "⚠️ PreCompact hook: Context file missing: $CONTEXT_FILE" >&2
    rm -f "$BREADCRUMB"
    exit 0
fi

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Copy command to read context file, then clean up both files
echo "cat \"$CONTEXT_FILE\" && rm \"$CONTEXT_FILE\" \"$(pwd)/$BREADCRUMB\"" | \
    "$PLUGIN_ROOT/scripts/clipboard.sh"

echo "📎 Copied: cat + rm $CONTEXT_FILE" >&2
