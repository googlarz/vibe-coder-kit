---
name: vibe-scope
description: Define session scope before coding — what we're doing, what we're NOT touching, and confirm a checkpoint exists.
---

## Overview

`vibe-scope` is a pre-session ritual for vibecoders. Before any code changes, run this to lock in what today's session covers — and what it doesn't. This prevents the most common vibecoder failure: asking Claude to "fix one thing" and ending up with half your app rewritten two hours later.

Run this at the start of every work session. It takes two minutes and saves hours.

**Emergency exception:** If the user invoked `/vibe-scope` but their message also describes something broken or urgent — an error, a crash, something not working for real users — acknowledge it and go to `/vibe-oops` instead. Scope-setting is for fresh starts, not for someone whose production is down.

---

## Process

Ask the user these 5 questions in order. One at a time. Wait for each answer before moving on. Do not skip questions. Do not add more questions.

### Question 1 — What are we doing today?

> "What are we building or fixing today? One sentence."

If the answer is vague (e.g., "make it better", "fix some stuff", "the app"), don't move on. See **When scope is vague** below.

### Question 2 — What are we NOT touching today?

> "What parts of the app should stay exactly as they are? (Payments, login, the homepage, the database — anything you don't want changed today.)"

If they say "nothing" or "I don't know", prompt them:
> "Think about the parts that are already working. Let's leave those alone."

Write down their answer even if it's short. "Leave the checkout flow alone" is a valid scope boundary.

### Question 3 — Live or test version?

> "Are we working on the live version (what real users see right now) or a test/preview version?"

If live + the work today is risky (involves payments, login, database changes, anything user-facing), add a warning to the session contract: **⚠️ Working on live — be careful and move in small steps.**

### Question 4 — Do we have a checkpoint?

> "When did you last save your work? (In coding terms: do you have a recent commit — basically a checkpoint of your app before we start?)"

First, check if git is initialized:
```bash
git status 2>&1
```

**If git is not initialized** (command errors with "not a git repository"):
> "Git — your version control system — isn't set up in this project. That means there's no way to go back if something breaks today. I'd strongly recommend setting it up before we start. Want me to do that? It takes 30 seconds."

If yes:
```bash
git init && git add -A && git commit -m "initial checkpoint $(date +'%Y-%m-%d')"
```

If they say no, note "No git — no save point available" in the contract and add a warning: **⚠️ No undo available if things break.**

**If git is initialized:**
- Check `git log --oneline -1 2>/dev/null` to see if any commits exist
- If yes: note the most recent commit and move on
- If no commits yet, or if the last commit was more than a few days ago: offer to create a checkpoint now
  > "Before we change anything, let's create a checkpoint so we can go back if something breaks. Takes 10 seconds."
  
  If yes, run: `git add -A && git commit -m "checkpoint $(date +'%Y-%m-%d')"` and confirm it worked.
  
  If they decline but the project is live (has real users): don't just note it and move on. Offer a safer middle ground:
  > "At least let me save just the files we're already tracking — takes 5 seconds and won't touch anything sensitive."
  Run: `git add --update && git commit -m "checkpoint $(date +'%Y-%m-%d')"`
  `--update` only stages files git already knows about — it cannot accidentally commit a `.env` file that hasn't been tracked before. This is always safe to run.

  If they decline entirely: note "No checkpoint — user declined" in the contract and add a warning: **⚠️ No undo available if things break.**

### Question 5 — What does "done" look like?

> "How will you know we succeeded today? What should work that doesn't work now?"

This is the success criteria. It should be something observable — "the button should turn green", "I can log in with Google", "the form sends an email". Not "it should feel better."

If they can't describe what done looks like, push back:
> "Let's figure that out before we start — otherwise we won't know when to stop."

---

## When scope is vague

If the answer to Question 1 is fuzzy, stop and ask a follow-up before continuing:

> "Can you show me exactly where in the app? Or tell me what's broken or missing?"

Common vague answers and how to handle them:

| They say | Ask |
|---|---|
| "Make it better" | "Better how? What frustrates you about it right now?" |
| "Fix some stuff" | "What's broken? What happens when you try to use it?" |
| "Improve the design" | "Which screen? What specifically looks wrong?" |
| "Add features" | "Which feature, and what should it do?" |

Do not proceed until you have a specific, one-sentence scope. If after two clarifying questions you still can't pin it down, say:
> "Let's take a step back. What's the one thing you want to be able to do after today that you can't do right now?"

---

## What to write to `.vibe/sessions.md`

After collecting all 5 answers, create `.vibe/sessions.md` if it doesn't exist (create the `.vibe/` directory too). **Prepend** (add to the top of the file, not the bottom) — the session-start hook reads the first entry to detect "session already started today."

Also write `.vibe/.scope` (machine-readable scope for the pre-tool.sh hook — this enables automatic scope enforcement):

```
NOT_TOUCHING=<comma-separated list from Question 2, e.g. "payments,login,homepage">
SCOPE=<one-line from Question 1>
DATE=<today's actual date as YYYY-MM-DD — write the literal date, e.g. 2026-05-27>
```

If Question 2 was "nothing" or vague, write an empty `NOT_TOUCHING=`. This file is read by the pre-tool hook on every bash command — if the command string matches anything in NOT_TOUCHING, it gets flagged before executing.

Write this block to sessions.md:

```
## [YYYY-MM-DD] — [one-sentence scope: what we're doing today]

TODAY WE ARE:
[Answer from Question 1 — specific and concrete]

WE ARE NOT TOUCHING:
[Answer from Question 2 — list of off-limits areas]

VERSION:
[Live / Test] [add ⚠️ WARNING: Live + risky work if applicable]

CHECKPOINT:
[Yes — committed at [time/date] / No — user declined / Created now at [time]]

DONE WHEN:
[Answer from Question 5 — observable success criteria]

---
```

Then confirm it with the user conversationally — don't show them the raw file, just reflect it back:
> "Okay, here's what I've got: we're [scope], leaving [off-limits] alone, and we'll know we're done when [success criteria]. Sound right?"

If they want to change anything, update the file.

---

## Internal instructions for Claude (not for the user)

During the session, refer back to this contract. Before making any change:

1. Check: is this change inside the scope we agreed to?
2. Check: does this touch anything in the "NOT touching" list?
3. If either answer is no — stop and say so.

When stopping, say it plainly:
> "This would touch [the login system / the database / the homepage] which we agreed to leave alone today. Want to add this to a future session instead?"

Do not proceed outside scope unless the user explicitly says to update the contract. If they want to expand scope mid-session, update `.vibe/sessions.md` with a note: `SCOPE CHANGE at [time]: [what changed]`.

---

## Verification checklist

Before ending the skill run, confirm:

- [ ] All 5 questions answered
- [ ] Scope is specific (not vague)
- [ ] Save point confirmed or created
- [ ] `.vibe/sessions.md` written and shown to user
- [ ] User confirmed the contract looks right
- [ ] If live + risky: warning is visible in the contract
