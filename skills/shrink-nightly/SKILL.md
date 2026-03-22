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

### 1. Audit

Scan the current context and produce **three buckets**:

**Housekeeping** — quick items resolvable in <1 min:
- Uncommitted git changes → show diff summary
- Scratchpad files → show full absolute path, explain if disposable
- Branch housekeeping → merge/rename candidates
- Background agents → list active/completed agents with IDs (carry to session context)

**Undocumented locked ends** (only if `--doc` flag is set):
- Completed work that wasn't written up
- Resolved discussions without notes

**Loose ends** — substantive unfinished work:
- Unfinished discussion items
- In-progress work not yet dispatched

Locked ends are excluded. However, in_progress issues from an external tracker
represent current session focus — include them as C (continue) candidates in
categorization.

Present all buckets in a numbered table:

```text
┌───┬──────────────────────┬──────────────────────┬─────────────────┬─────┬─────┐
│ # │ Item                 │ Type                 │ Related Files   │ Rec │ Alt │
├───┼──────────────────────┴──────────────────────┴─────────────────┴─────┴─────┤
│   │ HOUSEKEEPING (<1 min)                                                     │
├───┼──────────────────────┬──────────────────────┬─────────────────┬─────┬─────┤
│ 1 │ Uncommitted changes  │ 3 files modified     │ git status      │ —   │ —   │
│ 2 │ Scratchpad file      │ Disposable (session) │ /full/path/...  │ —   │ —   │
├───┼──────────────────────┴──────────────────────┴─────────────────┴─────┴─────┤
│   │ UNDOCUMENTED LOCKED ENDS (--doc)                                          │
├───┼──────────────────────┬──────────────────────┬─────────────────┬─────┬─────┤
│ 3 │ Hooks research       │ Finished, no notes   │ —               │ Y   │ N   │
│ 4 │ Scratchpad behavior  │ Finished, no notes   │ —               │ Y   │ N   │
├───┼──────────────────────┴──────────────────────┴─────────────────┴─────┴─────┤
│   │ LOOSE ENDS (unfinished)                                                   │
├───┼──────────────────────┬──────────────────────┬─────────────────┬─────┬─────┤
│ 5 │ Pre-compact redesign │ Draft in progress    │ pre-compact.md  │ C   │ B   │
└───┴──────────────────────┴──────────────────────┴─────────────────┴─────┴─────┘
```

**Rec** = recommended action, **Alt** = alternative. Housekeeping items use
`—` (resolved in step 2). Documentation items use Y/N. Loose ends use ABCD
letters.

Do not limit column widths — fit content naturally. If a row exceeds 80
characters, use whichever layout is easiest to read.

If no items found, ask: "All work is done. Use `/compact` to close session?"

### 2. Housekeeping Resolution

Resolve housekeeping items from the audit:

- **Uncommitted changes** → show diff, offer: chore commit or discard
- **Scratchpad files** → show full absolute path, explain if disposable, ask:
  keep or delete
- **Branch housekeeping** → merge/rename as needed

Present housekeeping items:

```text
Housekeeping (resolve now):
  1. Uncommitted tracking files → chore commit
  2. /Users/pablo/.claude/.../scratchpad/notes.md → disposable, delete?

Resolve these now? [Y/n]
```

If Y: execute immediately, remove from table.
If N or no housekeeping items: skip to next step.

### 3. Documentation Phase (if --doc)

For each undocumented locked end, use **selection dialog** (Y/N):

```text
Document "Hooks research"?
 ❯ Yes — create note and add to index
   No — skip
```

For items marked Yes:
1. Create/update note file
2. Add to document index
3. Commit documentation changes

### 4. Devlog Phase (if DEVLOG_DIR is set)

DEVLOG_DIR: !`${CLAUDE_PLUGIN_ROOT}/scripts/get-devlog-dir.sh`

If DEVLOG_DIR above is not set, skip this phase silently. Otherwise, offer to
write a devlog entry for the current session's work topic.

```text
Write devlog entry for this session?
Topic: <inferred topic from conversation>
 ❯ Yes — write/append to devlog
   No — skip
```

If Yes:
1. Infer the topic name from the session's primary work
2. Slugify the topic name for the filename (e.g., `plugin-migration.md`)
3. If a file for this topic already exists in `DEVLOG_DIR`, append a new
   dated section. If not, create the file
4. Content: date, what was done, decisions made, open questions

Devlog entries are cumulative per topic, not per session. Multiple sessions
on the same topic append to the same file.

### 5. Categorization Phase

For loose ends, the audit table already shows **Rec** (recommended) and **Alt**
(alternative) actions. User types a **letter sequence** to confirm or override
(plain text, no picker):

| Letter | Action | What it does | When to use |
|--------|--------|--------------|-------------|
| **A** | Action | Resolve directly now | Quick fix, handle before shrinking |
| **B** | Bead | Create beads issue | Needs tracking across sessions |
| **C** | Continue | Carry forward via `/compact` | Core work to continue |
| **D** | Drop | Discard | Not worth preserving |

**Input:** User types letter sequence matching loose end count. Press enter
with no input to accept all recommendations.

Example for 3 loose ends with Rec=B,C,D: enter accepts all, `BCD` confirms
explicitly, `BCB` overrides item 3 from D→B.

### 6. Execute Decisions

Process user's choices from all phases:

**From Housekeeping Resolution:**
- Already executed (committed, deleted, merged)

**From Documentation Phase (Y items):**
- Already executed (notes created, committed)

**From Categorization Phase (ABCD):**
- **A items**: Resolve directly now — execute the action before continuing shrink
- **B items**: Create beads issues (`bd create --title="..." --description="..."`)
- **C items**: Collect as focus for next session
- **D items**: Acknowledge and discard

Report what was created:

```text
Documented:
  • Hooks research → hooks-availability.md
  • Scratchpad behavior → scratchpad-behavior.md

Actioned:
  • Fixed typo in config file → committed

Created:
  • Issue: mf-xxx "Finalize pre-compact skill"

Focus (carrying forward):
  • Pre-compact redesign draft

Dropped:
  • Old session notes
```

### 7. Decide: Clear vs Compact

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

### 8. Write Session Context

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

### 9. Finalize

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
