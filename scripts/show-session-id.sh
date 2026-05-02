#!/bin/sh
# Print a markdown table comparing the current session-id across three
# sources. Backs the show-session-id skill — keeping all logic here
# avoids shell expansions in skill DCI (which Claude Code blocks).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ENV_VAL="${SESSION_ID:-<unset>}"

PID_VAL="$("$SCRIPT_DIR/find-session-id.sh" 2>/dev/null)"
[ -z "$PID_VAL" ] && PID_VAL="<not found>"

JSONL_VAL="$("$SCRIPT_DIR/get-newest-jsonl-id.sh")"
[ -z "$JSONL_VAL" ] && JSONL_VAL="<none>"

cat <<EOF
| Source | Value |
|--------|-------|
| env \$SESSION_ID | $ENV_VAL |
| PID file (PPID-walk) | $PID_VAL |
| Newest jsonl | $JSONL_VAL |
EOF
