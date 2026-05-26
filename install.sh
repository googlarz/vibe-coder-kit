#!/bin/bash
# vibe-skills installer
# Usage:
#   bash install.sh              — global install only (hooks + skills)
#   bash install.sh --project    — set up current directory as a vibe-skills project
#   bash install.sh /path/to/project — set up a specific project directory

set -e

VIBE_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
INSTALL_DIR="$CLAUDE_DIR/vibe-skills"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# ── Colors ─────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "  vibe-skills installer"
echo "  ─────────────────────"
echo ""

# ── Determine project directory ───────────────────────────────────────────────
PROJECT_DIR=""

if [ "$1" = "--project" ]; then
    PROJECT_DIR="$(pwd)"
elif [ -n "$1" ] && [ "$1" != "--global" ]; then
    PROJECT_DIR="$(cd "$1" && pwd)"
fi

# Warn if running from inside the vibe-skills repo itself
if [ "$(pwd)" = "$VIBE_SKILLS_DIR" ] && [ -z "$PROJECT_DIR" ] && [ "$1" != "--global" ]; then
    echo -e "  ${YELLOW}!${NC} You're running install.sh from inside the vibe-skills directory."
    echo ""
    echo "  To set up a project, run from your project directory:"
    echo "  cd /path/to/your-project && bash $VIBE_SKILLS_DIR/install.sh --project"
    echo ""
    echo "  To install globally only (hooks + skills, no project setup):"
    echo "  bash $VIBE_SKILLS_DIR/install.sh --global"
    echo ""
    read -p "  Install globally only (no project setup)? [Y/n] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "  Cancelled."
        exit 0
    fi
fi

# ── 1. Create install directory ────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR/hooks"
mkdir -p "$INSTALL_DIR/skills"

# ── 2. Copy hooks ──────────────────────────────────────────────────────────────
echo "Installing hooks..."
cp "$VIBE_SKILLS_DIR/hooks/"*.sh "$INSTALL_DIR/hooks/"
chmod +x "$INSTALL_DIR/hooks/"*.sh
echo -e "  ${GREEN}✓${NC} Hooks installed to $INSTALL_DIR/hooks/"

# ── 3. Copy skills ─────────────────────────────────────────────────────────────
echo "Installing skills..."
cp -r "$VIBE_SKILLS_DIR/skills/"* "$INSTALL_DIR/skills/"
echo -e "  ${GREEN}✓${NC} Skills installed to $INSTALL_DIR/skills/"

# ── 4. Register skills with Claude Code ───────────────────────────────────────
CLAUDE_SKILLS_DIR="$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"
for skill_dir in "$INSTALL_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$CLAUDE_SKILLS_DIR/$skill_name"
    if [ -L "$target" ]; then rm "$target"; fi
    ln -sf "$skill_dir" "$target"
done
echo -e "  ${GREEN}✓${NC} Skills linked in $CLAUDE_SKILLS_DIR"

# ── 5. Register hooks in settings.json ────────────────────────────────────────
echo "Configuring hooks in Claude Code settings..."

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

python3 - <<PYTHON
import json, sys, os

settings_file = "$SETTINGS_FILE"
install_dir = "$INSTALL_DIR"

with open(settings_file) as f:
    try:
        settings = json.load(f)
    except json.JSONDecodeError:
        settings = {}

if 'hooks' not in settings:
    settings['hooks'] = {}

hooks = settings['hooks']

# SessionStart hook
if 'SessionStart' not in hooks:
    hooks['SessionStart'] = []
session_start_cmd = f"bash {install_dir}/hooks/session-start.sh"
if not any(
    any(h.get('command') == session_start_cmd for h in entry.get('hooks', []))
    for entry in hooks['SessionStart']
):
    hooks['SessionStart'].append({
        "hooks": [{"type": "command", "command": session_start_cmd}]
    })

# PreToolUse hook for Bash
if 'PreToolUse' not in hooks:
    hooks['PreToolUse'] = []
pre_tool_cmd = f"bash {install_dir}/hooks/pre-tool.sh"
if not any(
    entry.get('matcher') == 'Bash' and
    any(h.get('command') == pre_tool_cmd for h in entry.get('hooks', []))
    for entry in hooks['PreToolUse']
):
    hooks['PreToolUse'].append({
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": pre_tool_cmd}]
    })

