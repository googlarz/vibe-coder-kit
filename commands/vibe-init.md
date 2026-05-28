---
description: Set up the current project for vibe-coder-kit — writes the behavioral baseline (CLAUDE.md) and creates the .vibe/ memory directory.
---

Set up the current working directory as a vibe-coder-kit project. This is a one-time setup per project.

The kit's source files live at `${CLAUDE_PLUGIN_ROOT}` (the installed plugin directory). If that variable isn't resolved, locate the plugin by searching `~/.claude/plugins/cache` for a `vibe-coder-kit` directory containing `CLAUDE.md` and `templates/.vibe/`.

Do the following, talking to the user like a friend — one step at a time, not a wall of output:

1. **Behavioral baseline (`CLAUDE.md`)**
   - If the project has no `CLAUDE.md`: copy `${CLAUDE_PLUGIN_ROOT}/CLAUDE.md` to `./CLAUDE.md`.
   - If a `CLAUDE.md` already exists: do NOT overwrite it. Ask whether to append the vibe-coder-kit baseline under a `---` separator, and only append if they say yes.

2. **Project memory (`.vibe/`)**
   - If `./.vibe/` does not exist: copy the templates from `${CLAUDE_PLUGIN_ROOT}/templates/.vibe/` to `./.vibe/`.
   - If it already exists: leave it alone and say so.

3. **Commit decision for `.vibe/`** — ask once:
   > "Should `.vibe/` be committed to git? Commit it so your project memory travels with the code (good for teams or backup), or gitignore it to keep it private. Either works."
   - If they choose gitignore: add `.vibe/` to `.gitignore` (create it if missing), but only if not already present.

4. **Confirm and orient.** Tell them what was created and that from the next session on, Claude will read `.vibe/` automatically and follow the baseline. Then ask the one question that starts real work:
   > "What are we building?"

Do not run the global installer or touch `~/.claude/settings.json` — hooks and skills are already active from the plugin. This command only sets up the project files.
