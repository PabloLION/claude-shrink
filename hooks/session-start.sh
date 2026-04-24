#!/bin/sh
# SessionStart hook: export session_id so skill scripts can build
# deterministic per-session paths (e.g., /tmp/shrink-<session_id>/).
# Hooks receive session_id in JSON stdin; skill scripts get it via
# the exported SESSION_ID env var.

SESSION_ID="$(cat | jq -r '.session_id')"

if [ -n "$SESSION_ID" ] && [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "export SESSION_ID=$SESSION_ID" >> "$CLAUDE_ENV_FILE"
fi
