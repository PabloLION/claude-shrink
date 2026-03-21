---
name: shrink
description: Shrink context safely. Audits loose ends, categorizes items, saves session context.
argument-hint: "[--doc] [--clear]"
---

You are shrinking the context safely.

## Arguments

| Arg | Description |
|-----|-------------|
| `--doc` | Include undocumented locked ends in audit. Prompts user to document finished work that lacks notes. |
| `--clear` | Use `/clear` instead of `/compact`. Writes lightweight topic hint only. |

Without `--doc`: Only audits loose ends (unfinished work).
With `--doc`: Also audits undocumented locked ends (finished work without documentation).

Default behavior is `/compact`. Pass `--clear` for a fresh start with minimal
context bridging. If any C items exist, `/compact` is used regardless of
`--clear`.

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

### 4. Categorization Phase

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

### 5. Execute Decisions

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

### 6. Decide: Clear vs Compact

Default is always `/compact`. Only use `/clear` when `--clear` flag was passed
AND no C items exist.

| Condition | Action |
|-----------|--------|
| Any C items | `/compact` (regardless of `--clear` flag) |
| `--clear` flag, no C items | `/clear` |
| No flag, no C items | `/compact` |

No user confirmation needed — the decision follows deterministically from the
flag and C item count.

### 7. Write Session Context

Write context file to pass information to next session.

**Path:** `<auto-memory-dir>/session-context.md`

Where `<auto-memory-dir>` is the persistent auto memory directory from the system
prompt (e.g., `~/.claude/projects/<encoded-path>/memory/`). This path is stable,
not git-tracked, and persists across sessions.

**Breadcrumb:** After writing the context file, write its absolute path to
`.claude/tmp/context-path.txt` (project-relative). This lets the PreCompact hook
find the file without knowing the encoded auto-memory path.

```sh
mkdir -p .claude/tmp
echo "<absolute-path-to-session-context.md>" > .claude/tmp/context-path.txt
```

#### Compact path (default)

Full context — focus on what to carry forward, not what was done:

```markdown
<!-- EPHEMERAL: Single-use file. Delete after reading in next session. -->
# Session Context

Generated: <timestamp>
**This file:** <full absolute path to this file>

## Next Steps

For each C item:
- What to do next
- Decisions still pending
- Blockers or dependencies

## Key Context

Minimal background needed to understand next steps. Not a history — if it's
committed or tracked in beads, don't repeat it here.

## Background Agents

Active or recently completed background agents. Include agent ID, description,
and output file path so the next context can retrieve results via TaskOutput
or resume via the Task tool's resume parameter.

- Agent ID: <agentId> — <description> — <output_file or "completed">

## User Corrections

Preferences or corrections the user expressed this session. These get lost in
automatic summaries and are worth preserving explicitly.
```

#### Clear path (`--clear`)

Lightweight topic hint — just enough for orientation in a fresh session:

```markdown
<!-- EPHEMERAL: Single-use file. Delete after reading in next session. -->
# Session Context (clear)

Generated: <timestamp>
**This file:** <full absolute path to this file>

## Topics

- [locked] Topic name — one-line summary of outcome
- [locked] Another topic — committed as abc1234
- [loose] Unfinished topic — tracked in mf-xxx
```

No Next Steps, Key Context, Background Agents, or User Corrections. Topics
are listed with `[locked]` or `[loose]` status and a brief summary.

### 8. Generate Command and Copy to Clipboard

Based on decision in step 6:

**If clearing:**
- Copy `/clear` to clipboard (no trailing newline)

**If compacting:**
- Generate instruction: `Focus on <C items summary>`
- Save instruction to `<auto-memory-dir>/compact-instruction.txt`
- Copy `/compact <instruction>` to clipboard (no trailing newline)

To copy to clipboard, run `${CLAUDE_PLUGIN_ROOT}/scripts/copy-compact-cmd.sh <auto-memory-dir>/compact-instruction.txt`.

### 9. Instruct User

Tell user verbally what happens next:

**If clearing:**

```text
📎 Copied: /clear

After clear, SessionStart hook reads session-context.md (topic list only),
then deletes it and .claude/tmp/context-path.txt.
```

**If compacting:**

```text
📎 Copied: /compact <instruction>

PreCompact hook will copy a read+cleanup command to clipboard.
After compaction, paste to read context — both files are auto-deleted.

First prompt in new session: focus on C items (already in compact summary).
```

**Cleanup note:** Session context files are single-use. The PreCompact hook
includes `rm` in the clipboard command. For `/clear`, the new session should
delete `session-context.md` and `.claude/tmp/context-path.txt` after reading.
