#!/bin/bash
# vibe-coder-kit verify — check that hooks are wired up and project is set up
# Usage:
#   bash verify.sh                          — check hooks only (global install)
#   bash verify.sh --project                — also check current project
#   bash verify.sh --project /path/to/proj  — check a specific project

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local label="$1"
    local result="$2"   # "pass" or "fail"
    local hint="$3"
    if [ "$result" = "pass" ]; then
        echo -e "  ${GREEN}✓${NC}  $label"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✗${NC}  $label"
        echo -e "       ${YELLOW}→${NC} $hint"
        FAIL=$((FAIL + 1))
    fi
}

warn() {
    local label="$1"
    local hint="$2"
    echo -e "  ${YELLOW}!${NC}  $label"
    echo -e "       ${YELLOW}→${NC} $hint"
}

echo ""
echo "  vibe-coder-kit verify"
echo "  ─────────────────────"
echo ""
echo "  Hooks"

# Hook scripts exist
for hook in session-start.sh pre-tool.sh session-stop.sh; do
    if [ -f "$INSTALL_DIR/hooks/$hook" ]; then
        check "$hook exists" "pass" ""
    else
        check "$hook exists" "fail" "Re-run the installer: bash $INSTALL_DIR/install.sh"
    fi
done

echo ""
echo "  settings.json"

# settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
    check "settings.json exists" "fail" "Run the installer: bash $INSTALL_DIR/install.sh"
else
    check "settings.json exists" "pass" ""

    # SessionStart registered
    if command -v python3 >/dev/null 2>&1; then
        SESSION_START_OK=$(python3 - <<PYTHON 2>/dev/null
import json
try:
    with open("$SETTINGS_FILE") as f:
        s = json.load(f)
    hooks = s.get("hooks", {})
    for entry in hooks.get("SessionStart", []):
        for h in entry.get("hooks", []):
            if "session-start.sh" in h.get("command", ""):
                print("yes")
                exit()
    print("no")
except:
    print("no")
PYTHON
)
        if [ "$SESSION_START_OK" = "yes" ]; then
            check "SessionStart hook registered" "pass" ""
        else
            check "SessionStart hook registered" "fail" "Re-run: bash $INSTALL_DIR/install.sh"
        fi

        PRE_TOOL_BASH_OK=$(python3 - <<PYTHON 2>/dev/null
import json
try:
    with open("$SETTINGS_FILE") as f:
        s = json.load(f)
    hooks = s.get("hooks", {})
    for entry in hooks.get("PreToolUse", []):
        if entry.get("matcher") == "Bash":
            for h in entry.get("hooks", []):
                if "pre-tool.sh" in h.get("command", ""):
                    print("yes")
                    exit()
    print("no")
except:
    print("no")
PYTHON
)
        if [ "$PRE_TOOL_BASH_OK" = "yes" ]; then
            check "PreToolUse (Bash) hook registered" "pass" ""
        else
            check "PreToolUse (Bash) hook registered" "fail" "Re-run: bash $INSTALL_DIR/install.sh"
        fi

        PRE_TOOL_WRITE_OK=$(python3 - <<PYTHON 2>/dev/null
import json
try:
    with open("$SETTINGS_FILE") as f:
        s = json.load(f)
    hooks = s.get("hooks", {})
    for entry in hooks.get("PreToolUse", []):
        if entry.get("matcher") == "Write|Edit":
            for h in entry.get("hooks", []):
                if "pre-tool.sh" in h.get("command", ""):
                    print("yes")
                    exit()
    print("no")
except:
    print("no")
PYTHON
)
        if [ "$PRE_TOOL_WRITE_OK" = "yes" ]; then
            check "PreToolUse (Write|Edit) hook registered" "pass" ""
        else
            check "PreToolUse (Write|Edit) hook registered" "fail" "Re-run: bash $INSTALL_DIR/install.sh"
        fi

        STOP_OK=$(python3 - <<PYTHON 2>/dev/null
import json
try:
    with open("$SETTINGS_FILE") as f:
        s = json.load(f)
    hooks = s.get("hooks", {})
    for entry in hooks.get("Stop", []):
        for h in entry.get("hooks", []):
            if "session-stop.sh" in h.get("command", ""):
                print("yes")
                exit()
    print("no")
except:
    print("no")
PYTHON
)
        if [ "$STOP_OK" = "yes" ]; then
            check "Stop hook registered" "pass" ""
        else
            check "Stop hook registered" "fail" "Re-run: bash $INSTALL_DIR/install.sh"
        fi
    else
        warn "python3 not found" "Can't verify settings.json — install python3 to check"
    fi
fi

# ── Project checks ─────────────────────────────────────────────────────────────
PROJECT_DIR=""
if [ "$1" = "--project" ] && [ -n "$2" ]; then
    PROJECT_DIR="$(cd "$2" && pwd)"
elif [ "$1" = "--project" ]; then
    PROJECT_DIR="$(pwd)"
fi

if [ -n "$PROJECT_DIR" ]; then
    echo ""
    echo "  Project: $PROJECT_DIR"

    if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
        check "CLAUDE.md present" "pass" ""
    else
        check "CLAUDE.md present" "fail" "Run: bash $INSTALL_DIR/install.sh --project $PROJECT_DIR"
    fi

    if [ -d "$PROJECT_DIR/.vibe" ]; then
        check ".vibe/ directory present" "pass" ""
        for template in project.md sessions.md decisions.md debt.md bugs.md gotchas.md conventions.md; do
            if [ -f "$PROJECT_DIR/.vibe/$template" ]; then
                check "  .vibe/$template" "pass" ""
            else
                check "  .vibe/$template" "fail" "Missing template — run: bash $INSTALL_DIR/install.sh --project $PROJECT_DIR"
            fi
        done
    else
        check ".vibe/ directory present" "fail" "Run: bash $INSTALL_DIR/install.sh --project $PROJECT_DIR"
    fi
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────"
if [ "$FAIL" -eq 0 ]; then
    echo -e "  ${GREEN}All checks passed${NC} ($PASS passed)"
else
    echo -e "  ${RED}$FAIL check(s) failed${NC} ($PASS passed, $FAIL failed)"
    echo ""
    echo "  Re-run the installer to fix most issues:"
    echo "  bash $INSTALL_DIR/install.sh"
fi
echo ""
