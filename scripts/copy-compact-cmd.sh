#!/bin/sh
# Build compact command from instruction file and copy to clipboard
# Usage: copy-compact-cmd.sh <path-to-compact-instruction.txt>

INSTRUCTION_FILE="${1:?Usage: copy-compact-cmd.sh <path-to-compact-instruction.txt>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPACT_CMD="/compact $(cat "$INSTRUCTION_FILE")"
echo "$COMPACT_CMD"
printf '%s' "$COMPACT_CMD" | "$SCRIPT_DIR/clipboard.sh"
