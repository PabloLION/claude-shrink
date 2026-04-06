#!/bin/sh
# Create and output a unique temporary directory for this shrink session.
# Prevents collision when multiple sessions shrink concurrently.
BASE="${CLAUDE_CODE_TMPDIR:-/tmp}"
SESSION_DIR="$(mktemp -d "$BASE/shrink-XXXXXX")"

# Write breadcrumb so hooks and finalize.sh can find session files
mkdir -p .claude/tmp
echo "$SESSION_DIR/session-context.md" > .claude/tmp/context-path.txt

echo "$SESSION_DIR"
