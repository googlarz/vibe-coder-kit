---
name: vibe-guardian
description: A walkthrough of what happens when things go wrong — error states, edge cases, and failure modes Claude skips by default. Explains each risk in user terms, prioritizes what to fix, and gives concrete next steps. Run after building anything that touches user data, auth, or external services.
---

# vibe-guardian

A walkthrough of the failure modes Claude skips when building the happy path. Claude builds what you ask for — The Guardian asks what happens to a real user when things don't go as planned.

This isn't a code audit. It's a guided conversation: "let's look at this together and make sure real users don't get hurt if something goes wrong."

## When to use

- After building anything that touches user data, auth, payments, or external services
- Before launching a new feature to real users
- When Claude said "this should handle it" but you're not sure how
- When something feels fragile and you want to know why

---

## Process

### Step 1 — Get oriented together

Before diving in, understand what was built this session. Check `.vibe/sessions.md` and run:

```bash
git diff --stat HEAD 2>/dev/null
```

Then say — out loud, not silently — what the feature does and who it affects:

> "So we built [X]. This lets users [do Y]. It touches [data/service/auth]. Let me walk through what happens when things don't go perfectly."

Setting this frame matters. It tells the user what's being reviewed and why it's worth checking.

### Step 2 — Walk through the failure scenarios

Go through each category below. For any that apply, don't just flag the gap — explain what happens to the user, and then explain what to do about it. Skip categories that genuinely don't apply.

---

**When the connection fails or the service is down**

If this feature calls an API, a database, or any external service: what does the user see if that call fails?

- Does the page crash, or show a helpful message?
- If they were in the middle of filling out a form, is their data lost?
- If the operation partially completed (some things saved, some didn't), is there a way back?

*Why this matters:* APIs go down. Databases timeout. If users lose work or see a blank crash page, they lose trust and may not come back.

*What to do:* Wrap the call in an error handler that shows a friendly message and, where possible, preserves what the user typed.

---

**When the user does something unexpected**

Walk through these quickly — just the ones that apply:

- **Double submit:** Can they click the button twice? What happens — two records created, two charges, or is it handled?
- **Navigate away mid-operation:** If they close the tab while something is saving, does anything break or get stuck in an in-between state?
- **Session expired:** If they leave the tab open for hours and then try to submit, do they get a clear message or a cryptic error?
- **URL manipulation:** If there's an ID in the URL (like `/users/123`), can they change it to `/users/124` and access someone else's data?

*Why this matters:* These aren't edge cases — they happen constantly. Double-submits happen every time there's a slow connection. Sessions expire on mobile all the time.

---

**When the data isn't what you expect**

- What if a field that should exist is empty or null — does the app crash or handle it gracefully?
- What if the user's name is 300 characters? What if their input contains special characters or HTML?
- What if there are 10,000 items where you expected 10?

*Why this matters:* Real data is messy. The test data you used while building is clean. Production data isn't.

---

**When auth or permissions aren't enforced**

This one deserves extra attention:

- Can a logged-out user reach this page directly? What happens?
- If this action is only for certain users (admins, account owners), does the code check — or does it trust the front end?
- If permissions are checked: where? In the component, in the API, or both?

*Why this matters:* Front-end permission checks can be bypassed. Anyone who knows the URL or can read the network requests can try things the UI doesn't show them. Permissions need to be enforced where data is accessed, not just where buttons are shown.

---

**When two things happen at the same time**

Only applies if multiple users interact with the same data, or the same user might have multiple tabs open:

- Can two users edit the same thing simultaneously? Who wins?
- Can the same user trigger this twice from two browser tabs?

*Why this matters:* This is rare but catastrophic when it happens — duplicated orders, overwritten data, corrupted state.

---

### Step 3 — Prioritize clearly

After walking through the scenarios, don't just list findings. Tell the user what order to handle things in:

> "Here's how I'd prioritize this:"

```
Fix before anyone uses this:
• [Gap] — [one sentence on what happens to users if this isn't fixed]

Fix before launch:
• [Gap] — [one sentence on why]

Fine to leave for now:
• [Gap] — [one sentence on why it's low risk]
```

Be specific about "fix before anyone uses this" — this means real data loss, security exposure, or complete feature failure. Not everything is urgent. Most things aren't.

### Step 4 — Help fix the critical items

For anything in "fix before anyone uses this": don't just name it, help fix it. Say:

> "The most important one is [gap]. Here's what fixing it looks like: [concrete approach in plain English]."

Then offer: "Want me to handle that now?"

If a gap genuinely requires more than a few lines to fix correctly (database transactions, complex auth logic, race condition handling), say so clearly:

> "This one is more complex than it looks. Fixing it properly requires [brief explanation]. This might be worth running /vibe-handoff for — a developer could sort this out in an hour."

Don't patch it badly to avoid that conversation. A bad patch is worse than knowing the gap exists.

### Step 5 — Write to vibe-brain

Before closing:

**If a gap was found and fixed:** Write to `.vibe/bugs.md`:
```
## [Date] — [short description]
**Symptom:** [what would have happened]
**Root cause:** [why]
**Fix:** [what was done]
```

**If something surprising about a library or service was discovered:** Write to `.vibe/gotchas.md`:
```
## [Date] — [library/service]: [short description]
**The surprise:** [what it does unexpectedly]
**Workaround:** [how to handle it]
```

**If anything is being left unfixed for now:** Write to `.vibe/debt.md`:
```
- [Date] [area] [Low/Medium/High] — [what the gap is and why it's acceptable to leave for now]
```

### Step 6 — Close with next steps

End with what the user should do next, in order:

> "Here's where things stand: [one sentence summary — what's fixed, what's left].
> Next step: [specific action — fix X, or run /vibe-check to scan for security issues, or run /vibe-git to commit]."

If everything looks solid: say so. "Nothing critical found" is a real and useful outcome. Name the specific things that were checked so the user knows what was covered.

---

## Tone rules

- Walk alongside, not above. "Let's look at this together" not "I've identified the following issues."
- Explain impact in user terms. Not "unhandled null pointer" — "the page will crash if a user's profile is missing their name."
- Be honest about severity. Not everything is critical. Inflating severity destroys trust.
- Help, don't just report. For critical gaps: offer to fix them. For complex ones: offer /vibe-handoff.
- End with energy. A clean review should feel like "we're ready." A review with fixes should feel like "we made it better."

## Verification

- [ ] Each failure scenario was explained in user terms, not technical terms
- [ ] Priorities are clear: fix now / fix before launch / fine for now
- [ ] Critical items have a concrete fix or a referral to /vibe-handoff
- [ ] Unfixed items are written to `.vibe/debt.md`
- [ ] Session closes with a specific next step
