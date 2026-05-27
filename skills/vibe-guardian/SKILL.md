---
name: vibe-guardian
description: Reads the code you just built and walks through what breaks for real users — error states, auth gaps, edge cases, data problems. Gives specific findings tied to actual code, prioritizes what to fix, and offers to write the fix. Run after building anything that touches user data, auth, or external services.
---

# vibe-guardian

**Scope:** vibe-guardian is for checking the feature you just built — what happens when it's misused, breaks, or has no users? For a full codebase security scan, use `/vibe-check`. For a dedicated auth audit, use `/vibe-auth`.

Claude builds the happy path. The Guardian reads what was just built and asks what happens to a real user when things don't go as planned.

This isn't a checklist to read through. It's a code review grounded in the actual files that changed, ending with a clear picture of what's safe to ship and what needs fixing first.

**What you'll get:** A prioritized list — what's fine, what to fix before anyone uses this, and (for critical items) a concrete code fix or an honest referral to /vibe-handoff if it's genuinely complex.

## When to use

- After building anything that touches user data, auth, payments, or external services
- Before launching a new feature to real users
- When Claude said "this should handle it" but you're not sure how
- When something feels fragile and you want to know why

---

## Process

### Step 1 — Read what was built

Don't go off memory or session notes. Read the actual code first.

Use both commands — `git status --short` shows uncommitted work; `git diff --name-only HEAD~1 HEAD` shows the last committed change. If work is uncommitted, only the first command returns results.

```bash
git status --short 2>/dev/null
git diff --name-only HEAD~1 HEAD 2>/dev/null
```

If `git status` returns nothing and `git diff HEAD~1 HEAD` returns nothing, ask: "What did you just change? Can you describe it or show me the file?"

Read the changed files. Focus on:
- Functions that handle user input or form submissions
- API calls, database operations, or external service calls
- Auth checks, permission guards, or session handling
- Anything that creates, updates, or deletes data

Also check `.vibe/bugs.md` and `.vibe/debt.md` — if there's a known fragile area that overlaps with this change, flag it early.

Then say — out loud, not silently — what was built and what it touches:

> "We built [X]. It lets users [do Y]. It touches [what data/services/auth]. Let me look at what happens when things don't go perfectly."

### Step 2 — Look for gaps in the actual code

Based on what you read, check which of these apply. **Skip the ones that genuinely don't** — this is a code review, not a form to fill out.

For each gap you find, name the specific file and function. Not "the API call" — "the `createOrder()` call in `api/orders.js` has no error handler."

---

**External calls without error handling**

For any API call, database query, or external service call in the changed code:
- Is there a try/catch or .catch() handler?
- What does the user see if the call fails? (Trace the error path — what gets rendered or returned?)
- If this is a form submit: if the call fails, does the user lose what they typed?

*Why this matters:* APIs go down. Databases timeout. A blank crash page destroys trust. A message that says "something went wrong, your data is saved" doesn't.

---

**User behavior the code doesn't handle**

Look at the submit handlers, action functions, and state management in the changed code:

- **Double submit:** After the first click, does the button get disabled or is there a loading state? If not, can the action run twice?
- **Session expiry:** If the user's session expires while the page is open, what happens when they submit? Does the code check, or does it silently fail or worse — succeed with the wrong user?
- **URL parameters with IDs:** If there's a resource ID in the URL or request body, does the code verify the current user owns that resource before returning or modifying it? Or does it trust the client?

*Why this matters:* Double-submits happen on slow connections. Sessions expire on mobile. URL manipulation is one of the most common ways data gets exposed.

---

**Data that could cause crashes**

Trace how the code accesses data from databases or external sources:

- Are nullable fields accessed safely? (`user.profile.name` crashes if `profile` is null — look for chained property access on database results)
- Is there any validation or max length for user-provided strings before they're stored?
- Are list queries limited? (`SELECT * FROM orders` with no LIMIT on a user with 10,000 orders)

*Why this matters:* Test data is clean. Production data isn't. The first real user with an unusual account will find every assumption.

---

**Auth or permission checks that exist only on the front end**

If there's a protected action in this feature, trace the check:
- Is it in the UI component (shows/hides a button), in the API route, or both?
- If I called the API directly — bypassing the UI entirely — would the permission check still run?

Front-end permission checks are not real checks. Anyone who can read network requests can call the API directly.

The fix is always the same: add the permission check to the API route — not just the UI. Removing it from the UI hides the gap; it needs to be enforced on the server side.

*Why this matters:* This is how user data gets accessed by the wrong people. The check must live where the data is, not where the button is.

---

**Unsanitized user input**

