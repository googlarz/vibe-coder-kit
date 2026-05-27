---
name: vibe-handoff
description: Generate a developer handoff document — either an emergency escalation (something broke) or a planned onboarding doc (developer joining the project).
---

# vibe-handoff

Produces a structured document a real developer can act on immediately. Use this when something breaks badly and you need help, or when a developer is joining the project and needs to understand what was built.

## Overview

Vibecoders often hit a wall — something breaks and the error messages are incomprehensible, or the project is growing and needs professional review. At that moment, the biggest obstacle isn't the problem itself: it's being able to describe it clearly to someone who can fix it.

vibe-handoff produces two kinds of documents:

- **EMERGENCY** — something broke, you need help now. Gives a developer everything they need to diagnose the problem without a back-and-forth.
- **PLANNED** — a developer is joining the project or doing a professional review. Gives them the full picture: what it is, how it works, what the risks are.

Ask the user which mode they need if it isn't obvious. If they say anything like "something broke," "it stopped working," "I'm getting an error," or "I need help fast" — that's EMERGENCY. If they say "someone is joining," "I want a developer to review this," or "we're going professional" — that's PLANNED.

---

## How to Invoke

**Emergency (something broke):**
> "Run vibe-handoff emergency"
> "Something broke, help me explain it to a developer"
> "I need to hand this off, it's broken"

**Planned (developer joining or reviewing):**
> "Run vibe-handoff planned"
> "I'm bringing in a developer, help me onboard them"
> "Generate a project overview for a developer"

---

## Emergency Mode Process

When something is broken and the user needs help immediately.

### Step 1 — Gather context

Ask the user these questions if the answers aren't obvious from the current session:

1. "What stopped working? What did you expect to happen, and what happened instead?"
2. "Is there an error message? Copy it exactly, even if it looks like gibberish."
3. "When did it last work? Did anything change right before it broke — a code change, a deploy, installing something new?"
4. "Is this affecting real users right now?"

### Step 2 — Read what's available

Check for `.vibe/project.md`, `.vibe/sessions.md`, and `.vibe/debt.md`. Read them silently. This tells you the stack, what was worked on recently, and what the known weak points are.

### Step 3 — Form a hypothesis

Before writing the document, reason through the most likely cause. Use the recent session history and debt log — if something was recently hacked together in the area that broke, say so. Be honest about uncertainty: "most likely X, but could also be Y."

### Step 4 — Produce the document

Output the emergency handoff document using the template below.

### Step 5 — Suggest next steps

After the document, tell the user where to get help:
- Is this a specific platform (Vercel, Supabase, Stripe)? Point to their Discord or support.
- Is this a common framework (Next.js, Rails, Django)? Name the Stack Overflow tag.
- Is this serious enough to hire someone? Say so directly and mention Upwork or Toptal.

---

## Planned Mode Process

When a developer is joining the project or doing a professional review.

### Step 1 — Read all vibe-brain files

Read these files if they exist:
- `.vibe/project.md` — stack, platform, deployment
- `.vibe/decisions.md` — architectural decisions and why they were made
- `.vibe/debt.md` — known shortcuts and risk levels
- `.vibe/sessions.md` — history of what was worked on
- `.vibe/bugs.md` — bugs that took multiple attempts to fix (the incoming developer must not repeat them)
- `.vibe/gotchas.md` — unexpected library/service behaviors already discovered
- `.vibe/conventions.md` — naming and structural rules the project has established

### Step 2 — Infer what's missing

If any of these files are missing or sparse, fill in what you can from the codebase:

```bash
# Stack
cat package.json 2>/dev/null | grep -E '"name"|"dependencies"' | head -20
cat requirements.txt 2>/dev/null | head -20

# Project structure (top-level only)
ls -1 . | grep -v node_modules | grep -v ".git"

# Entry points
ls src/ app/ pages/ api/ 2>/dev/null
```

Note explicitly what you inferred from code versus what came from `.vibe/` files. Inferences can be wrong — the developer receiving this document needs to know what to verify.

### Step 3 — Assess what needs professional attention

