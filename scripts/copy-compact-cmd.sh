#!/bin/sh
# Build compact command from instruction file and copy to clipboard
# Usage: copy-compact-cmd.sh <path-to-compact-instruction.txt>

INSTRUCTION_FILE="${1:?Usage: copy-compact-cmd.sh <path-to-compact-instruction.txt>}"
COMPACT_CMD="/compact $(cat "$INSTRUCTION_FILE")"
echo "$COMPACT_CMD"
printf '%s' "$COMPACT_CMD" | \
  if command -v pbcopy >/dev/null 2>&1; then pbcopy; \
  elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard; \
  elif command -v clip.exe >/dev/null 2>&1; then clip.exe; \
  fi
