#!/bin/bash
# PreToolUse hook — intercepts destructive Bash commands, package installs, and scope violations
# Receives JSON on stdin: {"tool_name": "...", "tool_input": {"command": "..."}} or {"tool_input": {"file_path": "..."}}

INPUT=$(cat)

# Extract command (Bash tool) and file_path (Write/Edit tools) from JSON
COMMAND=""
FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', d).get('command', ''))
except:
    print('')
" 2>/dev/null)
    FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', d).get('file_path', ''))
except:
    print('')
" 2>/dev/null)
else
    # Basic fallback: grep values from raw JSON
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
        | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"[[:space:]]*$//')
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
        | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"[[:space:]]*$//')
fi

[ -z "$COMMAND" ] && [ -z "$FILE_PATH" ] && exit 0

# ── Bash-only checks (destructive patterns + package installs) ────────────────

if [ -n "$COMMAND" ]; then

DESTRUCTIVE=false
REASON=""

if echo "$COMMAND" | grep -qiE "DROP[[:space:]]+TABLE|DROP[[:space:]]+DATABASE|DELETE[[:space:]]+FROM[[:space:]]+|TRUNCATE[[:space:]]+(TABLE[[:space:]]+)?[a-zA-Z\"'\`]"; then
    DESTRUCTIVE=true
    REASON="SQL destructive operation"
fi

if echo "$COMMAND" | grep -qE "rm[[:space:]]+-rf|rm[[:space:]]+-fr|rm[[:space:]]+-r[[:space:]]+-f|rm[[:space:]]+-f[[:space:]]+-r|\\\\rm[[:space:]]+-rf"; then
    DESTRUCTIVE=true
    REASON="recursive file deletion"
fi

if echo "$COMMAND" | grep -qE "git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+clean[[:space:]]+-f|git[[:space:]]+push[[:space:]]+.*--(force|force-with-lease)|git[[:space:]]+push[[:space:]]+-f[[:space:]]|git[[:space:]]+push[[:space:]]+-f$"; then
    DESTRUCTIVE=true
    REASON="destructive git operation"
fi

if echo "$COMMAND" | grep -qE "DROP[[:space:]]+COLUMN|RENAME[[:space:]]+COLUMN|ALTER[[:space:]]+TABLE.*DROP"; then
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

    # Escape command for safe JSON embedding (escape backslashes then double-quotes)
    SAFE_CMD=$(printf '%s' "$COMMAND" | sed 's/\\/\\\\/g; s/"/\\"/g')

    if [ -n "$PROD_ENV" ]; then
        cat <<EOF
{
  "decision": "block",
  "reason": "🚨 BLOCKED — $REASON detected in a PRODUCTION environment ($PROD_ENV).\n\nCommand: $SAFE_CMD\n\nThis could permanently destroy real user data. To proceed:\n1. Confirm you have a database backup\n2. Explicitly tell me this is intentional and you accept the risk\n3. I will run it only after your explicit confirmation"
}
EOF
    else
        cat <<EOF
{
  "decision": "block",
  "reason": "⚠️ BLOCKED — $REASON detected.\n\nCommand: $SAFE_CMD\n\nBefore I run this:\n1. Do you have a checkpoint? If not: git add -A && git commit -m 'checkpoint'\n2. Confirm this is intentional — this cannot be undone."
}
EOF
    fi
    exit 1
fi

# ── Package install detection ──────────────────────────────────────────────────

if echo "$COMMAND" | grep -qE "(^|&&|;)[[:space:]]*(npm install|npm i|yarn add|pnpm add|bun add|pip install|pip3 install)[[:space:]]+"; then
    PACKAGE=$(echo "$COMMAND" | grep -oE "(npm install|npm i|yarn add|pnpm add|bun add|pip install|pip3 install)[[:space:]]+[^;&]+" | head -1 | sed -E 's/(npm install|npm i|yarn add|pnpm add|bun add|pip install|pip3 install)[[:space:]]+//' | tr ' ' '\n' | grep -v '^-' | head -1 | sed 's/["\x27]//g')

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

fi # end Bash-only checks

# ── Scope enforcement — applies to both Bash commands and Write/Edit file paths ─
# Only enforces if the .scope file was written today (DATE field must match)

SCOPE_FILE="$(pwd)/.vibe/.scope"
if [ -f "$SCOPE_FILE" ]; then
    SCOPE_DATE=$(grep "^DATE=" "$SCOPE_FILE" 2>/dev/null | cut -d= -f2-)
    SCOPE_TODAY=$(date '+%Y-%m-%d')
    if [ "$SCOPE_DATE" = "$SCOPE_TODAY" ]; then
        NOT_TOUCHING=$(grep "^NOT_TOUCHING=" "$SCOPE_FILE" 2>/dev/null | cut -d= -f2-)
        SCOPE_DESC=$(grep "^SCOPE=" "$SCOPE_FILE" 2>/dev/null | cut -d= -f2-)
        if [ -n "$NOT_TOUCHING" ]; then
            IFS=',' read -ra PROTECTED <<< "$NOT_TOUCHING"
            for area in "${PROTECTED[@]}"; do
                area=$(echo "$area" | tr -d '[:space:]')
                [ -z "$area" ] && continue
                MATCHED_TARGET=""
                MATCHED_LABEL=""
                if [ -n "$COMMAND" ] && echo "$COMMAND" | grep -qi "$area"; then
                    MATCHED_TARGET="$COMMAND"
                    MATCHED_LABEL="command"
                elif [ -n "$FILE_PATH" ] && echo "$FILE_PATH" | grep -qi "$area"; then
                    MATCHED_TARGET="$FILE_PATH"
                    MATCHED_LABEL="file"
                fi
                if [ -n "$MATCHED_TARGET" ]; then
                    # Escape for safe JSON embedding (backslashes then double-quotes)
                    SAFE_TARGET=$(printf '%s' "$MATCHED_TARGET" | sed 's/\\/\\\\/g; s/"/\\"/g')
                    cat <<EOF
{
  "decision": "block",
  "reason": "⛔ SCOPE — this $MATCHED_LABEL touches \"$area\" which we agreed not to touch today.\n\nToday's scope: $SCOPE_DESC\nProtected: $NOT_TOUCHING\n\n$MATCHED_LABEL: $SAFE_TARGET\n\nIf this is intentional, say \"yes proceed\" and I'll run it. Or say \"add to today's scope\" to update the contract."
}
EOF
                    exit 1
                fi
            done
        fi
    fi
fi

exit 0
