#!/bin/bash
# Stop hook — runs vibe-safe if available, reminds Claude to update vibe-brain
# Outputs a reminder that Claude will see before its final response

VIBE_DIR="$(pwd)/.vibe"

OUTPUT=""

# Run vibe-safe if installed
VIBE_SAFE_PATH=""
for path in \
    "$(which vibe-safe 2>/dev/null)" \
    "$HOME/bin/vibe-safe" \
    "$HOME/.local/bin/vibe-safe" \
    "$(pwd)/vibe-safe" \
    "$(pwd)/vibe-safe.sh"; do
    if [ -x "$path" ]; then
        VIBE_SAFE_PATH="$path"
        break
    fi
done

if [ -n "$VIBE_SAFE_PATH" ]; then
    SAFE_RESULT=$(bash "$VIBE_SAFE_PATH" 2>&1 | tail -5)
    OUTPUT="$OUTPUT\nvibe-safe scan: $SAFE_RESULT"
fi

# Check if .vibe exists — remind Claude to update it
if [ -d "$VIBE_DIR" ]; then
    OUTPUT="$OUTPUT\n\n[REMINDER: Update .vibe/sessions.md with what changed this session, and .vibe/debt.md if any shortcuts were taken.]"
fi

# Check for unstaged changes
UNSTAGED=$(git diff --name-only 2>/dev/null)
if [ -n "$UNSTAGED" ]; then
    OUTPUT="$OUTPUT\n\n[Unsaved changes detected in: $(echo "$UNSTAGED" | tr '\n' ' ')]"
fi

if [ -n "$OUTPUT" ]; then
    printf "$OUTPUT\n"
fi

exit 0
