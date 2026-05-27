---
name: vibe-clean
description: Fix one piece of known technical debt properly — pick the most valuable item, understand it, fix it surgically, verify it, and update the record.
---

# vibe-clean

## When to use this

Use `/vibe-clean` when the project is stable and you want to fix something you already know is fragile — not to add features, not to respond to an emergency.

This is a deliberate, unhurried session. The goal is to leave the project with one fewer thing to worry about.

If something just broke: use `/vibe-oops` instead.
If you're not sure what to build next: use `/vibe-think` instead.

---

## The core discipline

Cleanup sessions that try to fix everything fix nothing. The rule here is: **pick one item, fix it properly, prove it works, update the record**. If you finish with one thing genuinely resolved, this was a successful session.

---

## Step 1 — Read the debt log

Don't invent work. Start with what's already documented.

Check these files:
- `.vibe/debt.md` — shortcuts taken and known fragile things
- `.vibe/bugs.md` — bugs that took multiple attempts to fix, or came back after being fixed
- `.vibe/sessions.md` — lines marked "Fragile:" from recent sessions

Summarize what you find in plain English — don't paste the raw files at the user. Something like:

> "You've got 4 debt items. The highest-risk one is the login error handling — it's marked HIGH. There's also a recurring bug in the payment form that's appeared twice. Want to start with one of those?"

If none of these files exist yet, or they're empty: that's fine. Ask the user instead:

> "What's the one thing in this project you're most nervous about breaking? That's what we should clean up."

That answer is the debt item to fix.

---

## Step 2 — Pick ONE item

Help the user decide which item is most worth fixing right now. The criteria, in order:

1. Has it caused a real problem before? (appeared in bugs.md, or the user remembers it breaking)
2. Is it in a high-traffic area — login, payments, the thing users do most?
3. Is it blocking other work?
4. Is it marked HIGH risk in debt.md?

Name your recommendation:

> "I'd suggest starting with [X]. It's been a bug twice already, and it's in the login flow — which means every user hits it. The other items can wait."

If the user wants to fix multiple things, push back:

> "Let's finish this one first. Once it's properly resolved and tested, we can move to the next one."

---

## Step 3 — Understand it before touching it

Read the relevant code before writing a single line. For the chosen item, answer these questions:

- What does the current code actually do?
- What specifically is fragile about it?
- What would break if the hack were removed without replacing it?
- What does "fixed" look like — concretely?

Then state the plan in one sentence:

> "I'm going to replace the hard-coded 3-second timeout in the API call with a proper retry that waits before trying again, and I'll verify it handles the case where the API doesn't respond at all."

Get the user's confirmation before touching anything.

If the debt turns out to be worse than the log suggested, say so:

> "This is more fragile than the debt log indicated. Before we change anything, I want to understand [X]. Can you tell me more about when this was added?"

---

## Step 4 — Create a checkpoint

Before writing a single line of code:

```bash
git add -A && git commit -m "checkpoint before cleaning [what you're fixing]"
```

Tell the user: "Saved your work. If the cleanup makes things worse, I can get us right back to here."

If git isn't set up, say so and offer to help set it up before continuing. Don't silently skip this step.

---

## Step 5 — Fix it surgically

Do exactly what was planned in Step 3. Nothing more.

- Change only the specific thing that's fragile
- Don't refactor adjacent code while you're in there — even if it looks messy
- Don't fix this item AND add a feature in the same pass
- Don't "clean up" nearby variable names or comments

If you notice other problems while fixing this one: write them to `.vibe/debt.md` now, and fix them in a future session. Not today.

The discipline here is deliberate. The goal is a change small enough that you can reason about exactly what it does.

---

## Step 6 — Write a test

The fix isn't done until there's a way to confirm it stays fixed.

Write one test that would catch this problem if it came back. Make it specific to the root cause — not just "does the feature work," but "does it handle the thing that was broken."

Examples:
- If the debt was "no error handling when the database is unavailable" → the test simulates the database being down and checks the app shows an error message instead of crashing
- If the debt was "the form accepts empty emails" → the test submits an empty email and checks it's rejected with a clear message
- If the debt was "a hard-coded API URL that breaks in staging" → the test checks the URL comes from the environment config, not from a string in the code

Keep the test simple. One clear scenario is enough.

If the project has no testing framework set up: don't install one just for this. Instead, write a manual verification script — a short script or set of console commands that reproduces the original problem and confirms it's fixed. Document it in `.vibe/debt.md` under the resolved item: "Verified manually by: [what to run/check]."

---

## Step 7 — Verify it works

Ask the user to run the feature that was affected and report back. You can't run the browser — they need to. Example: "Can you test [the specific thing] and tell me what you see?" For a web app: open the browser and click through the feature you changed. For an API: trigger the endpoint from the app or Postman. For a script: run it from the terminal.

Check three things:

1. The original problem no longer occurs
2. The feature still works normally for the happy path
3. One or two nearby features still work — a quick check, not a full test suite

Don't declare it done from reading the code. Wait for the user to confirm they've run it.

---

## Step 8 — Update the record

Remove the item from `.vibe/debt.md` — or mark it resolved with a note. Example:

```
- ~~[2026-05-10] auth/login.js HIGH — no retry on API timeout~~
  Resolved 2026-05-27. Added retry with exponential backoff. Test added.
```

If the cleanup revealed new debt — something you noticed while fixing this item — add it to the file now. Don't hide it.

If the bug appeared in `.vibe/bugs.md` and is now genuinely fixed, add a resolution note there too.

---

## When you're done

Acknowledge it simply:

> "That's one less thing to worry about. The [item] is now handled properly and there's a test to keep it that way."

Then offer: "Want to pick another item, or is that enough for today?"

---

## Verification checklist

- [ ] One specific debt item was chosen — not a vague "clean things up"
- [ ] The item was read and understood before any code was changed
- [ ] A checkpoint commit was made before the fix
- [ ] Only the debt item was changed — no adjacent improvements
- [ ] A test was written that catches this specific class of problem
- [ ] The feature was manually run and verified after the fix
- [ ] `.vibe/debt.md` was updated — item removed or marked resolved
- [ ] No new debt was silently introduced — if found, it was written to the file
