#!/bin/sh
# Output a per-session temporary directory for this shrink invocation.
# Resolution order:
#   1. SESSION_ID env var (set by SessionStart hook on startup events)
#   2. PID-keyed file lookup (works after /clear and --resume)
#   3. mktemp + breadcrumb (last-resort fallback)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="${CLAUDE_CODE_TMPDIR:-/tmp}"

if [ -z "${SESSION_ID:-}" ]; then
  SESSION_ID="$("$SCRIPT_DIR/find-session-id.sh")"
fi

if [ -n "${SESSION_ID:-}" ]; then
  SESSION_DIR="$BASE/shrink-$SESSION_ID"
  mkdir -p "$SESSION_DIR"
else
  SESSION_DIR="$(mktemp -d "$BASE/shrink-XXXXXX")"
  mkdir -p .claude/tmp
  echo "$SESSION_DIR/session-context.md" > .claude/tmp/context-path.txt
fi

echo "$SESSION_DIR"
