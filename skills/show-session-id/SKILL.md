---
description: Show current Claude Code session-id from three sources for debugging.
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/find-session-id.sh)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/get-newest-jsonl-id.sh)
---

# Show Session ID

Reports the current session-id from three independent sources. Use this
when something feels off — for example, after `/clear` or `--resume`, the
env var keeps the old value while Claude itself uses a new session-id.

| Source | Value |
|--------|-------|
| env `$SESSION_ID` | !`echo "${SESSION_ID:-<unset>}"` |
| PID file (PPID-walk) | !`${CLAUDE_PLUGIN_ROOT}/scripts/find-session-id.sh \|\| echo "<not found>"` |
| Newest jsonl | !`${CLAUDE_PLUGIN_ROOT}/scripts/get-newest-jsonl-id.sh` |

## How to read this

The newest jsonl is authoritative — Claude Code writes the transcript in
real time, so its filename equals the live session-id.

The PID file should always agree with the newest jsonl. Skill scripts walk
the PPID chain to find the file written by the SessionStart hook at
`~/.claude/tmp/session-by-pid/<claude-pid>`.

The env `$SESSION_ID` is correct on `SessionStart:startup` and stays correct
across `/compact` (the session-id does not change at compaction). It goes
stale after `/clear` and `--resume` because Claude Code only re-sources
`$CLAUDE_ENV_FILE` on startup.

If env diverges from the other two, do not trust `$SESSION_ID`. Skill
scripts in this plugin already handle that — they fall back to the PID
file when the env var is missing or wrong.
