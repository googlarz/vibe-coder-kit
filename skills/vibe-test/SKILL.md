---
name: vibe-test
description: Structured verification before pushing — walks through the happy path, the failure paths, and edge cases. Surfaces what's untested and what's most likely to break for real users.
---

# vibe-test

Structured verification before you push. Most vibe-coded bugs aren't in the happy path — they're in what happens when things go wrong. This skill walks through both.

## When to use

- After finishing a feature or fix, before running /vibe-check
- When you're not sure whether something "actually works"
- When Claude says "this should work" and you want to verify it does

---

## Process

### Step 1 — Identify what changed

Run:
```bash
# First command shows uncommitted changes; second shows what the last commit changed.
git status --short 2>/dev/null
git diff --name-only HEAD~1 HEAD 2>/dev/null
```

If the project has only one commit (new project), `git diff HEAD~1 HEAD` will fail because there's no previous commit to compare against. In that case, use `git status --short` instead to see what files exist.

List the files changed this session. For each file, identify what user-facing behavior it affects. Map code changes to user actions — not "modified auth.js" but "users logging in."

### Step 2 — Happy path test

**For backend-only changes (no UI to click):** ask the user to trigger the changed endpoint from their app or a test tool (curl, Postman, their test suite) instead of clicking through a UI flow.

Tell the user what to try — conversationally, not as a numbered list. Say something like:

> "Let me walk you through a quick test. First — [specific action]. What happens?"

Wait for them to try it and report back before moving on. If they can't test right now, say so clearly:

> "This is the most important step — trying it for real. Can you open the app now?"

If they genuinely can't test (it's broken, they're on mobile, etc.), note it as untested and flag it in the verdict.

If the happy path failed: don't continue to failure scenarios yet. Treat this as a bug — run `/vibe-oops` to diagnose and fix it first, then come back to finish testing.

### Step 3 — Failure path tests

For every user action in the happy path, ask: what happens if it goes wrong?

Check these failure scenarios for anything that applies to what was built:

| Scenario | What to test |
|---|---|
| **Empty input** | Submit a form with no data — what does the user see? |
| **Invalid input** | Wrong format, too long, special characters — does it break or explain? |
| **Already exists** | Create something that already exists — error or silent failure? |
| **Not logged in** | Access a protected page without being logged in — redirected or broken? |
| **Network offline** | No internet during a save — does data get lost? |
| **Slow connection** | Does something submit twice if the button is clicked twice? |
| **Missing data** | What if a field that should exist doesn't — crash or graceful message? |
| **Wrong device/viewport** | Layout or actions break on mobile. |

For each that applies, write the test step and the expected outcome. Flag any where the expected outcome is "I'm not sure" — those are the ones most likely to break.

### Step 4 — Nearby features check

Sometimes fixing one thing accidentally breaks something nearby. Check what was working before this session that could have broken.

First, check `.vibe/bugs.md` if it exists. Any previously fixed bugs in the area being tested are the highest-risk regressions — Claude often re-introduces the same class of bug when modifying nearby code. Name each one explicitly: "We fixed [X] on [date] — worth confirming it still holds."

Use the changed files identified in Step 1 to determine what to check for regressions. List adjacent features and ask the user to spot-check them — one action each. This doesn't need to be exhaustive, just the most likely collateral damage.

Before moving to the verdict, confirm that anything working before this session still works. Pick the one adjacent feature most likely to have been disturbed and ask the user to check it.

### Step 5 — Verdict

Write exactly three sentences. No report blocks. No "VERDICT:" labels.

**Sentence 1 — What worked:** The happy path result plus any failure scenario that passed.
> "[Happy path] worked. [Failure scenario] handled correctly too." — or — "[Happy path] worked. I couldn't test [scenario] — worth checking manually."

**Sentence 2 — What to check:** One specific thing to verify before pushing, or confirm everything passed.
> "Check [specific thing] before you push." — or — "Everything passed — nothing to flag."

**Sentence 3 — Next step:** One of three verdicts, no hedging.
> "Run /vibe-check and then /vibe-git when you're ready." — or — "Fix [specific thing] first, then come back." — or — "Don't push yet — [what's broken] needs a fix first. Want me to handle it?"

One verdict. One next step. Done.

### Step 6 — Automated test suggestion (optional)

After the report, if any failure scenario was found or left unchecked, name the one automated test that would prevent the worst regression:

> "If you want to prevent this from breaking silently in the future, the one test worth writing is: [specific test in plain English — e.g., 'a test that submits the login form with an empty password and checks that it returns an error message, not a crash.']"

Don't write the test unless asked. Just name it.

---

## Verification checklist

- [ ] Happy path was tested with actual steps, not assumed
- [ ] Failure scenarios covered — at least the most likely failure paths were tested, skipping only paths that genuinely don't apply
- [ ] Regression check covered the most adjacent feature
- [ ] Any "not sure" outcomes are named in the report, not glossed over
- [ ] Verdict is exactly three sentences — what worked, what to check, what to do next
