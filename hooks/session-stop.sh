#!/bin/bash
# Stop hook — runs vibe-safe if available, reminds Claude to update vibe-brain
# Outputs a reminder that Claude will see before its final response

VIBE_DIR="$(pwd)/.vibe"

NL=$'\n'
OUTPUT=""

# Run vibe-safe if installed
# Standard install: git clone https://github.com/googlarz/vibe-safe ~/.claude/skills/vibe-safe
VIBE_SAFE_PATH=""
for candidate in \
    "$HOME/.claude/skills/vibe-safe/hooks/pre-commit" \
    "$(which vibe-safe 2>/dev/null)" \
    "$HOME/bin/vibe-safe" \
    "$HOME/.local/bin/vibe-safe" \
    "$(pwd)/vibe-safe.sh"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        VIBE_SAFE_PATH="$candidate"
        break
    fi
done

if [ -n "$VIBE_SAFE_PATH" ]; then
    SAFE_OUTPUT=$(bash "$VIBE_SAFE_PATH" 2>&1)
    SAFE_EXIT=$?

    if echo "$SAFE_OUTPUT" | grep -q "all.*checks passed.*clear"; then
        # Clean — append a brief note so Claude knows (CLEAN_LINE already has "vibe-safe: " prefix)
        CLEAN_LINE=$(echo "$SAFE_OUTPUT" | grep "all.*checks passed.*clear" | head -1)
        OUTPUT="${OUTPUT}${NL}[$CLEAN_LINE]"
    else
        # Extract finding lines (each starts with "vibe-safe: ")
        FINDINGS=$(echo "$SAFE_OUTPUT" | grep "^vibe-safe:" | grep -v "all.*checks passed.*clear")
        if [ -n "$FINDINGS" ]; then
            if [ "$SAFE_EXIT" -ne 0 ]; then
                OUTPUT="${OUTPUT}${NL}${NL}[vibe-safe STOP — do not push until fixed:${NL}$FINDINGS]"
            else
                OUTPUT="${OUTPUT}${NL}${NL}[vibe-safe findings (fix before pushing):${NL}$FINDINGS]"
            fi
        fi
    fi
fi

# Check for unsaved changes — modified tracked files AND new untracked files
UNSTAGED=$(git diff --name-only 2>/dev/null)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | grep -v "^node_modules/" | grep -v "^\.vibe/")
UNSAVED=""
[ -n "$UNSTAGED" ] && UNSAVED="$UNSTAGED"
[ -n "$UNTRACKED" ] && UNSAVED="$UNSAVED $UNTRACKED"
if [ -n "$UNSAVED" ]; then
    OUTPUT="${OUTPUT}${NL}${NL}[Unsaved changes detected in: $(echo "$UNSAVED" | tr '\n' ' ')]"
fi

# Remind Claude to write vibe-brain before final response
if [ -d "$VIBE_DIR" ]; then
    OUTPUT="${OUTPUT}${NL}${NL}[REMINDER: Before your final response, update .vibe/sessions.md with what changed this session — what was built, what's fragile, what to test manually. Without this, the next session starts with no memory of today's work.]"
fi

if [ -n "$OUTPUT" ]; then
    printf '%s\n' "$OUTPUT"
fi

exit 0
