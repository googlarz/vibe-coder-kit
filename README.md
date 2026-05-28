# vibe-coder-kit

Persistent memory, automatic guardrails, and 27 skills — from first idea to shipped, and everything that breaks in between.

---

Claude can build. What it can't do — on its own — is remember what it decided last session, know which parts of your app are fragile, or stop before it overwrites something that can't be undone. vibe-coder-kit fills those gaps.

It works in three ways:

- **Remembers** — `.vibe/` persists project context between sessions. Claude starts every conversation knowing what's fragile, what was decided, what not to touch.
- **Protects** — Hooks fire silently on every session: dangerous commands blocked before they run, packages explained before install, scope enforced so Claude doesn't wander into code you said to leave alone. [vibe-safe](https://github.com/googlarz/vibe-safe) runs 66 security checks on every commit without Claude.
- **Guides** — 27 skills covering the full lifecycle: validating an idea before writing a line of code, keeping a session focused while building, and recovering a broken production deploy when things go wrong.

---

## Claude alone — Claude with vibe-coder-kit

| Situation | Without | With |
|---|---|---|
| Starting a new session | Re-explain the project every time | Claude reads `.vibe/` — already knows the stack, what's fragile, and what changed last session |
| New feature idea | Claude starts coding | `/vibe-skeptic` asks if it's worth building. `/vibe-think` locks down scope before a line is written. |
| Planning | Flat task list for the next hour | `/vibe-plan`: 3–5 phases, each with a checkpoint and a step you can actually click to verify |
| Running `rm -rf` or `DROP TABLE` | Executes immediately | Blocked. Claude names exactly what gets destroyed and asks to confirm. |
| `npm install some-package` | Installs silently | Claude explains what the package does, confirms the name, and flags if it's obscure |
| Feature is built | Ships with the gaps Claude skipped | `/vibe-guardian` reads the actual code — finds missing auth checks, unhandled errors, edge cases |
| Something breaks | Claude tries fix after fix until you stop it | `/vibe-oops`: three options — fix it, undo it, escalate. Stops after 3 attempts to reassess. |
| A bug took 2 hours to find | Same bug is possible next session | Root cause written to `.vibe/bugs.md` — next time, Claude already knows why it happened |

---

## Install

```bash
git clone https://github.com/googlarz/vibe-coder-kit ~/.vibe-coder-kit
bash ~/.vibe-coder-kit/install.sh
```

This connects the kit to Claude Code. It doesn't touch your app — it only changes how Claude behaves during sessions.

To set up a project:

```bash
cd path/to/your-project
bash ~/.vibe-coder-kit/install.sh --project
```

This creates a `CLAUDE.md` behavioral baseline and a `.vibe/` memory directory for the project.

---

## Memory — the .vibe/ brain

Every project gets a `.vibe/` directory. Claude writes to it during sessions and reads from it at the start of each new one.

```
.vibe/
├── project.md      what you're building, your stack, deployment platform
├── sessions.md     what changed each session, what to test manually
├── decisions.md    why you chose X over Y — so it doesn't get re-litigated
├── debt.md         shortcuts taken, fragile things, "ask a developer about this"
├── bugs.md         root causes of past bugs — same thing doesn't get debugged twice
├── gotchas.md      unexpected library/service behaviors that cost time to find
└── conventions.md  naming and structural rules that should stay consistent
```

No re-explaining the project at the start of every session. No rebuilding context. The history, the debt, the bugs — already there.

**Should you commit `.vibe/`?** The installer asks. Commit it to travel with the code (useful for teams or backup). Add it to `.gitignore` to keep it private. Either works.

---

## What fires automatically

No invocation needed. These run on every session.

| Hook | When | What it does |
|---|---|---|
| **Session start** | Every new conversation | Reads `.vibe/project.md` and `.vibe/sessions.md`. Surfaces recent history. Asks what you're working on today and what NOT to touch. Warns if a production environment is detected. |
| **Before bash commands** | Any shell command | Blocks database wipes, file deletions, and git history rewrites — explains why before stopping. Enforces scope (areas you said not to touch today). Explains every package before installing it. Requires confirmation before anything that can't be undone. |
| **Session stop** | When Claude finishes | Runs vibe-safe scan if installed. Surfaces findings before the final response. Reminds Claude to write to `.vibe/sessions.md`. |

---

## Skills

Claude suggests these at the right moment — you don't need to memorize the list. CLAUDE.md watches the conversation and will say "this looks like a `/vibe-guardian` situation" before you'd think to ask. You can also invoke any skill directly by name whenever you want.

### Before you build

Starting without thinking it through is how scope explodes and time disappears.

| Skill | When to run | What you get |
|---|---|---|
| `/vibe-skeptic` | New idea, before writing any code | An honest conversation about whether it's worth building. Green light, or a concrete experiment to validate first. |
| `/vibe-think` | Idea passes the skeptic test | Five questions, concrete scope, explicit "not building" list, biggest risk named. |
| `/vibe-plan` | Scope is confirmed | 3–5 phases, each with a checkpoint and a user-observable verify step. |

### While building

Keep the session focused and catch gaps before they ship.

