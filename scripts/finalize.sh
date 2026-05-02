#!/bin/sh
# Finalize shrink: copy command to clipboard, print user instructions.
#
# Usage: finalize.sh [--clear] [--keep]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CLEAR=0
KEEP=0
for arg in "$@"; do
    case "$arg" in
        --clear) CLEAR=1 ;;
        --keep) KEEP=1 ;;
        *) printf 'finalize.sh: unknown arg: %s\n' "$arg" >&2; exit 1 ;;
    esac
done

# Resolve SESSION_DIR (shared between compact and clear paths)
BASE="${CLAUDE_CODE_TMPDIR:-/tmp}"
if [ -z "${SESSION_ID:-}" ]; then
    SESSION_ID="$("$SCRIPT_DIR/find-session-id.sh")"
fi
if [ -n "${SESSION_ID:-}" ]; then
    SESSION_DIR="$BASE/shrink-$SESSION_ID"
else
    BREADCRUMB=".claude/tmp/context-path.txt"
    if [ -f "$BREADCRUMB" ]; then
        SESSION_DIR="$(dirname "$(cat "$BREADCRUMB")")"
    else
        SESSION_DIR="$BASE"
    fi
fi

# Marker file tells PreCompact hook (and next session) to skip cleanup
if [ "$KEEP" = "1" ]; then
    mkdir -p "$SESSION_DIR"
    touch "$SESSION_DIR/.keep"
fi

if [ "$CLEAR" = "1" ]; then
    printf '%s' "/clear" | "$SCRIPT_DIR/clipboard.sh"
    if [ "$KEEP" = "1" ]; then
        cat <<MSG
📎 Copied: /clear

After clear, SessionStart hook reads session-context.md (topic list only).
--keep: files preserved at $SESSION_DIR/ (delete manually).
MSG
    else
        cat <<'MSG'
📎 Copied: /clear

After clear, SessionStart hook reads session-context.md (topic list only),
then deletes it.
MSG
    fi
else
    INSTRUCTION_FILE="$SESSION_DIR/compact-instruction.txt"
    COMPACT_CMD="/compact $(cat "$INSTRUCTION_FILE")"
    printf '%s' "$COMPACT_CMD" | "$SCRIPT_DIR/clipboard.sh"
    if [ "$KEEP" = "1" ]; then
        cat <<MSG
📎 Copied: $COMPACT_CMD

PreCompact hook will copy session context to clipboard.
After compaction, paste to restore context.
--keep: temp files preserved at $SESSION_DIR/ (delete manually).

First prompt in new session: focus on C items (already in compact summary).
MSG
    else
        cat <<MSG
📎 Copied: $COMPACT_CMD

PreCompact hook will copy session context to clipboard.
After compaction, paste to restore context — temp files are auto-deleted.

First prompt in new session: focus on C items (already in compact summary).
MSG
    fi
fi
