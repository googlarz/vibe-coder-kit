---
name: vibe-think
description: Turn a vague idea into a clear, agreed scope before writing a single line of code. Ask the right questions, state what you're building and what you're not, name the biggest risk. Run this before /vibe-plan.
---

# vibe-think

Turns a vague idea into a concrete, agreed scope before anyone writes code. Most vibe-coded features fail because the idea wasn't clear before building started — the wrong thing gets built, or it gets abandoned halfway because the real problem was different.

## When to use

- "I want to add X to my app"
- "I have this idea for a feature"
- "Can we build Y?"
- Any time a session starts with something to build rather than something to fix

Don't skip this when the idea feels obvious. The 5 minutes it takes to run prevents hours of rebuilding.

---

## Process

### Step 1 — Read what's already known

Check these files silently if they exist:
- `.vibe/project.md` — what the app already does
- `.vibe/sessions.md` — what was recently built
- `.vibe/decisions.md` — what architectural choices have already been made

This gives you context before asking questions. Don't ask about things you can already read.

### Step 2 — Ask clarifying questions

Ask **at most 5 questions**. Focus on what you don't know from reading the existing files. Cover these in any order that fits the idea:

1. **Who is this for?** — "Who uses this, and what are they trying to do?" (If obvious from project.md, skip.)
2. **What does success look like?** — "How will you know it worked?" (A specific action or outcome, not "it's done.")
3. **What's the simplest version?** — "If we had to build this in one day, what would it do?"
4. **What's definitely out?** — "Is there anything that sounds related but we're not doing?"
5. **Deadline or constraint?** — "Is there a date this needs to be ready, or anything we can't change?"

Do not ask more than 5. Do not ask questions you can answer from the existing files. Do not ask vague questions — each question should have a specific answer.

### Step 3 — State the scope

Write the scope in plain English. Three parts, nothing more:

```
WHAT WE'RE BUILDING:
[One paragraph. Concrete enough that you could hand it to someone else and they'd build the right thing.
Not "a feature for users" — "a page at /settings where logged-in users can change their email and password."]

WHAT WE'RE NOT BUILDING (this session):
[2-4 things that are related but explicitly out of scope.
"Not building: account deletion, profile photo upload, two-factor auth."]

BIGGEST RISK:
[One sentence. What's the most likely way this goes wrong?
"The biggest risk is that changing email requires re-verification — if we skip that, users could lock themselves out."]
```

### Step 4 — Confirm before saving

Show the scope to the user and ask:

> "Does this match what you had in mind? Anything wrong or missing?"

Do not save until the user confirms. One sentence changes here are fine. If the scope is fundamentally different from what they meant, ask the clarifying questions again with better focus.

### Step 5 — Save and hand off

Once confirmed:

1. Write to `.vibe/sessions.md`:
   - If today's `## YYYY-MM-DD` entry already exists (e.g. vibe-scope ran earlier): append the scope block under that entry — do NOT add another `## YYYY-MM-DD` header.
   - If a **Scope:** or `TODAY WE ARE:` block already exists under today's entry, overwrite it rather than appending a second one — the user may have run /vibe-scope earlier.
   - If no entry for today exists: prepend a new one at the top.

```
## [YYYY-MM-DD] — [one-line scope summary]

TODAY WE ARE:
[paste WHAT WE'RE BUILDING]

WE ARE NOT TOUCHING:
[paste WHAT WE'RE NOT BUILDING]

BIGGEST RISK:
[paste BIGGEST RISK]

---
```

2. If `.vibe/` doesn't exist yet, create it and the sessions.md file.

3. Offer next step:
> "Scope saved. Ready to plan how we'll build it? Run /vibe-plan, or tell me to start and I'll think through the steps first."

---

## Language rules

- Plain English throughout. No technical jargon in the scope document.
- "WHAT WE'RE BUILDING" should read like you're explaining it to a friend, not a developer.
- "BIGGEST RISK" should describe what happens to the user, not the technical problem.
  - ✅ "Users could get locked out of their account"
  - ❌ "Email mutation requires transaction rollback handling"

## Verification

After running vibe-think:

- [ ] The scope is specific enough that two people reading it would build the same thing
- [ ] "What we're not building" exists and has at least 2 items
- [ ] The biggest risk describes user impact, not technical complexity
- [ ] The user confirmed the scope before it was saved
- [ ] `.vibe/sessions.md` has a new entry at the top
- [ ] .vibe/ directory exists and was created if missing