| Skill | When to run | What you get |
|---|---|---|
| `/vibe-scope` | Start of any session | What we're touching today and what NOT to touch. Checkpoint created. Scope written so the hook enforces it automatically. |
| `/vibe-test` | Feature is built | Happy path, failure paths, edge cases, regression check. One verdict at the end. |
| `/vibe-guardian` | Anything touching user data, auth, or external services | Reads the actual code, finds the gaps Claude skipped: error handling, auth enforcement, edge cases, data assumptions. Critical findings come with fixes. |
| `/vibe-auth` | Auth system needs a security audit | Seven checks: login inputs, session expiry, protected routes, authorization (user A can't see user B's data), password reset, password storage, logout. |

### When things go wrong

Something broke, something was exposed, or something's about to go dangerously wrong.

| Skill | When to run | What you get |
|---|---|---|
| `/vibe-oops` | Something is broken right now | Diagnosis in plain English. Three options: fix it, undo it, escalate. No more than 3 fix attempts before stopping to reassess. |
| `/vibe-debug` | Bug exists but the cause isn't obvious | Reproduce first, narrow where it lives, form a hypothesis, fix the root cause — not the symptom. |
| `/vibe-stuck` | Tried the same thing twice and it still doesn't work | Stops the loop. Names what's known vs. assumed. Picks a different path. |
| `/vibe-env` | Works locally but not in production | Six-point audit: secrets, config, `.gitignore`, hardcoded values, platform-specific behavior. |
| `/vibe-log` | Got an error message you don't understand | Translates it to plain English. Finds the cause. Proposes one fix. |
| `/vibe-rollback` | Something broke in production and needs fixing now | Detects your deployment platform and gives the exact rollback steps. |
| `/vibe-secret` | An API key, password, or token may have been exposed | Rotate first, then scrub git history, then audit what was at risk. In that order. |
| `/vibe-db` | Database migration, data inspection, or schema change | Verifies which environment you're in. Reads before writing. Backs up before anything destructive. |

### Shipping and upkeep

Getting to production, keeping it healthy, managing the project over time.

| Skill | When to run | What you get |
|---|---|---|
| `/vibe-check` | Before pushing | Runs vibe-safe (66 checks) if installed, or a built-in scan otherwise. Every finding in plain English with a concrete fix. Clear verdict: safe to push or not. |
| `/vibe-git` | After /vibe-check passes | Branch check, meaningful commit message, uploaded to GitHub, optional PR description. |
| `/vibe-launch` | Before going live | Six checks: secrets, deployment, core flow, monitoring, contact info, rollback plan. |
| `/vibe-monitor` | App is live but there's no way to know when it breaks | Sets up Sentry (errors) and UptimeRobot (uptime). You find out before your users do. |
| `/vibe-health` | Sessions feel messy or the same things keep breaking | Debt level, momentum, safety signals, honest "do you need a real developer?" assessment. |
| `/vibe-handoff` | Bringing in a developer | Escalation document with everything they need to understand the project and take over. |
| `/vibe-onboard` | Someone new is joining | First-hour guide: setup steps, what's fragile, what not to touch. |
| `/vibe-docs` | README is missing or out of date | Writes the public README from actual project files — nothing invented. |
| `/vibe-explain` | Session is wrapping up | What was built, what to test before closing the tab, one thing to watch. Three sentences. |
| `/vibe-perf` | Something feels slow | Measures the actual bottleneck. Fixes the biggest one. Verifies improvement with numbers. |
| `/vibe-upgrade` | Upgrading a dependency | One package at a time. Checkpoint before each. Failed upgrades written to `debt.md`. |
| `/vibe-clean` | Project is stable and you want to reduce known risk | Picks one documented debt item, fixes it properly, writes a test to keep it fixed. |

---

## The security layer

vibe-coder-kit pairs with [vibe-safe](https://github.com/googlarz/vibe-safe): a shell script that runs 66 security checks on every commit without Claude. It catches what behavioral contracts can't — the credential that slipped into the wrong file, the SQL query built from user input, the JWT that never expires.

| vibe-coder-kit | vibe-safe |
|---|---|
| Claude interprets context | Shell script — no LLM |
| Guards scope and intentions | Checks actual code and git state |
| Runs during conversation | Runs on every commit |
| Explains in plain English | Cites exact file:line |

When vibe-safe is installed, `/vibe-check` runs it and translates every finding to plain English. The session stop hook surfaces findings before Claude writes its final response. Git commit is blocked until STOP-level findings are resolved.

vibe-safe installs as part of `install.sh`. To install separately:

```bash
git clone https://github.com/googlarz/vibe-safe ~/.claude/skills/vibe-safe
```

---

## Verify your install

```bash
bash ~/.claude/vibe-coder-kit/verify.sh
bash ~/.claude/vibe-coder-kit/verify.sh --project   # also check the current project
```

Confirms all hooks are installed and registered in Claude Code settings. With `--project`, also verifies `CLAUDE.md` and all seven `.vibe/` template files are in place.

---

## Requirements

- [Claude Code](https://claude.ai/code)
- bash
- Python 3 (the installer will tell you if it's missing)
- git (checkpoints and vibe-safe don't work without it)
