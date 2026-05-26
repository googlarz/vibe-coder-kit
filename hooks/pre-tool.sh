#!/bin/bash
# PreToolUse hook — intercepts destructive Bash commands and package installs
# Receives JSON on stdin: {"tool_name": "Bash", "tool_input": {"command": "..."}}

INPUT=$(cat)

# Extract command from JSON
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    inp = d.get('tool_input', d)
    print(inp.get('command', ''))
except:
    print('')
" 2>/dev/null)

[ -z "$COMMAND" ] && exit 0

# ── Destructive pattern detection ─────────────────────────────────────────────

DESTRUCTIVE=false
REASON=""

if echo "$COMMAND" | grep -qiE "DROP\s+TABLE|DROP\s+DATABASE|DELETE\s+FROM\s+[a-z]|TRUNCATE\s+TABLE"; then
    DESTRUCTIVE=true
    REASON="SQL destructive operation"
fi

if echo "$COMMAND" | grep -qE "rm\s+-rf|rm\s+-fr"; then
    DESTRUCTIVE=true
    REASON="recursive file deletion"
fi

if echo "$COMMAND" | grep -qE "git\s+reset\s+--hard|git\s+clean\s+-f|git\s+push\s+.*--force|git\s+push\s+.*-f\b"; then
    DESTRUCTIVE=true
    REASON="destructive git operation"
fi

if echo "$COMMAND" | grep -qE "DROP\s+COLUMN|RENAME\s+COLUMN|ALTER\s+TABLE.*DROP"; then
    DESTRUCTIVE=true
    REASON="database schema change that removes data"
fi

if $DESTRUCTIVE; then
    # Check for production environment
    PROD_ENV=""
    for envfile in .env .env.production .env.local; do
        if [ -f "$envfile" ]; then
            if grep -qiE "NODE_ENV=production|VERCEL_ENV=production|APP_ENV=production|ENVIRONMENT=production" "$envfile" 2>/dev/null; then
                PROD_ENV="$envfile"
                break
            fi
        fi
    done

    if [ -n "$PROD_ENV" ]; then
        cat <<EOF
{
  "decision": "block",
  "reason": "🚨 BLOCKED — $REASON detected in a PRODUCTION environment ($PROD_ENV).\n\nCommand: $COMMAND\n\nThis could permanently destroy real user data. To proceed:\n1. Confirm you have a database backup\n2. Explicitly tell me this is intentional and you accept the risk\n3. I will run it only after your explicit confirmation"
}
EOF
    else
        cat <<EOF
{
  "decision": "block",
  "reason": "⚠️ BLOCKED — $REASON detected.\n\nCommand: $COMMAND\n\nBefore I run this:\n1. Do you have a save point? (if not, say 'vibe save' first)\n2. Confirm this is intentional\n\nThis cannot be undone."
}
EOF
    fi
    exit 1
fi

# ── Package install detection ──────────────────────────────────────────────────

if echo "$COMMAND" | grep -qE "^(npm install|npm i|yarn add|pnpm add|bun add|pip install|pip3 install)\s+"; then
    PACKAGE=$(echo "$COMMAND" | sed -E 's/^(npm install|npm i|yarn add|pnpm add|bun add|pip install|pip3 install)\s+//' | awk '{print $1}' | tr -d '"'"'" )

    # Known typosquatting targets
    SUSPICIOUS_NAMES="lodahs|expres\b|requst|mongoos\b|axois|recat\b|recat-dom|nod[e]js\b|colour\b|coloer"
    if echo "$PACKAGE" | grep -qiE "$SUSPICIOUS_NAMES"; then
        cat <<EOF
{
  "decision": "block",
  "reason": "⚠️ Package name '$PACKAGE' looks like it might be a typo of a popular package.\n\nTypo-squatting is common — malicious packages with similar names to popular ones.\n\nDid you mean a different package? Please confirm the exact name."
}
EOF
        exit 1
    fi

    # Flag dev-only packages being installed without --save-dev
    DEV_ONLY="jest|vitest|eslint|prettier|typescript|@types/|nodemon|ts-node"
    if echo "$PACKAGE" | grep -qiE "$DEV_ONLY" && ! echo "$COMMAND" | grep -qE "\-\-save\-dev|\-D\b"; then
        cat <<EOF
{
  "decision": "block",
  "reason": "ℹ️ '$PACKAGE' is a development tool. It should be installed with --save-dev (or -D) so it doesn't bloat your production app.\n\nShould I add --save-dev to the command?"
}
EOF
        exit 1
    fi
fi

exit 0
