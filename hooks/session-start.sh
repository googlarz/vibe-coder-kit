#!/bin/bash
# SessionStart hook — loads vibe-brain context for Claude
# Outputs project memory as context at the start of every session

VIBE_DIR="$(pwd)/.vibe"

if [ ! -d "$VIBE_DIR" ]; then
    # No vibe-brain yet — Claude will set it up via CLAUDE.md instructions
    echo '{"continue":true}'
    exit 0
fi

# Build context output using real newlines (not \n which bash doesn't interpret in double quotes)
NL=$'\n'
OUTPUT=""

if [ -f "$VIBE_DIR/project.md" ]; then
    OUTPUT="${OUTPUT}${NL}=== PROJECT CONTEXT ===${NL}$(cat "$VIBE_DIR/project.md")${NL}"
fi

if [ -f "$VIBE_DIR/conventions.md" ]; then
    CONV_ITEMS=$(grep -c "^## " "$VIBE_DIR/conventions.md" 2>/dev/null || echo 0)
    if [ "$CONV_ITEMS" -gt 0 ]; then
        # grep -v "^#[^#]" strips the top-level # title but keeps ## section headers
        OUTPUT="${OUTPUT}${NL}=== CONVENTIONS ($CONV_ITEMS) ===${NL}$(grep -v "^#[^#]\|^<!--\|^-->" "$VIBE_DIR/conventions.md")${NL}"
    fi
fi

if [ -f "$VIBE_DIR/bugs.md" ]; then
    BUG_ITEMS=$(grep -c "^## " "$VIBE_DIR/bugs.md" 2>/dev/null || echo 0)
    if [ "$BUG_ITEMS" -gt 0 ]; then
        # grep -v "^#[^#]" strips the top-level # title but keeps ## bug entry headers
        OUTPUT="${OUTPUT}${NL}=== KNOWN BUGS ($BUG_ITEMS) ===${NL}$(grep -v "^#[^#]\|^<!--\|^-->" "$VIBE_DIR/bugs.md")${NL}"
    fi
fi

if [ -f "$VIBE_DIR/gotchas.md" ]; then
    GOTCHA_ITEMS=$(grep -c "^## " "$VIBE_DIR/gotchas.md" 2>/dev/null || echo 0)
    if [ "$GOTCHA_ITEMS" -gt 0 ]; then
        # grep -v "^#[^#]" strips the top-level # title but keeps ## gotcha entry headers
        OUTPUT="${OUTPUT}${NL}=== GOTCHAS ($GOTCHA_ITEMS) ===${NL}$(grep -v "^#[^#]\|^<!--\|^-->" "$VIBE_DIR/gotchas.md")${NL}"
    fi
fi

if [ -f "$VIBE_DIR/decisions.md" ]; then
    DEC_ITEMS=$(grep -c "^## " "$VIBE_DIR/decisions.md" 2>/dev/null || echo 0)
    if [ "$DEC_ITEMS" -gt 0 ]; then
        OUTPUT="${OUTPUT}${NL}=== DECISIONS ($DEC_ITEMS) ===${NL}$(tail -30 "$VIBE_DIR/decisions.md")${NL}"
    fi
fi

if [ -f "$VIBE_DIR/debt.md" ]; then
    DEBT_ITEMS=$(grep -c "^\-" "$VIBE_DIR/debt.md" 2>/dev/null || echo 0)
    if [ "$DEBT_ITEMS" -gt 0 ]; then
        OUTPUT="${OUTPUT}${NL}=== DEBT LOG ($DEBT_ITEMS items) ===${NL}$(tail -20 "$VIBE_DIR/debt.md")${NL}"
    fi
fi

if [ -f "$VIBE_DIR/sessions.md" ]; then
    TODAY=$(date '+%Y-%m-%d')
    SESSION_TODAY=$(grep "^## $TODAY" "$VIBE_DIR/sessions.md" 2>/dev/null)
    if [ -n "$SESSION_TODAY" ]; then
        OUTPUT="${OUTPUT}${NL}=== SESSION ALREADY STARTED TODAY ===${NL}[Scope was already set this session — show a lighter 'picking up from earlier' prompt, not the full 5 questions]${NL}"
    fi
    # Last 3 sessions
    RECENT=$(awk '/^## /{count++} count>0 && count<=3{print}' "$VIBE_DIR/sessions.md" 2>/dev/null)
    if [ -n "$RECENT" ]; then
        OUTPUT="${OUTPUT}${NL}=== RECENT SESSIONS ===${NL}${RECENT}${NL}"
    fi

    # Detect unlogged commits — only if today's session has not been started yet
    # (suppresses spurious warnings for commits made during the current session)
    if [ -z "$SESSION_TODAY" ]; then
        LAST_LOG_DATE=$(grep "^## " "$VIBE_DIR/sessions.md" 2>/dev/null | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
        if [ -n "$LAST_LOG_DATE" ] && [ "$LAST_LOG_DATE" != "$TODAY" ]; then
            UNLOGGED=$(git log --oneline --after="$LAST_LOG_DATE" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$UNLOGGED" -gt 0 ]; then
                OUTPUT="${OUTPUT}${NL}=== SESSION LOG GAP ===${NL}Last session was logged on $LAST_LOG_DATE, but $UNLOGGED commit(s) since then have no session summary.${NL}Run /vibe-explain to document what was built.${NL}"
            fi
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
    OUTPUT="${OUTPUT}${NL}=== ENVIRONMENT WARNING ===${NL}${PROD_SIGNAL}${NL}"
elif [ -n "$DEPLOY_PLATFORM" ]; then
    OUTPUT="${OUTPUT}${NL}=== DEPLOYMENT DETECTED ===${NL}This project is configured for $DEPLOY_PLATFORM. Confirm which environment (local vs live) before any database operations.${NL}"
fi

RULES="${NL}=== SESSION RULES ===${NL}1. One thing at a time — don't front-load multiple findings or options${NL}2. Ask one question, wait for the answer, then ask the next${NL}3. Write to .vibe/ after every completed piece of work — not at end of session${NL}4. Before touching more than 3 files: create a git checkpoint first${NL}"

OUTPUT="${OUTPUT}${RULES}"

if [ -n "$OUTPUT" ]; then
    # Prefix with a sentinel line so Claude Code never mistakes the output for a JSON control directive,
    # even if a vibe-brain file (e.g. project.md) happens to start with '{'.
    printf '=== VIBE BRAIN ===%s' "$OUTPUT"
fi
# exit 0 with text output = inject as context (continue, not suppressed)
# exit 0 with no output = continue silently
