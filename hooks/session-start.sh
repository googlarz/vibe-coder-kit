#!/bin/bash
# SessionStart hook — loads vibe-brain context for Claude
# Outputs project memory as context at the start of every session

VIBE_DIR="$(pwd)/.vibe"

if [ ! -d "$VIBE_DIR" ]; then
    # No vibe-brain yet — Claude will set it up via CLAUDE.md instructions
    echo '{"continue":true,"suppressOutput":true}'
    exit 0
fi

# Build context output
OUTPUT=""

if [ -f "$VIBE_DIR/project.md" ]; then
    OUTPUT="$OUTPUT\n=== PROJECT CONTEXT ===\n$(cat "$VIBE_DIR/project.md")\n"
fi

if [ -f "$VIBE_DIR/debt.md" ]; then
    DEBT_ITEMS=$(grep -c "^\-" "$VIBE_DIR/debt.md" 2>/dev/null || echo 0)
    if [ "$DEBT_ITEMS" -gt 0 ]; then
        OUTPUT="$OUTPUT\n=== DEBT LOG ($DEBT_ITEMS items) ===\n$(tail -20 "$VIBE_DIR/debt.md")\n"
    fi
fi

if [ -f "$VIBE_DIR/sessions.md" ]; then
    # Last 3 sessions only
    RECENT=$(awk '/^## /{count++} count<=3{print}' "$VIBE_DIR/sessions.md" 2>/dev/null)
    if [ -n "$RECENT" ]; then
        OUTPUT="$OUTPUT\n=== RECENT SESSIONS ===\n$RECENT\n"
    fi
fi

# Check for production indicators and warn loudly
PROD_SIGNAL=""
if [ -f ".env" ]; then
    if grep -qiE "NODE_ENV=production|VERCEL_ENV=production|APP_ENV=production" .env 2>/dev/null; then
        PROD_SIGNAL="⚠️  PRODUCTION ENVIRONMENT DETECTED — real users and real data"
    fi
fi
if [ -f ".env.production" ]; then
    PROD_SIGNAL="⚠️  .env.production is present — confirm environment before database operations"
fi

if [ -n "$PROD_SIGNAL" ]; then
    OUTPUT="$OUTPUT\n=== ENVIRONMENT WARNING ===\n$PROD_SIGNAL\n"
fi

if [ -n "$OUTPUT" ]; then
    printf "$OUTPUT"
fi

echo '{"continue":true,"suppressOutput":false}'
