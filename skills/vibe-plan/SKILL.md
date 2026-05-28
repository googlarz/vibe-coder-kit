---
name: vibe-plan
description: Turn a confirmed scope into a concrete build plan — 3-5 phases, each with a checkpoint command and a verification step. Run after /vibe-think.
---

# vibe-plan

Turns a confirmed scope into a build plan with explicit checkpoints. Without this, sessions sprawl — you build for hours with no checkpoints, and if something breaks at the end, there's nothing to go back to.

## When to use

- After `/vibe-think` confirms what you're building
- When you know what you want to build but want a clear plan before starting
- Before any feature that touches more than 2 files

Don't use for tiny changes (single file, obvious fix). Use for anything that spans multiple files or takes more than 30 minutes.

---

## Process

### Step 1 — Read the context

**First-run note:** If `.vibe/project.md` doesn't exist yet, skip this step and ask the user directly: "What are we building, and what parts should the plan leave alone?" This is their first session — there's no prior context to read.

Read silently:
- `.vibe/sessions.md` — today's scope (from /vibe-think or already set)
- `.vibe/project.md` — tech stack and how the project is structured
- `.vibe/decisions.md` — architectural decisions already made
- `.vibe/bugs.md` — known bugs in this area (avoid repeating past mistakes)
- `.vibe/gotchas.md` — known library/service surprises that might affect this build. If gotchas.md mentions anything relevant to this feature area — especially library quirks, env setup surprises, or known failure patterns — name them in the plan as things to watch for. Don't just silently read and continue.
- `.vibe/conventions.md` — naming and structural rules to follow

If `.vibe/sessions.md` has no scope for today, ask:
> "What are we building? (If you've already run /vibe-think, I'll pick it up — otherwise give me a one-sentence description.)"

### Step 2 — Check git

```bash
git status 2>/dev/null
git branch --show-current 2>/dev/null
```

If git isn't set up: say so. Offer to initialize it. Checkpoints won't work without git.

If on `main` or `master`: name it. Recommend creating a feature branch before starting:
```bash
git checkout -b feature/[3-word-description]
```

If there are uncommitted changes: note them. Offer a checkpoint before we start — do this once, here, before any code changes. Before running `git add -A`, confirm `.env` is in `.gitignore` — `git add -A` stages everything including files git has never tracked. Run `git status` first and scan for anything sensitive in the 'Untracked files' list.
```bash
git add -A && git restore --staged .env 2>/dev/null && git commit -m "checkpoint before [scope summary]"
```

### Step 3 — Build and present the plan

**How checkpoints work:** after each phase, the user will say "save checkpoint" and you'll commit that phase's work before starting the next. Make this explicit in the plan — each phase ends with "Tell me when you're done and I'll save a checkpoint."

Break the work into **3-5 phases**. No more. If it genuinely needs more than 5 phases, the scope is too big — say so and suggest splitting.

Introduce the plan conversationally before laying it out:
> "Here's how I'm thinking we tackle this. Tell me if anything doesn't feel right — we can adjust before we start."

Then present each phase using this template:

```
## Phase [N] — [Short phase name]

**Goal:** [What the app can do after this phase that it can't now — one sentence]

**Steps:**
1. [Concrete task]
2. [Concrete task]
3. [Concrete task]

**Verify:** [What to try to confirm it worked — one user action]
**Checkpoint:** When you're ready, say "save checkpoint" and I'll commit this phase.
```

**Note:** When the user says "save checkpoint", run the same checkpoint command as Step 2 (with the phase name as the commit message).

Note: `.vibe/` will appear in `git status` as new files — this is expected and fine to include in the checkpoint commit. If you'd prefer to keep vibe-brain out of git, add `.vibe/` to `.gitignore` first.

---

### Step 4 — Name the tricky part

After the phases, say which one you're most uncertain about — in plain language:
> "The part I'd watch most carefully is Phase [N] — [why in one sentence]. If something goes wrong there, it'll probably show up as [hint]."

### Step 5 — Ask one question

Before saving, ask the one question that would most change this plan:

> "[Question about the riskiest assumption you made.]"

Example: "I assumed you're using Supabase for auth — is that right? It changes how we handle email verification."

If they confirm or clarify, adjust the plan accordingly.

### Step 6 — Save and start

Once confirmed:

1. Append the plan to `.vibe/sessions.md` under today's entry:
```
**Plan:**
[paste the phases]
**Highest risk:** [paste]
```

2. Offer to start:
> "Plan saved. Want me to start with Phase 1?"

If yes: begin. Create a **per-phase checkpoint** before the first change — this is distinct from the initial checkpoint in Step 2, which captures uncommitted work. This one marks the clean start of Phase 1 so each phase has its own recovery point. Confirm `.env` is in `.gitignore` before staging.
```bash
git add -A
git restore --staged .env 2>/dev/null  # safety: never commit .env
git commit -m "checkpoint: start of phase 1 — [scope]"
```

Then announce: "Saved your starting point. If anything goes wrong, I can get you back to here."

---

## Language rules

- Phase names should describe what the user gets, not what the code does.
  - ✅ "Phase 1: The settings page exists and loads"
  - ❌ "Phase 1: Route handler and component scaffold"
- Verification steps must be user actions or visible outcomes, not code inspection.
- "Highest risk" must name a user impact, not a technical challenge.

## Verification checklist

After running vibe-plan:

- [ ] 3-5 phases — no more
- [ ] Each phase has a checkpoint command and a verify step
- [ ] Verify steps are user-observable, not "code looks right"
- [ ] Highest-risk phase is named with a hint for what to do if it fails
- [ ] Git is set up — or user knows it isn't and consequences are named
- [ ] Plan is saved to `.vibe/sessions.md`
- [ ] User knows the exit path: run `/vibe-check` then `/vibe-git` after the final phase
- [ ] `.vibe/` knowledge files were checked for related prior bugs/gotchas
