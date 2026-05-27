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
git diff --stat HEAD 2>/dev/null || git status
```

List the files changed this session. For each file, identify what user-facing behavior it affects. Map code changes to user actions — not "modified auth.js" but "users logging in."

### Step 2 — Happy path test

Write out the exact steps to test the main thing that was built. Be specific enough that a non-developer could follow them.

```
HAPPY PATH:
1. [Specific action — e.g., "Open the app at /settings while logged in"]
2. [Next action]
3. [Expected result — e.g., "Your new email address appears immediately"]
```

Ask the user to run through these steps now if possible. If they can't test right now, say so explicitly — this is not a step to defer.

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
| **Mobile screen** | Does the layout break on a phone screen? |

For each that applies, write the test step and the expected outcome. Flag any where the expected outcome is "I'm not sure" — those are the ones most likely to break.

### Step 4 — Nearby features check

Sometimes fixing one thing accidentally breaks something nearby. Check what was working before this session that could have broken.

First, check `.vibe/bugs.md` if it exists. Any previously fixed bugs in the area being tested are the highest-risk regressions — Claude often re-introduces the same class of bug when modifying nearby code. Name each one explicitly: "We fixed [X] on [date] — worth confirming it still holds."

Then check adjacent files:

```bash
git diff --name-only HEAD~1 2>/dev/null
```

List adjacent features and ask the user to spot-check them — one action each. This doesn't need to be exhaustive, just the most likely collateral damage.

### Step 5 — Report

Output the test results in this format:

```
TEST RESULTS
─────────────────────────────────
✅ Happy path: [passed / failed — what happened]

FAILURE PATHS:
✅ [scenario]: [result]
⚠️  [scenario]: not tested — [why, or "couldn't reproduce"]
🚨 [scenario]: [what broke]

THINGS WE DIDN'T TOUCH (check these still work):
✅ [feature]: checked, still working
⚠️  [feature]: not checked — [reason]

VERDICT:
[Safe to push / Fix these before pushing / Do not push — [what's broken]]
─────────────────────────────────
```

### Step 6 — Automated test suggestion (optional)

After the report, if any failure scenario was found or left unchecked, name the one automated test that would prevent the worst regression:

> "If you want to prevent this from breaking silently in the future, the one test worth writing is: [specific test in plain English — e.g., 'a test that submits the login form with an empty password and checks that it returns an error message, not a crash.']"

Don't write the test unless asked. Just name it.

---

## Verification checklist

- [ ] Happy path was tested with actual steps, not assumed
- [ ] At least 3 failure scenarios were checked
- [ ] Regression check covered the most adjacent feature
- [ ] Any "not sure" outcomes are named in the report, not glossed over
- [ ] Verdict is one of three: safe / fix first / do not push
