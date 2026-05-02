---
description: Show current Claude Code session-id from three sources for debugging.
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/show-session-id.sh)
---

# Show Session ID

Reports the current session-id from three independent sources. Use this
when something feels off — for example, after `/clear` or `--resume`, the
env var keeps the old value while Claude itself uses a new session-id.

!`${CLAUDE_PLUGIN_ROOT}/scripts/show-session-id.sh`

## How to read this

The PID file is authoritative. The SessionStart hook writes
`~/.claude/tmp/session-by-pid/<claude-pid>` on every event source
(startup, compact, clear, resume), and skill scripts walk the PPID chain
to find the file written by their parent Claude process. If the PID file
shows a value, that is the current session-id.

The env `$SESSION_ID` is correct on `SessionStart:startup` and stays
correct across `/compact` (the session-id does not change at compaction).
It goes stale after `/clear` and `--resume` because Claude Code only
re-sources `$CLAUDE_ENV_FILE` on startup. If env disagrees with the PID
file, do not trust the env. Skill scripts in this plugin already fall
back to the PID file when the env var is missing or wrong.

The newest jsonl is a sanity check, not authoritative. It is the most
recently modified transcript file in the current project's transcript
directory. When multiple Claude sessions share the same project
directory, mtime ordering can favor a session that just exited
(Claude Code may write metadata at session end) over the live one. Treat
disagreement as a question about timing, not a sign the PID file is
wrong.
