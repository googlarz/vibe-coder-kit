#!/bin/bash
# test-hooks.sh — verify pre-tool.sh blocks destructive commands correctly
# Run after install to confirm the hook fires as expected
#
# Usage: bash test-hooks.sh
# Expected: all tests pass

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hooks/pre-tool.sh"

if [ ! -f "$HOOK" ]; then
    echo "ERROR: hooks/pre-tool.sh not found at $HOOK"
    exit 1
fi

PASS=0
FAIL=0

run_test() {
    local name="$1"
    local input="$2"
    local expect="$3"  # "block" or "allow"

    result=$(echo "$input" | bash "$HOOK" 2>/dev/null)
    exit_code=$?

    if [ "$expect" = "block" ]; then
        if [ $exit_code -ne 0 ] && echo "$result" | grep -q '"decision"'; then
            echo "  ✓ BLOCK  $name"
            PASS=$((PASS+1))
        else
            echo "  ✗ MISSED $name (expected block, got exit $exit_code)"
            [ -n "$result" ] && echo "    output: $result"
            FAIL=$((FAIL+1))
        fi
    else
        if [ $exit_code -eq 0 ]; then
            echo "  ✓ ALLOW  $name"
            PASS=$((PASS+1))
        else
            echo "  ✗ WRONG  $name (expected allow, got blocked)"
            [ -n "$result" ] && echo "    output: $result"
            FAIL=$((FAIL+1))
        fi
    fi
}

echo ""
echo "  pre-tool.sh hook tests"
echo "  ──────────────────────"
echo ""
echo "  Destructive commands (should block):"

run_test "rm -rf /tmp/test" \
    '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/test"}}' \
    block

run_test "rm -rf ~ (home dir)" \
    '{"tool_name":"Bash","tool_input":{"command":"rm -rf ~"}}' \
    block

run_test "DROP TABLE users" \
    '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP TABLE users\""}}' \
    block

run_test "DELETE FROM sessions (bare table)" \
    '{"tool_name":"Bash","tool_input":{"command":"sqlite3 app.db \"DELETE FROM sessions\""}}' \
    block

run_test "DELETE FROM \"Users\" (quoted table)" \
    '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DELETE FROM \\\"Users\\\"\""}}' \
    block

run_test "TRUNCATE users" \
    '{"tool_name":"Bash","tool_input":{"command":"psql -c \"TRUNCATE users\""}}' \
    block

run_test "git push --force" \
    '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \
    block

run_test "git push -f" \
    '{"tool_name":"Bash","tool_input":{"command":"git push -f origin main"}}' \
    block

run_test "git reset --hard" \
    '{"tool_name":"Bash","tool_input":{"command":"git reset --hard HEAD~3"}}' \
    block

run_test "git clean -f" \
    '{"tool_name":"Bash","tool_input":{"command":"git clean -f"}}' \
    block

echo ""
echo "  Safe commands (should allow):"

run_test "git status" \
    '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
    allow

run_test "git log --oneline" \
    '{"tool_name":"Bash","tool_input":{"command":"git log --oneline -5"}}' \
    allow

run_test "ls -la" \
    '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
    allow

run_test "npm install express (standalone)" \
    '{"tool_name":"Bash","tool_input":{"command":"npm install express"}}' \
    allow

run_test "cd && npm install express (chained)" \
    '{"tool_name":"Bash","tool_input":{"command":"cd myapp && npm install express"}}' \
    allow

run_test "SELECT query (not DROP/DELETE)" \
    '{"tool_name":"Bash","tool_input":{"command":"psql -c \"SELECT * FROM users LIMIT 5\""}}' \
    allow

run_test "non-Bash tool (Read)" \
    '{"tool_name":"Read","tool_input":{"file_path":"./index.js"}}' \
    allow

# ── Scope enforcement tests ────────────────────────────────────────────────────
# These require a temporary .vibe/.scope file

echo ""
echo "  Scope enforcement (should block when .vibe/.scope is active):"

# Set up a temp scope file
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/.vibe"
TODAY=$(date '+%Y-%m-%d')
cat > "$TEMP_DIR/.vibe/.scope" <<SCOPE
NOT_TOUCHING=payments,auth
SCOPE=add email form
DATE=$TODAY
SCOPE

