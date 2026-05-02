# claude-shrink

A Claude Code plugin for safe context shrinking. Audits loose ends, categorizes
items, saves session context, and prepares the compact/clear command.

## Usage

```sh
/claude-shrink:shrink [--doc] [--clear] [--force]
/claude-shrink:show-session-id
```

| Skill | Description |
|-------|-------------|
| `shrink` | Audit loose ends and prepare a compact/clear command |
| `show-session-id` | Report the current session-id from three sources for debugging |

Flags for `shrink`:

| Flag | Description |
|------|-------------|
| `--doc` | Include undocumented locked ends in audit |
| `--clear` | Use `/clear` instead of `/compact` |
| `--force` | Force `/clear` even if C items exist |
| `--log` | Force devlog write (requires DEVLOG_DIR) |
| `--keep` | Preserve session-context.md after compact/clear (debugging) |

## Installation

Register as a local plugin for testing:

```sh
claude --plugin-dir /path/to/claude-shrink
```

## Known Limitations

`${CLAUDE_CODE_TMPDIR}` does not expand in `Write()` allowed-tools patterns
when the environment variable is unset. The variable falls back to empty string
rather than the `/tmp` default, causing a permission prompt when writing
session-context.md and compact-instruction.txt. The allowed-tools declarations
follow the documented API correctly — this is a Claude Code platform limitation.
DCI scripts handle the fallback correctly via shell default syntax
(`${CLAUDE_CODE_TMPDIR:-/tmp}`), but allowed-tools frontmatter has no equivalent
mechanism.

Hooks cannot trigger slash commands. Hooks can react to events (inject context,
block actions) but cannot invoke `/compact`, `/clear`, or other commands. The
use case of auto-triggering shrink and compact on branch switch is not possible.

Prompt suggestions are not programmable. Claude Code's Tab-to-accept suggestions
are auto-generated with no configuration API. Custom suggestions (e.g., suggest
reading session context after shrink) cannot be implemented.

Concurrent same-repo sessions are supported via PID-keyed session-id
distribution. The SessionStart hook writes
`~/.claude/tmp/session-by-pid/<claude-pid>` with the current session-id on every
event source (startup, compact, clear, resume). Skill scripts walk the PPID
chain to find the file written by their parent Claude process; the PID is
globally unique so concurrent sessions cannot collide. Resolution order is env
`$SESSION_ID` → PID file → `mktemp` suffix. The last resort suffix is
isolated but not discoverable by the PreCompact hook without a breadcrumb file.

Claude Code only sources `$CLAUDE_ENV_FILE` on `SessionStart:startup`, so the
env var stays correct across `/compact` (the session-id does not change) but
goes stale after `/clear` and `--resume`. The PID file fallback covers those
cases. Run `/claude-shrink:show-session-id` to inspect all three sources.
