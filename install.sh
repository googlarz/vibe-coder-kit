#!/bin/bash
# vibe-skills installer
# Installs behavioral baseline, hooks, and skills for solo vibecoders

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
# Skills need to be in ~/.claude/skills/ for Claude Code to discover them
CLAUDE_SKILLS_DIR="$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"
for skill_dir in "$INSTALL_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$CLAUDE_SKILLS_DIR/$skill_name"
    if [ -L "$target" ]; then
        rm "$target"
    fi
    ln -sf "$skill_dir" "$target"
done
echo -e "  ${GREEN}✓${NC} Skills linked in $CLAUDE_SKILLS_DIR"

# ── 5. Register hooks in settings.json ────────────────────────────────────────
echo "Configuring hooks in Claude Code settings..."

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# Use Python to merge hooks into settings.json
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

# ── 6. Copy CLAUDE.md (offer to append to existing) ───────────────────────────
echo ""
echo "CLAUDE.md behavioral baseline:"

if [ -f "CLAUDE.md" ]; then
    echo -e "  ${YELLOW}!${NC} CLAUDE.md already exists in this directory."
    echo "     The vibe-skills baseline is at: $VIBE_SKILLS_DIR/CLAUDE.md"
    echo "     Add it to your project CLAUDE.md to enable behavioral contracts."
    echo ""
    read -p "  Append vibe-skills behavioral baseline to your CLAUDE.md? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "" >> CLAUDE.md
        echo "---" >> CLAUDE.md
        cat "$VIBE_SKILLS_DIR/CLAUDE.md" >> CLAUDE.md
        echo -e "  ${GREEN}✓${NC} Appended to CLAUDE.md"
    else
        echo "  Skipped. Copy manually from: $VIBE_SKILLS_DIR/CLAUDE.md"
    fi
else
    cp "$VIBE_SKILLS_DIR/CLAUDE.md" "CLAUDE.md"
    echo -e "  ${GREEN}✓${NC} CLAUDE.md written to current directory"
fi

# ── 7. Initialize .vibe/ in current project ────────────────────────────────────
echo ""
if [ ! -d ".vibe" ]; then
    read -p "Initialize vibe-brain (.vibe/) in current directory? [Y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cp -r "$VIBE_SKILLS_DIR/templates/.vibe" ".vibe"
        echo -e "  ${GREEN}✓${NC} .vibe/ created — Claude will fill it in as you work"
        # Add .vibe to .gitignore (contains project state, not secrets, but should be per-project)
        if [ -f ".gitignore" ]; then
            if ! grep -q "^\.vibe/$" .gitignore 2>/dev/null; then
                echo "" >> .gitignore
                echo "# vibe-skills project memory" >> .gitignore
                echo ".vibe/" >> .gitignore
                echo -e "  ${GREEN}✓${NC} Added .vibe/ to .gitignore"
            fi
        fi
    fi
else
    echo -e "  ${YELLOW}!${NC} .vibe/ already exists — skipping"
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────"
echo -e "  ${GREEN}vibe-skills installed.${NC}"
echo ""
echo "  What's active:"
echo "  • CLAUDE.md — behavioral baseline (edit to customize)"
echo "  • Hooks — auto-fire on session start, before bash, on stop"
echo "  • Skills — invoke with /vibe-scope, /vibe-check, /vibe-oops,"
echo "             /vibe-launch, /vibe-health, /vibe-handoff"
echo "  • .vibe/ — project memory (Claude fills this as you work)"
echo ""
echo "  Start your next Claude Code session in this project."
echo "  vibe-scope will run automatically."
echo ""
