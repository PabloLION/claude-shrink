#!/bin/sh
# Copy stdin to system clipboard. Cross-platform: macOS, Linux, WSL.
# Usage: echo "text" | ./clipboard.sh

if command -v pbcopy >/dev/null 2>&1; then
    pbcopy
elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
elif command -v clip.exe >/dev/null 2>&1; then
    clip.exe
else
    echo "⚠️ No clipboard tool found (pbcopy, xclip, clip.exe)" >&2
    exit 1
fi
