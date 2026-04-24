#!/bin/sh
# Output a per-session temporary directory for this shrink invocation.
# Uses SESSION_ID (exported by SessionStart hook) for deterministic paths.
# Falls back to mktemp + breadcrumb if SESSION_ID is unavailable.

BASE="${CLAUDE_CODE_TMPDIR:-/tmp}"

if [ -n "${SESSION_ID:-}" ]; then
  SESSION_DIR="$BASE/shrink-$SESSION_ID"
  mkdir -p "$SESSION_DIR"
else
  # Fallback: random dir + breadcrumb for hook discovery
  SESSION_DIR="$(mktemp -d "$BASE/shrink-XXXXXX")"
  mkdir -p .claude/tmp
  echo "$SESSION_DIR/session-context.md" > .claude/tmp/context-path.txt
fi

echo "$SESSION_DIR"
