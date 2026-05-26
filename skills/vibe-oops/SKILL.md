---
name: vibe-oops
description: Recovery protocol when things break — diagnose first, then exactly three options: fix it, undo it, or get help.
---

## Overview

Something broke. That's okay. The worst thing you can do right now is start trying random fixes.

This skill walks through what happened, explains it in plain English, and gives you exactly three options. Pick one. Do not try all three at once.

---

## Step 1: Diagnose First — Don't Fix Yet

Before touching anything, understand what broke.

### If the user hasn't described what happened yet

Ask:
> "What happened? Walk me through it — what did you do, and what did you see?"

Wait for the answer. Do not guess.

### Read the error message

If there's an error message, explain it in plain English. One or two sentences. No jargon.

Examples of what this looks like:
- "This means your app tried to connect to the database, but the database is refusing the connection. It's not finding what it's looking for."
- "This means a file your app needs doesn't exist. It was either deleted or never created."
- "This means the code has a typo that breaks the syntax — like a missing bracket or a misplaced comma."

### Identify the type of problem

Pick one:
- **Code error** — the code itself is broken (syntax, logic, a missing function)
- **Configuration error** — a setting, environment variable, or connection string is wrong
- **Deployment error** — the code works locally but broke when you pushed it live
- **Data problem** — something went wrong with the database or files (most serious — see Special Cases)

### Rate the severity

Say this clearly to the user before moving on:

| Severity | Say this |
|----------|----------|
| Low | "This is annoying but harmless — it doesn't affect real users." |
| Medium | "This breaks a feature, but the rest of your app still works." |
| High | "This is affecting real users right now. We should move fast." |
| Critical | "Something is seriously wrong. Stop and read the special cases below." |

---

## Step 2: Present Exactly Three Options

Always three. Always in this order. Always with honest confidence.

---

### Option 1: Fix It

What to tell the user:
1. What you think the problem is (one sentence)
2. What the fix is (what you'll change and where)
3. How confident you are — **be honest**:
   - "I'm 90% sure this is it."
   - "I'm about 70% sure. There's another possibility but this is the most likely."
   - "I'm not certain, but this is the best starting point."
4. How long it'll take ("About 5 minutes" / "This might take 20-30 minutes")

Do not say "this should work" without explaining why you think it'll work.

If confidence is below 50%, say so: "I'm not confident in this fix. I'd recommend Option 2 first."

---

### Option 2: Undo It

Run this first:
```
git log --oneline -5
```

**If a checkpoint exists:**

Tell the user:
> "You have a save point from [X commits ago / time if available]. We can go back to that. Everything you've done since then would be undone."

Then offer:
> "Before we go back, should I save what we have now as a separate checkpoint? That way we don't lose the work entirely — we can look at it later."

If they want to undo:
```
git revert HEAD
```
or for a hard reset to a specific commit (confirm first):
```
git reset --hard [commit hash]
```

Always confirm before running a hard reset. Say what will be lost.

**If no checkpoint exists:**

Be honest:
> "There's no save point in your git history. Here's what we can and can't recover:"

- If files were deleted: explain which ones and whether they can be reconstructed
- If a database was modified: see Special Cases — this is serious
- If code was overwritten: check if your editor has local history (VS Code does — Cmd+Shift+P → "Local History: Find Entry to Restore")

Do not pretend recovery is possible when it isn't.

---

### Option 3: Get Help

Tell the user when to choose this:
- The problem involves real money, real payments, or payment data
- You suspect data loss or corruption
- A security issue might be involved (passwords exposed, unauthorized access)
- You've tried two different fixes and both failed
- You're genuinely unsure what's wrong

**Produce a handoff note immediately.** Fill this in and give it to the user to share with a developer:

```
## What we built
[One paragraph describing what the app does and the tech stack]

## What broke
[Exact description of what stopped working, when it started, what changed before it broke]

## The error message
[Paste the exact error — full text, not a summary]

## What we tried
[List every fix that was attempted, in order]

## What to look at first
[Your best guess at the root cause based on the error type]

## Files most likely involved
[List the relevant files — routes, config, database connection, etc.]
```

**Where to get help:**
- For common frameworks (Next.js, Supabase, Vercel, Stripe): search their official Discord — usually fastest
- Stack Overflow: good for error messages — paste the exact error in quotes
- Hiring a developer for a few hours: Toptal, Upwork, or a local freelancer — use the handoff note above

---

## Step 3: What NOT to Do

These make things worse. Do not do them:

- **Do not suggest more than 3 fixes without pausing.** If two fixes have failed, stop. Reassess. Say what you've learned from the failures before trying anything else.
- **Do not delete files as a fix** unless the user explicitly asks you to delete a specific file and understands what it does.
- **Do not say "this should work"** without a reason. If you can't explain why a fix should work, say that.
- **Do not keep trying the same fix** with small variations. If it failed once, it will likely fail again unless you understand why it failed.
- **If the same fix fails twice:** stop, say "This approach isn't working, and here's what I think that means:", and explain what you've ruled out. Then reassess.

---

## Special Cases

### Production is down

Treat as critical severity.

**Go to Option 2 first.** Do not attempt fixes while real users are affected.

1. Undo to the last known-good state
2. Verify production is back up
3. Then investigate the fix in a safe environment

If you can't undo, prioritize getting *something* working over getting it working *correctly*.

### Data might be lost

Stop immediately. Do not touch anything else.

1. Do not run any database commands
2. Do not restart the database
3. Check if a backup exists:
   - Supabase: Dashboard → Settings → Database → Backups
   - PlanetScale, Railway, Render: check their dashboard for backup options
   - Local database: check for `.sql` dump files in the project

If no backup exists: be honest about what's recoverable. Some data loss may be permanent. A developer may be needed.

### "It was working yesterday"

Check git for recent changes:
```
git log --oneline --since="2 days ago"
```

Show the user what changed. The most recent commit touching the broken area is almost always the cause.

---

## Verification

After a fix is applied, confirm it worked before declaring done:

1. Ask the user to test the specific thing that was broken
2. Ask them to test one other thing nearby (to check for side effects)
3. Create a checkpoint: `git add -A && git commit -m "fix: [what was fixed]"`

Only then: "Looks like that fixed it."

If testing reveals a new problem: go back to Step 1. Do not stack fixes.
