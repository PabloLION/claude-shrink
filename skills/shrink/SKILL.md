---
description: Shrink context safely. Audits loose ends, categorizes items, saves session context.
argument-hint: "[--doc] [--clear] [--force]"
allowed-tools:
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/finalize.sh:*)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/get-devlog-dir.sh)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/get-tmpdir.sh)
  - Bash(${CLAUDE_PLUGIN_ROOT}/scripts/get-timestamp.sh)
  - Bash(git:*)
  - Read
  - Write(${CLAUDE_CODE_TMPDIR}/session-context.md)
  - Write(${CLAUDE_CODE_TMPDIR}/compact-instruction.txt)
  - Edit
  - AskUserQuestion
---

You are shrinking the context safely.

## Arguments

| Arg | Description |
|-----|-------------|
| `--doc` | Include undocumented locked ends in audit. Prompts user to document finished work that lacks notes. |
| `--clear` | Use `/clear` instead of `/compact`. Writes lightweight topic hint only. |
| `--force` | Force `/clear` even if C items exist. Implies `--clear`. |

Without `--doc`: Only audits loose ends (unfinished work).
With `--doc`: Also audits undocumented locked ends (finished work without documentation).

Default behavior is `/compact`. Pass `--clear` for a fresh start with minimal
context bridging. If any C items exist, `/compact` is used regardless of
`--clear` (unless `--force` overrides).

## Process

### 0. Preserve

Before auditing, capture knowledge that would be lost in compaction.

**Extract recurring feedback**

Scan the conversation for patterns the user repeated multiple times or
corrected more than once. Save each as a feedback memory or user-scope rule.
These are the easiest to lose in compaction — always do this explicitly.

**Promote decisions**

Check if any locked decisions from this session should be promoted to a
persistent tier:
- Project rules updates (`.claude/rules/`)
- Memory updates (`~/.claude/projects/.../memory/`)
- ADR or doc updates (project docs)

Skip if no novel decisions were made this session.

### 1. Audit

Scan the current context and produce all items across these buckets:

**Housekeeping** — quick items resolvable in <1 min:
- Uncommitted git changes → show diff summary
- Scratchpad files → show full absolute path, explain if disposable
- Branch housekeeping → merge/rename candidates
- Background agents → list active/completed agents with IDs (carry to session context)

**Undocumented locked ends** (only if `--doc` flag is set):
- Completed work that wasn't written up
- Resolved discussions without notes

**Devlog** (only if DEVLOG_DIR is set):

DEVLOG_DIR: !`${CLAUDE_PLUGIN_ROOT}/scripts/get-devlog-dir.sh`

If DEVLOG_DIR above is set, include a devlog row. Infer the topic from the
session's primary work.

**Loose ends** — substantive unfinished work:
- Unfinished discussion items
- In-progress work not yet dispatched

Locked ends are excluded. However, in_progress issues from an external tracker
represent current session focus — include them as C (continue) candidates.

Present all items in a single numbered table with **Rec** (recommended action)
and **Reason** columns:

```text
┌───┬──────────────────────┬──────────────────────┬─────────────────┬────────┬──────────────────────┐
│ # │ Item                 │ Type                 │ Related Files   │ Rec    │ Reason               │
├───┼──────────────────────┴──────────────────────┴─────────────────┴────────┴──────────────────────┤
│   │ HOUSEKEEPING (<1 min)                                                                        │
├───┼──────────────────────┬──────────────────────┬─────────────────┬────────┬──────────────────────┤
│ 1 │ Uncommitted changes  │ 3 files modified     │ git status      │ commit │ Tracking files only  │
│ 2 │ Scratchpad file      │ Disposable (session) │ ~/path/to/...   │ delete │ Session-only scratch │
├───┼──────────────────────┴──────────────────────┴─────────────────┴────────┴──────────────────────┤
│   │ UNDOCUMENTED LOCKED ENDS (--doc)                                                             │
├───┼──────────────────────┬──────────────────────┬─────────────────┬────────┬──────────────────────┤
│ 3 │ Hooks research       │ Finished, no notes   │ —               │ Y      │ Novel findings       │
├───┼──────────────────────┴──────────────────────┴─────────────────┴────────┴──────────────────────┤
│   │ DEVLOG                                                                                       │
├───┼──────────────────────┬──────────────────────┬─────────────────┬────────┬──────────────────────┤
│ 4 │ Session devlog       │ plugin-migration     │ devlog/         │ Y      │ Multi-session topic  │
├───┼──────────────────────┴──────────────────────┴─────────────────┴────────┴──────────────────────┤
│   │ LOOSE ENDS (unfinished)                                                                      │
├───┼──────────────────────┬──────────────────────┬─────────────────┬────────┬──────────────────────┤
│ 5 │ Pre-compact redesign │ Draft in progress    │ pre-compact.md  │ C      │ Core work ongoing    │
└───┴──────────────────────┴──────────────────────┴─────────────────┴────────┴──────────────────────┘
```

**Rec values by bucket:**

| Bucket | Values | Meaning |
|--------|--------|---------|
| Housekeeping | commit, discard, delete, keep, merge, skip | Action to take |
| Docs (`--doc`) | Y, N | Document or skip |
| Devlog | Y, N | Write entry or skip |
| Loose ends | A (action), B (bead), C (continue), D (drop) | See below |

