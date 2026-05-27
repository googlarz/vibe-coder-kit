# vibe-coder-kit

**A knowledgeable friend alongside every session — not a system printing reports.**

---

Claude writes the code. The commit message says "update." You're not sure what changed, whether it's safe to push, or whether you've crossed a line that needs a real developer. The next session starts from scratch — no memory of what was decided, what's fragile, or what you're even building.

vibe-coder-kit fixes this. It installs two things that work together silently:

- **Behavioral layer** (this repo) — hooks that fire automatically, project memory that persists across sessions, and 18 skills covering the full lifecycle from idea to ship. The whole experience is designed to feel like a conversation with someone who knows your project — not a tool running a checklist.
- **Mechanical layer** ([vibe-safe](https://github.com/googlarz/vibe-safe)) — 66 security checks on every commit: credentials, injection vulnerabilities, auth gaps, and more — no Claude required

---

## Install

```bash
# 1. Install vibe-coder-kit:
git clone https://github.com/googlarz/vibe-coder-kit ~/.vibe-coder-kit
bash ~/.vibe-coder-kit/install.sh
```

This downloads the kit and connects it to Claude Code. It won't touch your app — it only changes how Claude behaves during sessions.

To set up a project:

```bash
cd ~/your-project
bash ~/.vibe-coder-kit/install.sh --project
```

This adds a `CLAUDE.md` behavioral baseline and a `.vibe/` project memory directory.

---

## What fires automatically

No invocation needed. These run on every Claude Code session.

| Hook | When | What it does |
|---|---|---|
| **Session start** | Every new conversation | Reads `.vibe/project.md` and `.vibe/sessions.md`. Surfaces recent history. Asks what you're building today and what NOT to touch. Warns if a production environment is detected. |
| **Before bash commands** | Any shell command | Blocks commands that delete databases, wipe files, or overwrite your code history — explains why before stopping. Enforces session scope (areas you said not to touch today). Explains every package before installing it. Requires confirmation before anything that can't be undone. |
| **Session stop** | When Claude finishes | Runs vibe-safe scan. Surfaces findings before the final response. Reminds Claude to update `.vibe/sessions.md`. |
| **CLAUDE.md baseline** | Always active | Environment checks before DB ops. Git checkpoints before big changes. Plain-English risk explanations. The signal to escalate to a real developer. |

---

## Skills — invoke when you need them

**Before you build:**

| Skill | When to run |
|---|---|
| `/vibe-skeptic` | New idea — a conversation that figures out if it's worth building, catches scope creep early, and either gives a green light or designs a concrete experiment to validate first. |
| `/vibe-think` | Idea passes — clarify the scope before writing any code. 5 questions, concrete scope, what you're NOT building, biggest risk. |
| `/vibe-plan` | Scope confirmed — break the work into 3-5 phases, each with a checkpoint command and a user-observable verify step. |

**During a session:**

| Skill | When to run |
|---|---|
| `/vibe-scope` | Start of session — defines what we're working on today and what NOT to touch. Creates a checkpoint. Writes a scope file so the hook can enforce it automatically for the rest of the session. |
| `/vibe-test` | Feature is built — structured verification: happy path, failure paths, edge cases, regression check. |
| `/vibe-guardian` | Anything that touches user data, auth, or external services — reads the actual code and finds the gaps Claude skipped: error handling, auth enforcement, edge cases, data assumptions. |
| `/vibe-oops` | Something broke — diagnoses in plain English, three options: fix it, undo it, escalate. |

**Shipping:**

| Skill | When to run |
|---|---|
| `/vibe-check` | Before pushing — vibe-safe (66 checks) or inline scan, every finding translated to plain English, clear verdict. |
| `/vibe-git` | After /vibe-check passes — branch check, meaningful commit message, uploads to GitHub, optional PR description. |
| `/vibe-launch` | Before going live — six checks: secrets, deployment, core flow, monitoring, contact info, rollback. |
| `/vibe-health` | Project feels messy — debt level, momentum, safety signals, honest "do you need a real developer?" |
| `/vibe-handoff` | Bringing in a developer — emergency escalation doc or planned onboarding doc. |
| `/vibe-explain` | Session wrapping up — plain-English summary of what changed, what to test, what might have broken. |

**Troubleshooting:**

| Skill | When to run |
|---|---|
| `/vibe-stuck` | Stuck in a loop — Claude keeps trying the same thing. Stops the loop, names what's known vs assumed, picks a new path. |
| `/vibe-env` | Something works locally but not deployed — six-point environment audit: secrets, config, .gitignore, hardcoded values. |
| `/vibe-log` | Got an error message you don't understand — translates it to plain English, finds the cause, proposes one fix. |
| `/vibe-rollback` | Something broke in production — detects your deployment platform and gives you the exact steps to roll back right now. |
| `/vibe-upgrade` | Upgrading a dependency — one package at a time, checkpoint before each, write to debt.md on failure. |

---

## How it feels

Every skill in this pack is designed to feel like a conversation — not a system running a process. Claude talks while it works, shares one thing at a time, and always ends with a clear next step.

A few examples of how this shows up in practice:

**`/vibe-scope`** asks five questions one at a time, waits for each answer, then reflects the plan back in plain speech: "Okay, here's what I've got: we're doing X, leaving Y alone, and we're done when Z. Sound right?"

**`/vibe-test`** doesn't output a report. It walks you through testing the main thing first — "can you try this now?" — then shares what it found and ends with one verdict: safe to push, fix this first, or don't push yet.

**`/vibe-explain`** wraps up a session in exactly three sentences: what was built, what to try before you close the tab, and one thing to keep an eye on (or "nothing flagged"). No headers, no lists.

**`/vibe-skeptic`** thinks out loud with you. If the idea needs validation first, it writes a concrete experiment: hypothesis, what to do today, what "yes, build it" looks like, and a timeframe in days not weeks.

**`/vibe-guardian`** reads the actual code before saying anything — runs `git diff`, opens changed files, checks `.vibe/bugs.md` for patterns. Findings are tied to specific functions and lines. Critical ones come with actual code fixes, not descriptions of fixes.

---

## vibe-brain — project memory

Every project gets a `.vibe/` directory. Claude writes to it automatically during each session.

```
.vibe/
├── project.md      what you're building, your stack, your deployment
├── sessions.md     what changed in each session, what to test manually
├── decisions.md    why you chose X over Y
├── debt.md         shortcuts taken, fragile things, "ask a dev about this"
├── bugs.md         bug root causes — so the same thing isn't debugged twice
├── gotchas.md      unexpected library/service behaviors — each one cost time to find
└── conventions.md  naming rules and patterns that should stay consistent
```

At the start of every session, Claude reads these files silently. No re-explaining the project. No rebuilding context. The history, the debt, the bugs, the conventions — already there.

`/vibe-scope` also writes a `.vibe/.scope` file — a machine-readable contract that tells the pre-tool hook which areas are off-limits today. If a command touches something you said not to touch, it gets blocked before it runs.

**Should you commit `.vibe/`?** The installer asks. Commit it if you want project memory to travel with the code (good for teams or backup). Gitignore it if you want it private. Either works.

---

## vibe-safe — the security layer

vibe-coder-kit pairs with [vibe-safe](https://github.com/googlarz/vibe-safe): a shell script that runs 66 security checks on every commit without Claude. It catches what behavioral contracts can't — the credential that slipped into the wrong file, the SQL query built from user input, the JWT that never expires.

The two layers are designed to complement each other:

| vibe-coder-kit (behavioral) | vibe-safe (mechanical) |
|---|---|
| Claude interprets context | Shell script — no LLM |
| Guards intentions and scope | Checks actual code and git state |
| Runs during conversation | Runs on every commit |
| Explains in plain English | Cites exact file:line |

When vibe-safe is installed:

- `/vibe-check` runs it and translates every `vibe-safe:` finding into plain English with a concrete fix
- The session stop hook surfaces findings before Claude writes its final response
- Pre-commit: git commit is blocked until STOP-level findings are resolved

vibe-safe is installed as part of the `install.sh` flow. To install it separately:

```bash
git clone https://github.com/googlarz/vibe-safe ~/.claude/skills/vibe-safe
```

---

## Verify your install

After installing, run this to confirm everything is wired up:

```bash
bash ~/.claude/vibe-coder-kit/verify.sh
bash ~/.claude/vibe-coder-kit/verify.sh --project   # also check the current project
```

This checks that all three hooks are installed, registered in Claude Code settings, and (with `--project`) that CLAUDE.md and all seven `.vibe/` template files are present.

---

## Requirements

- [Claude Code](https://claude.ai/code) (CLI or desktop app)
- bash
- Python 3 (already installed on most Macs; the installer will tell you if it's missing)
- git (recommended — checkpoints and vibe-safe don't work without it)

---

## Philosophy

Three failure modes end vibe-coded projects:

1. **You don't know what changed** — vibe-brain and `/vibe-explain` fix this
2. **Mistakes ship before you catch them** — vibe-safe and `/vibe-check` fix this
3. **You don't know when to stop** — `/vibe-health` and `/vibe-handoff` fix this

vibe-coder-kit doesn't make you a developer. It makes solo AI-assisted development sustainable.

---

## Related

- [vibe-safe](https://github.com/googlarz/vibe-safe) — the security layer this pack pairs with
- [agent-skills](https://github.com/googlarz/agent-skills) — equivalent pack for professional engineers
