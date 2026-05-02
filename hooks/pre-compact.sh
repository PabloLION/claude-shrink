#!/bin/sh
# PreCompact hook: copies session context to clipboard and cleans up.
# After compaction, user pastes the context content directly.
# Files are cleaned up here — no dependency on user action.
#
# Discovery order:
#   1. session_id from JSON stdin (per-session, no collision)
#   2. Breadcrumb file (legacy fallback, per-project-directory)

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${CLAUDE_CODE_TMPDIR:-/tmp}"

# Read session_id from JSON stdin
INPUT="$(cat)"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty')"

# Try session_id path first
if [ -n "$SESSION_ID" ] && [ -f "$BASE/shrink-$SESSION_ID/session-context.md" ]; then
  CONTEXT_FILE="$BASE/shrink-$SESSION_ID/session-context.md"
else
  # Fallback: breadcrumb file
  BREADCRUMB=".claude/tmp/context-path.txt"
  if [ ! -f "$BREADCRUMB" ]; then
    exit 0
  fi
  CONTEXT_FILE="$(cat "$BREADCRUMB")"
  rm "$BREADCRUMB"

  if [ ! -f "$CONTEXT_FILE" ]; then
    exit 0
  fi
fi

SESSION_DIR="$(dirname "$CONTEXT_FILE")"

# Copy context content to clipboard (user pastes text, not a command)
cat "$CONTEXT_FILE" | "$PLUGIN_ROOT/scripts/clipboard.sh"

# Clean up session files unless --keep marker exists
if [ -f "$SESSION_DIR/.keep" ]; then
  printf '{"systemMessage":"Session context copied to clipboard. --keep: temp files preserved at %s/."}\n' "$SESSION_DIR"
else
  rm "$CONTEXT_FILE" "$SESSION_DIR/compact-instruction.txt" 2>/dev/null
  rmdir "$SESSION_DIR" 2>/dev/null
  printf '{"systemMessage":"Session context copied to clipboard. Paste after compaction to restore context."}\n'
fi
