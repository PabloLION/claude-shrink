#!/bin/sh
# SessionStart hook: distribute session_id to skill scripts via two
# channels.
#
# 1. PID-keyed file at ~/.claude/tmp/session-by-pid/<claude-pid>.
#    Written on every SessionStart event (startup, compact, clear,
#    resume). Skill scripts walk the PPID chain to find it.
# 2. Best-effort export to $CLAUDE_ENV_FILE. Claude Code only sources
#    this on startup events, but the cost is negligible.
#
# Hook $PPID = Claude process PID directly (no intermediate shell).

SESSION_ID="$(jq -r '.session_id // empty')"
CLAUDE_PID="$PPID"

if [ -n "$SESSION_ID" ] && [ -n "$CLAUDE_PID" ]; then
  DIR="$HOME/.claude/tmp/session-by-pid"
  mkdir -p "$DIR"
  printf '%s\n' "$SESSION_ID" > "$DIR/$CLAUDE_PID"

  # Prune entries for dead Claude processes
  for f in "$DIR"/*; do
    [ -e "$f" ] || continue
    p="$(basename "$f")"
    kill -0 "$p" 2>/dev/null || rm -f "$f"
  done
fi

if [ -n "$SESSION_ID" ] && [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "export SESSION_ID=$SESSION_ID" >> "$CLAUDE_ENV_FILE"
fi
