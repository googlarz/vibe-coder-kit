---
name: vibe-explain
description: Plain-English summary of what changed this session — what's new, what to test manually, and what might break. Run at the end of any coding session.
---

# vibe-explain

Explains what just happened in plain English. Most vibecoders don't read diffs — this skill tells them what changed, what to click through to verify, and what might have broken, so they can close the tab with confidence.

## When to use

- End of any coding session: "What did we just build?"
- Before sharing a build with someone else
- When returning after a break and wanting to know where things stand
- After Claude makes a lot of changes and the scope feels unclear

## Process

### Step 1 — Gather what changed

Run:
```bash
git diff HEAD~1 --stat 2>/dev/null || git diff --stat 2>/dev/null
```

If git isn't available or has no history, look at the files Claude touched in this session.

Also check `.vibe/sessions.md` — if today's session entry exists, it has useful context.

### Step 2 — Produce the plain-English summary

Output exactly this format:

```
─────────────────────────────────────
  WHAT WE BUILT — [today's date]
─────────────────────────────────────
WHAT'S NEW:
[2-4 bullet points in plain English — user-facing features or changes]
• [e.g. "The login page now shows an error message if the password is wrong"]
• [e.g. "Users can now upload a profile photo"]

WHAT CHANGED UNDER THE HOOD:
[1-3 bullets — technical changes in non-technical language]
• [e.g. "We updated how passwords are stored — more secure now"]
• [e.g. "Added a new page at /settings"]

TEST THESE MANUALLY:
[Specific things to click through to confirm everything works]
1. [e.g. "Try logging in with a wrong password — you should see a red error message"]
2. [e.g. "Sign up as a new user and check that the welcome email arrives"]
3. [e.g. "Open the app on your phone and confirm the layout looks right"]

WATCH OUT FOR:
[Things that might have broken or are fragile — honest, not alarming]
• [e.g. "The logout button wasn't tested today — worth checking"]
• [e.g. "This only works if STRIPE_KEY is set in your environment variables"]
• ["Nothing flagged" if everything looks clean]
─────────────────────────────────────
```

### Step 3 — Update vibe-brain

After producing the summary, write it to `.vibe/sessions.md` if not already written this session:

```
## [YYYY-MM-DD] — [one-line summary]
- Changed: [file list]
- Added: [features]
- Fragile: [concerns from "Watch out for" above]
- Test manually: [from "Test these manually" above]
```

### Step 4 — Save point

If there are unstaged changes, offer:
> "Want me to save a snapshot of this work before you go? Takes 10 seconds."

If yes: `git add -A && git commit -m "session: [one-line summary from Step 2]"`

## Language rules

- Write as if explaining to someone who has never written code
- "We added a new page" not "Created route handler for /settings"
- "The button now does X" not "Implemented onClick handler"
- Be honest in "Watch out for" — don't sanitize real risks

## Verification

After running vibe-explain:
- [ ] The summary could be read by someone who wasn't in the session and they'd understand what changed
- [ ] "Test manually" items are specific actions, not vague ("check the login" → "try logging in with the wrong password")
- [ ] `.vibe/sessions.md` has today's entry
- [ ] Any risky or untested areas are named in "Watch out for"
