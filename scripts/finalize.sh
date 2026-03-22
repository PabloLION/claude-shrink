#!/bin/sh
# Finalize shrink: copy command to clipboard, print user instructions.
# Replaces steps 9+10 of the shrink skill.
#
# Usage: finalize.sh --clear
#    or: finalize.sh          (reads compact instruction from TMPDIR)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPDIR="${CLAUDE_CODE_TMPDIR:-/tmp}"

if [ "$1" = "--clear" ]; then
    printf '%s' "/clear" | "$SCRIPT_DIR/clipboard.sh"
    cat <<'MSG'
📎 Copied: /clear

After clear, SessionStart hook reads session-context.md (topic list only),
then deletes it.
MSG
else
    INSTRUCTION_FILE="$TMPDIR/compact-instruction.txt"
    COMPACT_CMD="/compact $(cat "$INSTRUCTION_FILE")"
    printf '%s' "$COMPACT_CMD" | "$SCRIPT_DIR/clipboard.sh"
    cat <<MSG
📎 Copied: $COMPACT_CMD

PreCompact hook will copy session context to clipboard.
After compaction, paste to restore context — temp files are auto-deleted.

First prompt in new session: focus on C items (already in compact summary).
MSG
fi
