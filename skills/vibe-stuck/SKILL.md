---
name: vibe-stuck
description: When you've been fighting the same problem for 2+ hours and tried 3+ things — stop trying, start diagnosing.
---

# vibe-stuck

## Overview

Two hours in. Three approaches down. Still broken. The temptation right now is to try one more thing.

Don't.

The problem isn't that you haven't found the right fix yet. The problem is you don't actually know what's wrong. We need to slow down and find out.

---

## Step 1: Stop

Before anything else, say this to the user:

> "Let's stop trying things for a minute. Two hours of fixes without a clear answer usually means we're solving the wrong problem. I want to understand what's actually happening first."

Then ask — just this one question, nothing else:

> "What's the exact symptom — what are you seeing or not seeing right now?"

Wait for the answer. Do not guess, do not pre-empt.

---

## Step 2: What did you try?

Once they've described what's happening:

> "Walk me through what you tried — just a quick list. Don't explain each one yet, just name them."

Wait for the list.

---

## Step 3: What actually happened with each attempt?

Ask 2-3 diagnostic questions at once — don't interrogate every attempt, just gather what you actually need to route to the right path.

> "When you tried [X] — did anything change at all? Did the error message look different? Did it get further before failing?"

This matters. "It didn't work" hides information. "The error changed from X to Y" is a clue. "It got further but then hit a different problem" is a clue. Batch the question across attempts: "You've tried X and Y — what did each one change and what did you see?" One question that covers multiple attempts is better than five sequential questions.

---

## Step 4: Look at the history

Run:
```
git log --oneline -10
```

Count the commits that look like debug attempts. Say it plainly:

> "I can see you've made [N] commits trying to fix this. That tells me we've been in a loop."

If there are 5+ debug commits, name the pattern: "We've been iterating on the same approach. That's usually a sign the assumption underneath the approach is wrong."

---

## Step 5: Look fresh — not through the lens of what's been tried

Open the relevant file or error output without assuming anything. Read it as if you haven't seen this project before.

What does the error actually say? What file, what line, what operation?

Don't skip this because you think you already know. You might — but that assumption is why you've been stuck.

---

## Step 6: Two short lists

Write these out for the user — keep them short:

**What we actually know for certain:**
- [concrete fact from the error or log]
- [concrete fact from what changed / didn't change]
- [what the last working state was, if known]

**What we've been assuming:**
- [thing the fix attempts assumed was true]
- [assumption about where the problem is]
- [assumption about what the error means]

Then say: "The bug is probably hiding in the 'assuming' list."

---

## Step 7: Three paths

Don't call them options — that word causes paralysis. Present them as paths:

---

**Path 1: Different angle**

Based on what we now actually know, propose one approach that hasn't been tried. Ground it in something specific from the diagnosis above — not a new guess, a reasoned move.

Say why: "I think this is worth trying because [specific reason from what we just found]."

If you can't ground it in something specific, say so: "I honestly don't have high confidence in a new direction — which makes Path 2 look better right now."

---

**Path 2: Start fresh from before this started**

Run:
```
git log --oneline -20
```

Find the last commit before the debugging started. Look for commits with messages like 'checkpoint', 'before [feature]', or the last commit before a string of messages mentioning the broken feature. Run `git log --oneline -20` and show the list to the user — they'll recognize the right one.

Say:

> "Your last clean checkpoint was [N] commits ago — that's when this was still working. We can go back to there and rebuild the feature more carefully. You'd lose the debug attempts, but since none of them worked, we're not losing anything useful."

If we go back: create a branch to preserve the current broken state first, in case there's something worth examining later.

---

**Path 3: Get a developer**

Be direct about when this path is right:
- It involves auth, login, sessions, or OAuth
- It involves payments or payment data
- Something might be corrupted (database, cache, build artifacts)
- We've genuinely been stuck 3+ hours with no diagnostic progress

Say: "This one needs someone who can look at it deeply. Let me write the handoff document — it takes two minutes and gives a developer everything they need."

Then run `/vibe-handoff`.

---

## Step 8: One thing

After presenting the three paths:

> "Of those, I'd start with [specific path, specific first action]. Want to do that?"

Not a menu. One recommendation. They can override it.

---

## After fixing

Write to `.vibe/bugs.md` before moving on:

```
## [Date] — [short description]
**Symptom:** [what was happening]
**Root cause:** [what was actually wrong]
**Fix:** [what worked]
**What the failed attempts told us:** [what we ruled out, so next time we skip straight to the right diagnosis]
```

This is how the next session avoids two hours of the same loop.

If a path was chosen but the fix isn't complete yet: write to `.vibe/sessions.md` under today's entry — note what was tried, what was learned, and which path was chosen. The next session should not start blind.

---

## Verification checklist

- [ ] Stopped attempting fixes before running this skill
- [ ] Two lists written and shown to user: what we know vs. what we've been assuming
- [ ] One path recommended — not a menu of options
- [ ] If fixing in-session: checkpoint created before the new attempt
- [ ] If rolling back: user guided to the right commit, not just told to "find the checkpoint"
- [ ] .vibe/bugs.md updated if the issue was resolved
- [ ] .vibe/sessions.md updated with what was learned, even if not resolved
