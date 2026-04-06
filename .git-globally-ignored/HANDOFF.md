# Shrink — Migration Handoff

## Origin

Originally a local user-scope skill at `~/.claude/skills/shrink/`. Moved here
on 2026-03-18 to become a standalone plugin. The old skill is still installed
and actively used — do not remove it until the plugin replacement is tested.

## Migration Status

10 of 16 issues completed. Core migration done. Remaining work is enhancements
and upstream feature requests.

### Completed

- cs-7zf: Migrate from local skill to plugin format
- cs-4mb: Pre-allow skill scripts in allowedTools
- cs-pfh: Add allowed-tools frontmatter field
- cs-h7n: Add per-topic devlog tracking
- cs-qft: Clean up MEMORY.md duplication and clipboard helper
- cs-9vr: Verify recommendation column in audit table
- cs-af1: Add --force flag for clear
- cs-moz: Research: is option A still needed? (yes)
- cs-wr2: Bug: session-context.md not removed after compaction
- cs-9x2: PostToolUse hook: suggest /shrink on branch switch

### In Progress

- cs-8rf: Refactor steps 8-10 into shell scripts with DCI

### Deferred

- cs-i5y [P2]: File upstream FR — trigger /compact from hooks
- cs-awb [P2]: File upstream FR — programmable prompt suggestions
- cs-ws0 [P3]: Use private store for temp files (blocked on Claude Code support)
- cs-8z3 [P4]: Add --log option
- cs-eel [P4]: Add --keep option

## Hook Registration

The `pre-compact.sh` hook is currently registered in `~/.claude/settings.json`
as a PreCompact hook (line ~499), pointing to the old path
`~/.claude/pablo/hooks/pre-compact.sh`. When the plugin is installed:

1. The plugin manifest (`plugin.json`) registers the hook instead
2. The old registration in `settings.json` must be removed
3. The old file at `~/.claude/pablo/hooks/pre-compact.sh` must be deleted

**Not shrink-related** (verified): `session-start.sh` and `session-end.sh` in
`~/.claude/pablo/hooks/` are general logging hooks — they don't interact with
shrink.

## Cleanup (Post-Migration)

After the plugin is installed and tested, remove from old locations.

### Files to Delete

```sh
# Remove known files explicitly (no -rf)
rm ~/.claude/skills/shrink/scripts/clipboard.sh
rm ~/.claude/skills/shrink/scripts/copy-compact-cmd.sh
rm ~/.claude/skills/shrink/SKILL.md
rmdir ~/.claude/skills/shrink/scripts/
rmdir ~/.claude/skills/shrink/
rm ~/.claude/pablo/hooks/pre-compact.sh
```

### Settings to Update

Remove the PreCompact hook entry from `~/.claude/settings.json` (~line 499):

```json
{
  "command": "~/.claude/pablo/hooks/pre-compact.sh"
}
```

The plugin manifest handles hook registration instead.

### Verification Checklist

Before removing old files:

- [ ] Plugin is installed (visible in plugin list)
- [ ] `/claude-shrink:shrink-nightly` invokes the plugin skill
- [ ] PreCompact hook fires from plugin (test with `/compact`)
- [ ] `scripts/finalize.sh` runs without permission prompts
- [ ] Session context file is written and cleaned up correctly
- [ ] Clipboard copy works on both compact and clear paths
- [ ] DCI expands correctly (timestamp, TMPDIR, DEVLOG_DIR)

## Why We Moved On From Write Permission Prompts

`Write(${CLAUDE_CODE_TMPDIR}/...)` in allowed-tools does not suppress permission
prompts when `CLAUDE_CODE_TMPDIR` is unset — the variable expands to empty
instead of the `/tmp` default. Our declarations follow the documented API
correctly. DCI handles the fallback via `:-/tmp`, but allowed-tools has no
equivalent mechanism. This is a platform limitation, not a fixable bug on our
side. Tracked in README under known limitations.
