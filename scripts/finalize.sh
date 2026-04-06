#!/bin/sh
# Finalize shrink: copy command to clipboard, print user instructions.
#
# Usage: finalize.sh --clear
#    or: finalize.sh          (reads compact instruction via breadcrumb)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$1" = "--clear" ]; then
    printf '%s' "/clear" | "$SCRIPT_DIR/clipboard.sh"
    cat <<'MSG'
📎 Copied: /clear

After clear, SessionStart hook reads session-context.md (topic list only),
then deletes it.
MSG
else
    # Find instruction file via breadcrumb
    BREADCRUMB=".claude/tmp/context-path.txt"
    if [ -f "$BREADCRUMB" ]; then
        SESSION_DIR="$(dirname "$(cat "$BREADCRUMB")")"
    else
        SESSION_DIR="${CLAUDE_CODE_TMPDIR:-/tmp}"
    fi
    INSTRUCTION_FILE="$SESSION_DIR/compact-instruction.txt"
    COMPACT_CMD="/compact $(cat "$INSTRUCTION_FILE")"
    printf '%s' "$COMPACT_CMD" | "$SCRIPT_DIR/clipboard.sh"
    cat <<MSG
📎 Copied: $COMPACT_CMD

PreCompact hook will copy session context to clipboard.
After compaction, paste to restore context — temp files are auto-deleted.

First prompt in new session: focus on C items (already in compact summary).
MSG
fi