Honestly assess the areas a developer should review. Don't soften this. Common areas:
- **Auth** — is it custom? Is session handling solid?
- **Data model** — are there obvious normalization problems or missing indexes?
- **Security** — has a security scan been run? (vibe-check — a 66-pattern security scan tool in this project's workflow.) Are there known findings?
- **Payments** — is Stripe integration complete and correct?
- **Performance** — are there database queries in loops, missing caching, large unoptimized assets?
- **Deployment** — is the deploy process documented and repeatable?

### Step 4 — Produce the document

Output the planned handoff document using the template below.

---

## Output Templates

### Emergency Handoff Document

```
# EMERGENCY HANDOFF — [Project name or "Unnamed Project"]
Generated: [today's date]

---

## What We Built
[2-3 sentences. What the project does, who uses it, approximate current state. Plain English.]

## What Broke
[Exactly what stopped working. Be specific: which page, which action, which API call.
When it was last working. What changed right before it broke, if known.]

## What We Tried
[Bullet list of every fix attempted. Be honest — include things that made it worse.]

## The Error
[Exact error message, copied verbatim. If there's no error message, describe the symptom
as specifically as possible: "the page loads but the submit button does nothing",
"the app crashes with a white screen", etc.]

## What a Developer Should Look at First
[Your best guess at root cause. Be direct even if uncertain:
"Most likely X because of Y. Could also be Z."
Point to specific files or functions if you know them.]

## Environment
[From .vibe/project.md if available:]
- Platform: [Vercel / Replit / Railway / local / etc.]
- Database: [Supabase / PlanetScale / SQLite / etc.]
- Auth: [NextAuth / Clerk / custom / none]
- Deployment: [how it gets pushed to production]
- Stack: [main language/framework]

## Urgency
[Answer these directly:]
- Real users affected: [yes / no / unknown]
- Data at risk: [yes / no / unknown]
- Revenue affected: [yes / no / unknown]

---

## Where to Get Help

[One of the following, based on what's broken and how serious:]

**If it's a platform issue** (Vercel, Supabase, etc.):
→ [Platform name] Discord: [link if known] or their support docs.
   For common platforms, use these: Vercel: vercel.com/support | Supabase: supabase.com/support | Railway: railway.app/help | Fly.io: community.fly.io | Stripe: support.stripe.com. If the platform isn't in the list above, write: "Search for [actual platform name, e.g. Railway] support or community Discord" — substitute the actual platform name, not a placeholder.

**If it's a framework issue** (Next.js, Rails, etc.):
→ Stack Overflow tag: [tag name] — paste the exact error message.

**If this needs a professional developer:**
→ This is beyond vibe-coding territory. Post on Upwork (upwork.com) or Toptal (toptal.com)
   and share this document. A developer should be able to diagnose within an hour.
```

---

### Planned Handoff Document

```
# PROJECT HANDOFF — [Project name]
Generated: [today's date]

---

## What This Is
[One paragraph. What the project does, who the users are, current state
(prototype / MVP / in production with X users). Be honest about maturity.]

## Stack
[From .vibe/project.md if available; otherwise inferred from codebase — note "[inferred from codebase, not from project log]" if project.md was missing.]
- Language/Framework: [e.g. Next.js 14, Rails 7, Django 4]
- Database: [e.g. PostgreSQL via Supabase, SQLite]
- Auth: [e.g. NextAuth with Google, Clerk, custom JWT]
- Hosting: [e.g. Vercel, Railway, Fly.io, self-hosted]
- Key third-party services: [Stripe, Resend, Cloudinary, etc.]

## Architecture
[From .vibe/decisions.md if available. Key decisions and why they were made.
If the decisions file doesn't exist, describe the structure you can see:
- How the codebase is organized
- Where the main entry points are
- How data flows through the system
Note: "[inferred from codebase, not from decision log]" if the file was missing.]

## Known Debt
[From .vibe/debt.md if available. Format each item as:]

| Area | What the shortcut is | Risk if not fixed |
|------|----------------------|-------------------|
| [file or feature] | [plain description] | [LOW / MEDIUM / HIGH] |

[If no debt file exists: "No formal debt log. See 'What Needs Professional Attention' below."]

## Recent History
[From .vibe/sessions.md — last 5 sessions summarized as bullet points.
Format: "[Date] — [what was done] / [what was left fragile]]
If sessions file doesn't exist: "No session log available."]

## What Needs Professional Attention
[Honest assessment. Flag these areas if they apply:]

- [ ] **Auth** — [describe what's there and what the concern is]
- [ ] **Data model** — [describe schema and any obvious issues]
- [ ] **Security** — [note if a security scan was run (vibe-check — a 66-pattern security scan tool in this project's workflow); list known findings]
- [ ] **Payments** — [describe Stripe setup and any gaps]
- [ ] **Performance** — [describe any known slow paths]
- [ ] **Deployment** — [describe how deploys work; note if it's manual/fragile]

[**Default: keep all items.** Only remove a line if you have specific evidence from the codebase that the concern genuinely doesn't apply — e.g. "no auth system present" is grounds to remove the Auth line; "I didn't see any Stripe files" is not evidence the payments concern doesn't apply (it may just not be implemented yet). When in doubt, keep the line. A developer would rather see a concern that turns out to be a non-issue than find a gap you quietly omitted. Add any concerns not on this list that are specific to this project.]

## How to Run Locally
[If a README exists with setup instructions, summarize them here. If not, infer from the codebase and note "[inferred from codebase, not from README]".]

1. Clone the repo
2. Copy `.env.example` to `.env` and fill in: [list required env vars]
3. Install dependencies: `[npm install / pip install -r requirements.txt / etc.]`
4. [Any database setup steps]
5. Run: `[npm run dev / python manage.py runserver / etc.]`
6. Open: [http://localhost:3000 or equivalent]

[If this can't be inferred: "Setup instructions not documented. Ask the original developer."]

## About This Project's Setup
This project uses [vibe-coder-kit](https://github.com/googlarz/vibe-coder-kit) — a set of
behavioral contracts and hooks for AI-assisted development. Key things to know:

- `.vibe/` folder contains project context, decision log, debt log, and session history
- The AI assistant follows behavioral contracts defined in `CLAUDE.md` at the project root
- Checkpoints are saved as git commits before significant changes

When working with AI tools on this project, the behavioral baseline is active by default.
```

---

## Verification

Before handing either document to anyone, show it to the user first:

> "Before I send this — does this describe your project accurately? Is there anything wrong or missing?"

This matters because you may have inferred things that are slightly off. The user is the final check.

After that, confirm:

- [ ] The document was reviewed and confirmed by the user before sending
- [ ] The document could be handed to a developer who has never seen the project and they would know where to start
- [ ] Error messages are copied verbatim (EMERGENCY) or stack is stated precisely (PLANNED)
- [ ] Nothing is softened — risks, debt, and uncertainty are stated plainly
- [ ] Root cause hypothesis stated (even if unconfirmed)
- [ ] The urgency assessment (EMERGENCY) or professional attention list (PLANNED) is honest
- [ ] Next steps are actionable, not vague
