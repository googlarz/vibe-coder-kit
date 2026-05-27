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

if [ -f "$VIBE_DIR/conventions.md" ]; then
    CONV_ITEMS=$(grep -c "^## " "$VIBE_DIR/conventions.md" 2>/dev/null || echo 0)
    if [ "$CONV_ITEMS" -gt 0 ]; then
        OUTPUT="$OUTPUT\n=== CONVENTIONS ($CONV_ITEMS) ===\n$(grep -v "^#[^#]\|^<!--\|^-->" "$VIBE_DIR/conventions.md")\n"
    fi
fi

if [ -f "$VIBE_DIR/bugs.md" ]; then
    BUG_ITEMS=$(grep -c "^## " "$VIBE_DIR/bugs.md" 2>/dev/null || echo 0)
    if [ "$BUG_ITEMS" -gt 0 ]; then
        OUTPUT="$OUTPUT\n=== KNOWN BUGS ($BUG_ITEMS) ===\n$(cat "$VIBE_DIR/bugs.md" | grep -v "^#\|^<!--\|^-->")\n"
    fi
fi

if [ -f "$VIBE_DIR/gotchas.md" ]; then
    GOTCHA_ITEMS=$(grep -c "^## " "$VIBE_DIR/gotchas.md" 2>/dev/null || echo 0)
    if [ "$GOTCHA_ITEMS" -gt 0 ]; then
        OUTPUT="$OUTPUT\n=== GOTCHAS ($GOTCHA_ITEMS) ===\n$(cat "$VIBE_DIR/gotchas.md" | grep -v "^#\|^<!--\|^-->")\n"
    fi
fi

if [ -f "$VIBE_DIR/decisions.md" ]; then
    DEC_ITEMS=$(grep -c "^## " "$VIBE_DIR/decisions.md" 2>/dev/null || echo 0)
    if [ "$DEC_ITEMS" -gt 0 ]; then
        OUTPUT="$OUTPUT\n=== DECISIONS ($DEC_ITEMS) ===\n$(tail -30 "$VIBE_DIR/decisions.md")\n"
    fi
fi

if [ -f "$VIBE_DIR/debt.md" ]; then
    DEBT_ITEMS=$(grep -c "^\-" "$VIBE_DIR/debt.md" 2>/dev/null || echo 0)
    if [ "$DEBT_ITEMS" -gt 0 ]; then
        OUTPUT="$OUTPUT\n=== DEBT LOG ($DEBT_ITEMS items) ===\n$(tail -20 "$VIBE_DIR/debt.md")\n"
    fi
fi

if [ -f "$VIBE_DIR/sessions.md" ]; then
    TODAY=$(date '+%Y-%m-%d')
    SESSION_TODAY=$(grep "^## $TODAY" "$VIBE_DIR/sessions.md" 2>/dev/null)
    if [ -n "$SESSION_TODAY" ]; then
        OUTPUT="$OUTPUT\n=== SESSION ALREADY STARTED TODAY ===\n[Scope was already set this session — show a lighter 'picking up from earlier' prompt, not the full 5 questions]\n"
    fi
    # Last 3 sessions
    RECENT=$(awk '/^## /{count++} count>0 && count<=3{print}' "$VIBE_DIR/sessions.md" 2>/dev/null)
    if [ -n "$RECENT" ]; then
        OUTPUT="$OUTPUT\n=== RECENT SESSIONS ===\n$RECENT\n"
    fi

    # Detect unlogged commits — commits that exist after the last session entry date
    LAST_LOG_DATE=$(grep "^## " "$VIBE_DIR/sessions.md" 2>/dev/null | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    if [ -n "$LAST_LOG_DATE" ] && [ "$LAST_LOG_DATE" != "$TODAY" ]; then
        UNLOGGED=$(git log --oneline --after="$LAST_LOG_DATE" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$UNLOGGED" -gt 0 ]; then
            OUTPUT="$OUTPUT\n=== SESSION LOG GAP ===\nLast session was logged on $LAST_LOG_DATE, but $UNLOGGED commit(s) since then have no session summary.\nRun /vibe-explain to document what was built.\n"
        fi
    fi
fi

# Check for production indicators — env files AND deployment platform configs
PROD_SIGNAL=""
DEPLOY_PLATFORM=""

# Env file checks
for envfile in .env .env.production .env.local; do
    if [ -f "$envfile" ]; then
        if grep -qiE "NODE_ENV=production|VERCEL_ENV=production|APP_ENV=production|ENVIRONMENT=production" "$envfile" 2>/dev/null; then
            PROD_SIGNAL="⚠️  PRODUCTION — $envfile has production environment variables"
            break
        fi
    fi
done

# Deployment platform detection (these files mean the project is live somewhere)
if [ -f "vercel.json" ] || [ -d ".vercel" ]; then
    DEPLOY_PLATFORM="Vercel"
elif [ -f "railway.toml" ] || [ -f "railway.json" ]; then
    DEPLOY_PLATFORM="Railway"
elif [ -f "fly.toml" ]; then
    DEPLOY_PLATFORM="Fly.io"
elif [ -f "render.yaml" ] || [ -f "render.yml" ]; then
    DEPLOY_PLATFORM="Render"
elif [ -f "netlify.toml" ] || [ -d ".netlify" ]; then
    DEPLOY_PLATFORM="Netlify"
elif [ -f "Dockerfile" ] && [ -f "docker-compose.yml" ]; then
    DEPLOY_PLATFORM="Docker"
fi

if [ -n "$PROD_SIGNAL" ]; then
    OUTPUT="$OUTPUT\n=== ENVIRONMENT WARNING ===\n$PROD_SIGNAL\n"
elif [ -n "$DEPLOY_PLATFORM" ]; then
    OUTPUT="$OUTPUT\n=== DEPLOYMENT DETECTED ===\nThis project is configured for $DEPLOY_PLATFORM. Confirm which environment (local vs live) before any database operations.\n"
fi

if [ -n "$OUTPUT" ]; then
    printf '%s' "$OUTPUT"
fi
# exit 0 with text output = inject as context (continue, not suppressed)
# exit 0 with no output = continue silently
