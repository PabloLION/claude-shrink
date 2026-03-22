#!/bin/sh
# PreCompact hook: copies session context to clipboard and cleans up
# After compaction, user pastes the context content directly.
# Files are cleaned up here — no dependency on user action.

TMPDIR="${CLAUDE_CODE_TMPDIR:-/tmp}"
CONTEXT_FILE="$TMPDIR/session-context.md"

if [ ! -f "$CONTEXT_FILE" ]; then
    exit 0
fi

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Copy context content to clipboard (user pastes text, not a command)
cat "$CONTEXT_FILE" | "$PLUGIN_ROOT/scripts/clipboard.sh"

# Clean up
rm -f "$CONTEXT_FILE" "$TMPDIR/compact-instruction.txt"

# Output JSON for Claude Code
printf '{"systemMessage":"Session context copied to clipboard. Paste after compaction to restore context."}\n'
