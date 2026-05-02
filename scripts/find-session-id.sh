#!/bin/sh
# Walk the PPID chain to find the session-id file written by the
# SessionStart hook. Used as a fallback for SESSION_ID after /clear or
# --resume, where Claude Code does not re-source $CLAUDE_ENV_FILE.
#
# Outputs the session-id and exits 0 on match; exits 1 with no output
# otherwise.

DIR="$HOME/.claude/tmp/session-by-pid"

pid=$$
i=0
while [ $i -lt 10 ]; do
  i=$((i + 1))
  case "$pid" in
    ''|0|1) exit 1 ;;
  esac
  if [ -f "$DIR/$pid" ]; then
    cat "$DIR/$pid"
    exit 0
  fi
  pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
done
exit 1
