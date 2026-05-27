---
name: vibe-debug
description: Systematic investigation when a bug's cause isn't obvious — reproduce it first, then narrow it down, then fix it.
---

# vibe-debug

## When to use this vs. other skills

Use `/vibe-debug` when something isn't working and you're not sure why — a feature that never worked, something that breaks sometimes, or a bug you can't explain.

If the bug is in production right now and users are affected: use `/vibe-oops` instead — that's the emergency path.

If you've already tried 3+ approaches without converging: skip straight to `/vibe-stuck`.

---

## The core discipline

Most debugging goes wrong because the fix comes before the understanding. The pattern here is always: **reproduce → narrow → fix**. Don't skip steps.

---

## Step 1: Reproduce it consistently

Before touching any code, figure out if you can make the bug happen on demand.

Ask the user:
> "Walk me through exactly what you did when it broke — every step."

Then try to reproduce it with those exact steps. A bug you can reproduce is a bug you can fix. A bug you can't reproduce might just go away on its own — or it might keep surprising you.

If it's intermittent (happens sometimes but not always):
- Ask: does it happen with specific data? specific users? in a specific browser? when logged in vs. logged out?
- Look for a pattern before assuming it's random
- Try to find the minimum conditions that consistently trigger it

Do not move to Step 2 until you can make the bug happen when you want it to.

---

## Step 2: Read the error (if there is one)

Don't jump to code. Read the error first.

Translate it into plain English before doing anything else. What file and line does it point to? What does it actually mean?

Check both places:
- **Browser console** — press F12 or right-click → Inspect → Console tab
- **Server logs** — your hosting dashboard (Vercel, Railway, Render) or your terminal if running locally

These often point to different things. A browser error might say "can't read property of undefined." The server log might say "database connection refused." Both matter — they're telling you different parts of the story.

If the error message is confusing, use `/vibe-log` to get a plain-English translation.

---

## Step 3: Find where the bug lives

Don't read everything. Use binary search — start at one end and cut the problem in half each time.

Start at the entry point for the broken feature:
- For a button: what function runs when it's clicked?
- For a page that fails to load: what route handles that URL?
- For a form: what happens when it's submitted?

Then trace one level at a time. What does this function call? What does that function call? You're following the path of execution until you find where it goes wrong.

Add temporary logs to mark your progress:
```
console.log("reached point A")
console.log("reached point B", someValue)
console.log("reached point C", anotherValue)
```

Run the code and look at your logs. The last one that prints tells you where execution stopped. That's your target zone.

---

## Step 4: Name your best guess

Before changing anything, name what you think is causing this, and why. Even a rough guess is useful. Write it down: "I think the problem is ___ because ___." This forces clarity before you start fixing.

Something like:
- "I think the user ID is undefined when it reaches the database query — the log shows undefined at point C."
- "I think the API call is failing because the URL has a typo."
- "I think the condition on line 47 is backwards — it runs when it shouldn't."

If you have more than one guess, pick the most likely one. Don't test all of them at once — you won't know which one actually fixed it.

State the guess clearly before writing any code.

---

## Step 5: Test the hypothesis

Make one targeted change that proves or disproves your hypothesis. This is not the fix yet — it's a test.

Examples:
- Hardcode a value that you suspect is coming in wrong. If the bug goes away, you know the value was the problem.
- Add a log right before the suspected line and print the exact value. If it shows what you expected, your hypothesis is wrong — go back to Step 4.
- Comment out a block of code to see if removing it changes anything.

One change. Check the result. Then decide whether your hypothesis holds.

---

## Step 6: Fix it

Now you know what's wrong. Fix the specific root cause — not the symptom.

First, create a checkpoint so you can get back here if the fix makes things worse:
```
git add -A && git commit -m "checkpoint before debug fix"
```

Then make the surgical change. Change only what's broken. Don't improve adjacent code or clean up unrelated things while you're in there.

After the fix:
- Remove all the temporary console.log lines you added in Step 3
- Run through the exact reproduction steps from Step 1 and confirm the bug is gone
- Test one or two nearby things to make sure you didn't accidentally break something else

---

## Step 7: Check for siblings

The same bug often lives in more than one place.

Search the codebase for the same pattern you just fixed:

```bash
grep -r "[the pattern that was wrong]" . --include="*.js" --include="*.ts" --include="*.py" --exclude-dir=node_modules -n
```

For example, if you fixed a bug where `calculateTotal()` wasn't handling negative numbers, search for other places that do math: `grep -rn 'calculateTotal\|subtotal\|amount' . --include='*.js' | grep -v node_modules`.

If you fixed a missing null check — search for similar null access patterns. If you fixed an unhandled promise rejection — search for other async functions without try/catch. Name any siblings you find but don't fix them in this session — write them to `.vibe/debt.md`.

This takes two minutes and prevents the same class of bug from showing up again in a week.

---

## If you're still stuck after 3 hypotheses

Stop. Don't keep guessing.

Say what you've ruled out:
> "We've confirmed the data is correct when it enters this function. The bug happens somewhere between here and the database. I'm not sure what's causing it."

Then suggest `/vibe-stuck` — that skill is built for exactly this situation: when you've been going in circles and need to step back and reassess.

---

## Verification checklist

Before calling this done:

- [ ] Bug was reproduced consistently before any fix was attempted
- [ ] Root cause was named specifically — not just "there was a bug"
- [ ] Only the broken thing was changed — no adjacent improvements
- [ ] All temporary debug logs were removed
- [ ] Fix was verified using the same steps that originally reproduced the bug
- [ ] Nearby code was checked for the same class of bug
- [ ] A checkpoint commit was made before the fix
