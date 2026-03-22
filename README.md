# claude-shrink

A Claude Code plugin for safe context shrinking. Audits loose ends, categorizes
items, saves session context, and prepares the compact/clear command.

## Usage

```sh
/claude-shrink:shrink-nightly [--doc] [--clear] [--force]
```

| Flag | Description |
|------|-------------|
| `--doc` | Include undocumented locked ends in audit |
| `--clear` | Use `/clear` instead of `/compact` |
| `--force` | Force `/clear` even if C items exist |

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
