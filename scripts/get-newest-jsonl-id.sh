#!/bin/sh
# Print the basename (without .jsonl) of the most recently modified
# transcript file in ~/.claude/projects/<encoded-cwd>/. Empty if none.
# Authoritative current session-id, since Claude Code writes the
# transcript in real time.

ENC="$(echo "$PWD" | sed 's|/|-|g')"
NEWEST="$(ls -t "$HOME/.claude/projects/$ENC"/*.jsonl 2>/dev/null | head -1)"
[ -n "$NEWEST" ] && basename "$NEWEST" .jsonl
