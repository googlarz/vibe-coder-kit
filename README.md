# vibe-skills

Claude Code skills, hooks, and behavioral contracts for solo vibecoders.

You're building something real with AI assistance. vibe-skills makes that safer: it guards your sessions automatically, keeps project memory across conversations, and gives you structured skills for the moments that matter — before launching, when things break, when you need real help.

**Ship without regret. Undo anything. Know when to escalate.**

---

## Install

**Step 1 — Install globally** (once, anywhere):

```bash
git clone https://github.com/googlarz/vibe-skills ~/.vibe-skills
bash ~/.vibe-skills/install.sh --global
```

This installs the hooks and skills into `~/.claude/`. They fire in every Claude Code session from this point on.

**Step 2 — Set up each project** (once per project, from the project root):

```bash
cd ~/your-project
bash ~/.vibe-skills/install.sh --project
```

This adds `CLAUDE.md` and `.vibe/` to your project. You'll be asked whether to commit or gitignore `.vibe/` — see below.

The installer:
- Registers hooks in `~/.claude/settings.json`
- Links skills so you can invoke them with `/vibe-*`
- Writes `CLAUDE.md` behavioral baseline to your project
- Initializes `.vibe/` project memory (Claude fills this as you work)

---

## What you get

### Automatic — fires without invoking anything

| What | When it fires | What it does |
|---|---|---|
| **Session start** | Every new conversation | Loads your project memory. Asks what you're working on and what NOT to touch. Warns if production environment detected. |
| **Before bash commands** | Before any shell command | Blocks destructive operations (`DROP TABLE`, `rm -rf`, force push) and asks for confirmation. Checks package names for typos before install. |
| **Session stop** | When Claude finishes | Runs vibe-safe scan if installed. Reminds Claude to update `.vibe/` with what changed. |
| **CLAUDE.md behavioral baseline** | Always active | Defines how Claude behaves: environment checks, checkpoint creation, plain-English explanations, the "you need a real developer" signal. |

### On-demand — invoke when you need them

| Skill | What it does |
|---|---|
| `/vibe-scope` | 5-question session setup — defines what we're building today and what we're NOT touching. Creates a save point if you don't have one. |
| `/vibe-check` | Pre-push security scan. Runs vibe-safe if installed, translates every finding into plain English with a clear verdict: safe / fix first / do not push. |
| `/vibe-oops` | Recovery protocol when things break. Diagnoses the error in plain English, then gives exactly three options: fix it, undo it, get help. |
| `/vibe-launch` | Pre-launch checklist — 6 checks before telling real users about your app: secrets, deployment, core flow, monitoring, user contact, rollback. |
| `/vibe-health` | Weekly project health dashboard — debt level, momentum, safety signals, and honest assessment of whether you need a real developer yet. |
| `/vibe-handoff` | Generates a developer handoff document — either an emergency escalation (something broke) or a planned onboarding doc (bringing in a developer). |
| `/vibe-explain` | Plain-English summary of what changed this session — what's new, what to test manually, what might break. Run before closing the tab. |

---

## vibe-brain — project memory

vibe-skills creates a `.vibe/` directory in your project. Claude writes to it automatically.

```
.vibe/
├── project.md      what you're building, your stack, your deployment
├── sessions.md     what changed in each session, what to test manually
├── debt.md         shortcuts taken, fragile things, "ask a dev about this"
└── decisions.md    why you chose X over Y
```

At the start of every session, Claude reads these files silently. It knows your project — the history, the debt, the environment — without you having to re-explain everything.

**Should you commit `.vibe/`?** Your call — the installer asks:

- **Commit it** if you want project memory to travel with the code (good for backup or sharing with a future developer)
- **Gitignore it** if you want it private and out of your commit history (fine for solo work)

Either way works. You can always change your mind later.

---

## vibe-safe integration

[vibe-safe](https://github.com/googlarz/vibe-safe) is a companion security scanner that checks your code for secrets, injection vulnerabilities, and common mistakes.

Install it for the best experience:

```bash
# follow vibe-safe install instructions
```

`/vibe-check` will detect vibe-safe automatically and use it if available. Without it, vibe-check runs a basic inline scan.

---

## Requirements

- [Claude Code](https://claude.ai/code)
- bash
- Python 3 (used by install.sh to update `settings.json`)
- git (recommended — save points won't work without it)

---

## Philosophy

Three rules, in order:

1. **Safety first** — never break what's working; always have a way back
2. **Plain English** — if you can't explain a risk in one sentence, it's not useful
3. **Know your limits** — the best skill vibe-skills teaches is recognizing when to bring in a real developer

vibe-skills doesn't make you a developer. It makes you a safer solo builder.

---

## Related

- [vibe-safe](https://github.com/googlarz/vibe-safe) — security scanner this pack integrates with
- [agent-skills](https://github.com/googlarz/agent-skills) — the equivalent pack for professional engineers
- [context-handoff](https://github.com/googlarz/context-handoff) — continue Claude conversations exactly where you left off
