#!/bin/sh
# PreCompact hook: copies session context to clipboard and cleans up.
# After compaction, user pastes the context content directly.
# Files are cleaned up here — no dependency on user action.

BREADCRUMB=".claude/tmp/context-path.txt"

if [ ! -f "$BREADCRUMB" ]; then
    exit 0
fi

CONTEXT_FILE="$(cat "$BREADCRUMB")"

if [ ! -f "$CONTEXT_FILE" ]; then
    rm "$BREADCRUMB"
    exit 0
fi

SESSION_DIR="$(dirname "$CONTEXT_FILE")"
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Copy context content to clipboard (user pastes text, not a command)
cat "$CONTEXT_FILE" | "$PLUGIN_ROOT/scripts/clipboard.sh"

# Clean up session files and breadcrumb
rm "$CONTEXT_FILE" "$SESSION_DIR/compact-instruction.txt"
rmdir "$SESSION_DIR" 2>/dev/null
rm "$BREADCRUMB"

# Output JSON for Claude Code
printf '{"systemMessage":"Session context copied to clipboard. Paste after compaction to restore context."}\n'