Look for places where user-provided input is inserted directly into:
- Database queries without parameterization (e.g., `"SELECT * FROM users WHERE email = '" + email + "'"`)
- HTML templates without escaping (which could let an attacker inject code into the page for other users — called XSS, cross-site scripting)
- Shell commands (e.g., `exec('git ' + userInput)`)

If the project uses an ORM (Prisma, SQLAlchemy, ActiveRecord), parameterization is usually handled automatically — note that and move on. If it uses raw SQL strings with user data: flag it.

---

**Concurrent access** *(only if users share state)*

Only check this if multiple users can affect the same records, or a user might have multiple tabs open. Quick check: if two different users can affect the same data at the same time (booking the same slot, spending the same credits, editing the same document), concurrent access is relevant. If each user only touches their own data, skip this check.
- What happens if two people submit at the same time? Who wins, and is the loser's data silently discarded?
- Is there a unique constraint or transaction that prevents duplicates?

*Why this matters:* Rare but catastrophic — duplicated orders, overwritten records, corrupted state. If it doesn't apply, skip it.

---

### Step 3 — Prioritize clearly

After reviewing, give a clear priority order. Don't inflate severity — if everything is critical, nothing gets fixed.

> "Here's how I'd prioritize this:"

```
Fix before anyone uses this:
• [Specific gap] — [one sentence: what breaks for the user if this isn't fixed]

Fix before launch (not blocking today, but should be done):
• [Gap] — [one sentence why]

Fine to leave for now:
• [Gap] — [one sentence why it's acceptable at this stage]
```

"Fix before anyone uses this" means real data loss, real security exposure, or the feature failing for a predictable real-world scenario. Not everything is urgent.

### Step 4 — Fix the critical items

For anything in "fix before anyone uses this": don't describe the fix — write it.

> "The most important one is [gap in `file.js`, `functionName()`]. Here's the fix:"

```[language]
// [what's changing and why]
[actual code]
```

> "Want me to apply this now?"

If the fix is genuinely complex (database transactions, proper auth middleware, race condition handling with locks), be honest:

> "Fixing this properly requires [what and why]. Getting it wrong would be worse than the current gap. This is worth a /vibe-handoff — a developer could sort this out in an hour."

Don't write a bad patch to avoid that conversation.

### Step 5 — Write to vibe-brain

Before closing, update the project memory.

**If a gap was found and fixed:** Write to `.vibe/bugs.md`:
```
## [Date] — [short description]
**Symptom:** [what would have happened]
**Root cause:** [why]
**Fix:** [what was done]
```

**If something surprising was discovered about a library or service:** Write to `.vibe/gotchas.md`:
```
## [Date] — [library/service]: [short description]
**The surprise:** [what it does unexpectedly]
**Workaround:** [how to handle it]
```

**If anything is being left unfixed:** Write to `.vibe/debt.md`:
```
- [Date] [area] [Low/Medium/High] — [what the gap is and why it's acceptable to leave for now]
```

### Step 6 — Close with next steps

> "Here's where things stand: [one sentence — what was fixed, what's left, is it safe to ship?]
> Next step: [one of: fix [X] now / run /vibe-check for the security scan / run /vibe-git to commit]"

If everything looks solid, say so explicitly:

> "Nothing critical found. The things I checked: [list what was covered]. Safe to proceed — run /vibe-check next."

"Nothing critical found" is a real and useful outcome. Name what was checked so the user knows the scope of the review.

---

## Tone rules

- Read first, then talk. Findings grounded in actual code are more useful than questions about hypothetical code.
- Walk alongside, not above. "Let's look at this together" not "I've identified the following issues."
- Explain impact in user terms. Not "unhandled null pointer" — "the page crashes if a user's profile is missing their name."
- Be honest about severity. Inflating severity destroys trust. Not everything is critical.
- Help, don't just report. For critical gaps: write the fix and offer to apply it. For complex ones: /vibe-handoff — don't patch it badly.
- End with energy. A clean review should feel like "we're ready." A review with fixes should feel like "we made it better."

## Verification

- [ ] Changed files were actually read before any findings were stated
- [ ] `.vibe/bugs.md` and `.vibe/debt.md` were checked for prior patterns in this area
- [ ] Each finding names a specific file and function, not a generic category
- [ ] Only applicable categories were checked — irrelevant ones were skipped
- [ ] Priorities are clear: fix now / fix before launch / fine for now
- [ ] Critical items have actual code fixes written and offered, or an honest /vibe-handoff referral
- [ ] Unfixed items are written to `.vibe/debt.md`
- [ ] Session closes with a specific next step