# Run hook from temp dir to pick up the .scope file
run_scope_test() {
    local name="$1"
    local input="$2"
    local expect="$3"

    result=$(cd "$TEMP_DIR" && echo "$input" | bash "$HOOK" 2>/dev/null)
    exit_code=$?

    if [ "$expect" = "block" ]; then
        if [ $exit_code -ne 0 ] && echo "$result" | grep -q '"decision"'; then
            echo "  ✓ BLOCK  $name"
            PASS=$((PASS+1))
        else
            echo "  ✗ MISSED $name (expected block, got exit $exit_code)"
            [ -n "$result" ] && echo "    output: $result"
            FAIL=$((FAIL+1))
        fi
    else
        if [ $exit_code -eq 0 ]; then
            echo "  ✓ ALLOW  $name"
            PASS=$((PASS+1))
        else
            echo "  ✗ WRONG  $name (expected allow, got blocked)"
            [ -n "$result" ] && echo "    output: $result"
            FAIL=$((FAIL+1))
        fi
    fi
}

run_scope_test "Bash command touching protected area" \
    '{"tool_name":"Bash","tool_input":{"command":"cat src/payments/stripe.js"}}' \
    block

run_scope_test "Write tool touching protected file path" \
    '{"tool_name":"Write","tool_input":{"file_path":"src/auth/login.js","content":"..."}}' \
    block

run_scope_test "Edit tool touching protected file path" \
    '{"tool_name":"Edit","tool_input":{"file_path":"src/payments/checkout.js","old_string":"x","new_string":"y"}}' \
    block

run_scope_test "Safe file outside protected areas" \
    '{"tool_name":"Write","tool_input":{"file_path":"src/profile/email-form.js","content":"..."}}' \
    allow

run_scope_test "Safe bash command outside protected areas" \
    '{"tool_name":"Bash","tool_input":{"command":"cat src/profile/email-form.js"}}' \
    allow

# Test expired scope (yesterday's date — should NOT block)
YESTERDAY_DIR=$(mktemp -d)
mkdir -p "$YESTERDAY_DIR/.vibe"
YESTERDAY=$(date -v-1d '+%Y-%m-%d' 2>/dev/null || date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null)
cat > "$YESTERDAY_DIR/.vibe/.scope" <<SCOPE
NOT_TOUCHING=payments,auth
SCOPE=old scope from yesterday
DATE=$YESTERDAY
SCOPE

run_expired_test() {
    local name="$1"
    local input="$2"
    local expect="$3"

    result=$(cd "$YESTERDAY_DIR" && echo "$input" | bash "$HOOK" 2>/dev/null)
    exit_code=$?

    if [ "$expect" = "block" ]; then
        if [ $exit_code -ne 0 ] && echo "$result" | grep -q '"decision"'; then
            echo "  ✓ BLOCK  $name"
            PASS=$((PASS+1))
        else
            echo "  ✗ MISSED $name (expected block, got exit $exit_code)"
            FAIL=$((FAIL+1))
        fi
    else
        if [ $exit_code -eq 0 ]; then
            echo "  ✓ ALLOW  $name"
            PASS=$((PASS+1))
        else
            echo "  ✗ WRONG  $name (expected allow, got blocked)"
            [ -n "$result" ] && echo "    output: $result"
            FAIL=$((FAIL+1))
        fi
    fi
}

echo ""
echo "  Expired scope (yesterday's date — should NOT block):"

run_expired_test "Expired scope: Write to payments/ should pass" \
    '{"tool_name":"Write","tool_input":{"file_path":"src/payments/stripe.js","content":"x"}}' \
    allow

run_expired_test "Expired scope: bash touching auth should pass" \
    '{"tool_name":"Bash","tool_input":{"command":"cat src/auth/login.js"}}' \
    allow

# Clean up
rm -rf "$TEMP_DIR" "$YESTERDAY_DIR"

echo ""
echo "  ──────────────────────"
echo "  Results: $PASS passed, $FAIL failed"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "  All tests passed — hooks are working correctly."
    echo ""
    exit 0
else
    echo "  Some tests failed. Check hooks/pre-tool.sh and re-run."
    echo "  Tip: The hook receives JSON on stdin and must exit non-zero"
    echo "       with a {\"decision\":\"block\",\"reason\":\"...\"} payload to block."
    echo ""
    exit 1
fi
