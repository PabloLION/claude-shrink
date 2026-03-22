#!/bin/sh
# Write session-context.md to CLAUDE_CODE_TMPDIR from stdin.
# Usage: echo "content" | write-session-context.sh
TMPDIR="${CLAUDE_CODE_TMPDIR:-/tmp}"
mkdir -p "$TMPDIR"
cat > "$TMPDIR/session-context.md"