# Stop hook
if 'Stop' not in hooks:
    hooks['Stop'] = []
stop_cmd = f"bash {install_dir}/hooks/session-stop.sh"
if not any(
    any(h.get('command') == stop_cmd for h in entry.get('hooks', []))
    for entry in hooks['Stop']
):
    hooks['Stop'].append({
        "hooks": [{"type": "command", "command": stop_cmd}]
    })

with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)

print("  hooks merged into settings.json")
PYTHON

echo -e "  ${GREEN}✓${NC} Hooks registered in $SETTINGS_FILE"

# ── 6. Project setup (only if project dir was specified) ──────────────────────
if [ -n "$PROJECT_DIR" ]; then
    echo ""
    echo "Setting up project: $PROJECT_DIR"

    # CLAUDE.md
    CLAUDE_TARGET="$PROJECT_DIR/CLAUDE.md"
    if [ -f "$CLAUDE_TARGET" ]; then
        echo -e "  ${YELLOW}!${NC} CLAUDE.md already exists."
        read -p "  Append vibe-skills behavioral baseline? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "" >> "$CLAUDE_TARGET"
            echo "---" >> "$CLAUDE_TARGET"
            cat "$VIBE_SKILLS_DIR/CLAUDE.md" >> "$CLAUDE_TARGET"
            echo -e "  ${GREEN}✓${NC} Appended to CLAUDE.md"
        fi
    else
        cp "$VIBE_SKILLS_DIR/CLAUDE.md" "$CLAUDE_TARGET"
        echo -e "  ${GREEN}✓${NC} CLAUDE.md written"
    fi

    # .vibe/ directory
    VIBE_TARGET="$PROJECT_DIR/.vibe"
    if [ ! -d "$VIBE_TARGET" ]; then
        cp -r "$VIBE_SKILLS_DIR/templates/.vibe" "$VIBE_TARGET"
        echo -e "  ${GREEN}✓${NC} .vibe/ created — Claude fills this as you work"

        # Ask about gitignore
        echo ""
        echo "  Should .vibe/ be committed to git?"
        echo "  • Commit it: your project memory travels with the code (good for teams or backup)"
        echo "  • Gitignore it: keeps it private and out of your commit history (fine for solo)"
        echo ""
        read -p "  Add .vibe/ to .gitignore? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            GITIGNORE="$PROJECT_DIR/.gitignore"
            if [ -f "$GITIGNORE" ]; then
                if ! grep -q "^\.vibe" "$GITIGNORE" 2>/dev/null; then
                    echo "" >> "$GITIGNORE"
                    echo "# vibe-skills project memory" >> "$GITIGNORE"
                    echo ".vibe/" >> "$GITIGNORE"
                    echo -e "  ${GREEN}✓${NC} Added .vibe/ to .gitignore"
                fi
            else
                echo ".vibe/" > "$GITIGNORE"
                echo -e "  ${GREEN}✓${NC} Created .gitignore with .vibe/"
            fi
        else
            echo "  .vibe/ will be tracked by git — consider committing it for backup"
        fi
    else
        echo -e "  ${YELLOW}!${NC} .vibe/ already exists — skipping"
    fi
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────"
echo -e "  ${GREEN}vibe-skills installed.${NC}"
echo ""
if [ -n "$PROJECT_DIR" ]; then
    echo "  Project ready: $PROJECT_DIR"
    echo ""
fi
echo "  Active everywhere (global hooks):"
echo "  • Destructive command intercept"
echo "  • Deployment environment detection"
echo "  • vibe-safe scan on stop"
echo ""
echo "  Active in this project (add to others with --project):"
echo "  • CLAUDE.md behavioral baseline"
echo "  • .vibe/ project memory"
echo ""
echo "  Skills: /vibe-scope  /vibe-check  /vibe-oops"
echo "          /vibe-launch /vibe-health /vibe-handoff /vibe-explain"
echo ""
if [ -z "$PROJECT_DIR" ]; then
    echo "  To set up a project:"
    echo "  cd /your/project && bash $INSTALL_DIR/../vibe-skills/install.sh --project"
    echo "  (or: bash $VIBE_SKILLS_DIR/install.sh --project /your/project)"
    echo ""
fi
