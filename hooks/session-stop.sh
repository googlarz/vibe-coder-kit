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
    OUTPUT="${OUTPUT}${NL}${NL}[Unsaved changes detected in: $(echo "$UNSAVED" | tr '\n' ' ') — before we wrap up, offer to save these with /vibe-git or a checkpoint commit.]"
fi

# Remind Claude to write vibe-brain before final response
if [ -d "$VIBE_DIR" ]; then
    TODAY_STOP=$(date '+%Y-%m-%d')
    if [ -f "$VIBE_DIR/sessions.md" ] && grep -q "^## $TODAY_STOP" "$VIBE_DIR/sessions.md" 2>/dev/null; then
        # Today's entry exists — light reminder to keep it current
        OUTPUT="${OUTPUT}${NL}${NL}[REMINDER: .vibe/sessions.md already has today's entry — make sure it reflects everything built this session (Fragile, Test manually).]"
    else
        # No entry yet — stronger reminder with git data to help populate it
        TODAY_COMMITS=$(git log --oneline --after="${TODAY_STOP} 00:00" 2>/dev/null | head -5)
        CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null | head -10)
        CONTEXT=""
        [ -n "$TODAY_COMMITS" ] && CONTEXT="${CONTEXT}${NL}  Commits today: $TODAY_COMMITS"
        [ -n "$CHANGED_FILES" ] && CONTEXT="${CONTEXT}${NL}  Files changed: $(echo "$CHANGED_FILES" | tr '\n' ' ')"
        OUTPUT="${OUTPUT}${NL}${NL}[REQUIRED BEFORE FINAL RESPONSE: No session entry yet for $TODAY_STOP. Write to .vibe/sessions.md now:${NL}  ## [$TODAY_STOP] — [one line: what was done]${NL}  - Changed: [files]${NL}  - Added: [features]${NL}  - Fragile: [anything shaky, or 'nothing notable']${NL}  - Test manually: [what to click through]${CONTEXT}${NL}Without this, the next session starts with no memory of today.]"
    fi
fi

if [ -n "$OUTPUT" ]; then
    printf '%s\n' "$OUTPUT"
fi

exit 0