**Loose end actions:**

| Letter | Action | What it does | When to use |
|--------|--------|--------------|-------------|
| **A** | Action | Resolve directly now | Quick fix, handle before shrinking |
| **B** | Bead | Create beads issue | Needs tracking across sessions |
| **C** | Continue | Carry forward via `/compact` | Core work to continue |
| **D** | Drop | Discard | Not worth preserving |

Do not limit column widths — fit content naturally. If a row exceeds 80
characters, use whichever layout is easiest to read.

If no items found, ask: "All work is done. Use `/compact` to close session?"

### 2. Confirm

Ask the user to confirm with a single AskUserQuestion. Default option (press
enter) accepts all recommendations.

The user can respond in three ways:

1. **Accept all** — press enter (selects default option)
2. **Short codes** — type a sequence matching item numbers, e.g. for 5 items
   with Rec=commit,delete,Y,Y,C: type `commit keep Y N CB` to override #2
   (keep instead of delete), #4 (N instead of Y), #5 (B instead of C)
3. **Natural language** — describe changes, e.g. "keep #2, change #5 to B"

### 3. Execute

Process all confirmed decisions at once.

**Housekeeping:**
- `commit` → stage and commit
- `discard` → discard changes
- `delete` → remove file
- `keep` → no action
- `merge` → merge branch
- `skip` → no action

**Documentation (Y items):**
1. Create/update note file
2. Add to document index
3. Commit documentation changes

**Devlog (Y items):**
1. Slugify topic name for filename (e.g., `plugin-migration.md`)
2. If file exists in DEVLOG_DIR, append dated section. If not, create file
3. Content: date, what was done, decisions made, open questions

Devlog entries are cumulative per topic, not per session.

**Loose ends:**
- **A** → Resolve directly now before continuing shrink
- **B** → Create beads issue (`bd create --title="..." --description="..."`)
- **C** → Collect as focus for next session
- **D** → Acknowledge and discard

**Loose ends file (memory):**

If any C items or unfinished work exist, create `loose-ends-YYYYMMDD.md` in the
user's memory directory. This replaces the previous loose ends file (delete it
first). Include:
- Unfinished design items
- Open questions
- Gaps identified but not addressed
- Items deferred to specific sprints

This file persists across sessions (unlike session-context.md which is
ephemeral). It acts as a safety net if the session context is lost.

Report what was done:

```text
Preserved:
  • Feedback: "no rm -rf" → saved to memory
  • Promoted: session isolation design → project rules

Housekeeping:
  • Uncommitted changes → committed (chore)
  • ~/path/scratch.md → deleted

Documented:
  • Hooks research → hooks-availability.md

Devlog:
  • plugin-migration.md → appended

Actioned:
  • Fixed typo → committed

Created:
  • Issue: cs-xxx "Finalize pre-compact skill"

Focus (carrying forward):
  • Pre-compact redesign draft

Loose ends file:
  • loose-ends-20260407.md → written to memory

Dropped:
  • Old session notes
```

### 4. Decide: Clear vs Compact

Default is always `/compact`. Only use `/clear` when `--clear` flag was passed
AND no C items exist.

| Condition | Action |
|-----------|--------|
| `--force` flag | `/clear` (regardless of C items) |
| Any C items | `/compact` (regardless of `--clear` flag) |
| `--clear` flag, no C items | `/clear` |
| No flag, no C items | `/compact` |

No user confirmation needed — the decision follows deterministically from the
flag and C item count.

### 5. Write Session Context

Write context file to pass information to next session.

TMPDIR: !`${CLAUDE_PLUGIN_ROOT}/scripts/get-tmpdir.sh`
TIMESTAMP: !`${CLAUDE_PLUGIN_ROOT}/scripts/get-timestamp.sh`

**Path:** `TMPDIR/session-context.md` (using TMPDIR value above).

#### Compact path (default)

Write full context — focus on what to carry forward, not what was done:

```markdown
<!-- EPHEMERAL: Single-use file. Delete after reading in next session. -->
# Session Context

Generated: TIMESTAMP
**This file:** TMPDIR/session-context.md

## Next Steps

- C item: what to do next, pending decisions, blockers

## Key Context

Minimal background for next steps. Not a history.

## Background Agents

- Agent ID: <agentId> — <description> — <output_file or "completed">

## User Corrections

Preferences or corrections expressed this session.
```

#### Clear path (`--clear`)

Write lightweight topic hint only:

```markdown
<!-- EPHEMERAL: Single-use file. Delete after reading in next session. -->
# Session Context (clear)

Generated: TIMESTAMP
**This file:** TMPDIR/session-context.md

## Topics

- [locked] Topic name — one-line summary
- [loose] Unfinished topic — tracked in cs-xxx
```

### 6. Finalize

**If compacting:** Write instruction to `TMPDIR/compact-instruction.txt`:

```text
Focus on <C items summary>
```

Then run `${CLAUDE_PLUGIN_ROOT}/scripts/finalize.sh` (no arguments — it reads
the instruction file from TMPDIR internally).

**If clearing:** Run `${CLAUDE_PLUGIN_ROOT}/scripts/finalize.sh --clear`.

Echo the script output to the user. Cleanup is automatic — PreCompact hook
deletes temp files, `/clear` sessions should delete session-context.md after
reading.
