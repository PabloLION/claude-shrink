#!/bin/sh
# Read DEVLOG_DIR from project settings. Outputs the path or "not set".
# Used via DCI in SKILL.md — runs during skill preprocessing.
jq -r '.env.DEVLOG_DIR // "not set"' .claude/settings.local.json 2>/dev/null || echo "not set"
