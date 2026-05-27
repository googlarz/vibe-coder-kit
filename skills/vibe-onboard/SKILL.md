---
name: vibe-onboard
description: Generate a "first hour" onboarding doc for someone new joining the project — a co-founder, friend, hired developer, or freelancer.
---

# vibe-onboard

Produces an ONBOARDING.md that eliminates the "where do I find X?" and "why does this work this way?" questions — so the new person's first session is productive instead of painful.

## This is different from vibe-handoff

- **vibe-handoff** is emergency escalation — something broke and you need a developer to rescue it now
- **vibe-onboard** is planned collaboration — someone's joining the project and you want them up to speed fast

The difference matters. This skill assumes the project is working and the goal is a smooth first day, not triage.

**vs. vibe-handoff (PLANNED mode):** vibe-onboard creates a first-day guide for someone joining an ongoing project. vibe-handoff (PLANNED mode) creates an exit document when handing a project to a new maintainer. Different audiences, different depth.

---

## Before Starting — Where to save the document

Ask this before anything else:

> "First — where should I save this? Common choices: `ONBOARDING.md` in the project root, or `.vibe/onboarding-[name].md` if there are multiple collaborators."

---

## Step 1 — Ask who is joining

Before reading anything or writing anything, ask this one question:

> "Who's joining and what's their role — are they a developer taking over features, a designer touching the frontend, or someone checking things out?"

Wait for the answer. It shapes everything else.

- **Developer** → full document: technical setup, architecture decisions, what not to touch
- **Designer** → focused on frontend files, design tokens and colors, how to see changes locally
- **Non-technical collaborator** → access to deploy dashboards, how the app works, what's broken and what isn't

If the answer is unclear or they say "just a friend helping out" — generate the developer version. It's the most complete and wastes nothing.

---

## Step 2 — Read what's available

Read these files silently before writing anything:

- `.vibe/project.md` — stack, hosting, deployment
- `.vibe/debt.md` — known shortcuts and risk levels (critical for the "What's Fragile" section)
- `.vibe/sessions.md` — look for "Fragile:" fields in recent sessions
- `.vibe/decisions.md` — architectural choices and why they were made
- `.vibe/.scope` — if it exists, it defines what the current owner treats as off-limits

If these files don't exist, infer what you can from the codebase:

```bash
# Package manager and stack
cat package.json 2>/dev/null | head -30
cat requirements.txt 2>/dev/null | head -10
ls -1 . | grep -v node_modules | grep -v ".git"
```

Note explicitly what came from `.vibe/` files versus what you inferred. The new person deserves to know which facts to verify.

---

## Step 3 — Ask about fragile things if the files are empty

If `.vibe/debt.md` doesn't exist or has no entries, ask directly:

> "What's the one thing in this project you're most nervous about breaking?"

Use their answer verbatim in Section 5. Don't soften it, don't reframe it. Their instinct is the truth.

---

## Step 4 — Produce the onboarding document

Generate the appropriate version based on Step 1. Use the templates below.

---

## Document Templates

### Developer Version

~~~
# Onboarding — [Project Name]
Welcome. This doc covers everything you need to get productive on day one.
Generated: [today's date]

---

## What This Is
[One paragraph. What the project does, who uses it, current state — prototype /
MVP / in production with X users. Be honest about maturity. Don't oversell it.]

---

## How to Run Locally

1. Clone the repo: `git clone [url]`
2. Copy environment variables: `cp .env.example .env`
   You'll need to fill in:
   - `[VAR_NAME]` — [what it's for] — ask [owner name or "the project owner"] for this
   - `[VAR_NAME]` — [what it's for] — get it from [where: Stripe dashboard, Supabase settings, etc.]
   [List every required var. If you can't find .env.example, infer from the codebase and note that.]
3. Install dependencies: `[npm install / pip install -r requirements.txt / etc.]`
4. [Database setup if needed — e.g. `npx prisma migrate dev` or `python manage.py migrate`]
5. Start the app: `[npm run dev / python manage.py runserver / etc.]`
6. Open: [http://localhost:3000 or equivalent]

If any step requires a secret the project owner hasn't shared yet — that's the blocker.
Don't spend time debugging a startup failure before confirming all env vars are filled in.

---

## How to Deploy

[One paragraph. How code gets to production:]
- Pushing to `main` auto-deploys via [Vercel / Railway / Render / etc.]
- OR: there's a manual deploy step — [describe it]
- Staging environment: [yes, at X / no, everything goes straight to production]

[If you can't determine this: "Deployment process is not documented. Ask the project owner before pushing anything."]

---

## The Stack

[From .vibe/project.md if available; otherwise inferred from codebase — note "[inferred]" if so.]

- Language / Framework: [e.g. Next.js 14, Django 4.2, Rails 7]
- Database: [e.g. PostgreSQL via Supabase, SQLite, PlanetScale]
- Auth: [e.g. NextAuth with Google, Clerk, custom JWT, none]
- Hosting: [e.g. Vercel, Railway, Fly.io, local only]
- Key third-party services: [Stripe, Resend, Cloudinary, etc. — or "none identified"]

---

## What's Fragile

[This is the most important section. Source it from .vibe/debt.md and "Fragile:" fields in
.vibe/sessions.md. If those files are empty, use the project owner's answer from Step 3.
Do not invent fragility you haven't confirmed — but do not soften what you did find.]

The things most likely to break or surprise you:

- [Specific fragile thing — e.g. "Email sending has not been tested in production. It may go to spam or fail silently."]
- [Specific fragile thing — e.g. "The payment flow only covers the happy path. Failed cards are not handled gracefully yet."]
- [Specific fragile thing — e.g. "Auth resets every 24 hours. Users get logged out. This is known and not yet fixed."]

[If nothing was flagged in debt.md or sessions.md, and the project owner said nothing is fragile, write:
"No fragile areas flagged at time of writing. Run /vibe-health after your first session to assess."]

---

## What Not to Touch Yet

[Source from .vibe/.scope if it exists, otherwise from HIGH-risk items in debt.md,
and ask the project owner what they'd be nervous about someone changing.]

Leave these alone until you've read the relevant code and understand it:

- **Auth and payments** — highest risk, changes here can lock users out or break billing
- [Any area listed as HIGH risk in debt.md]
- [Anything the project owner flags as "I don't fully understand this myself"]

These aren't permanent off-limits — they're "understand before you touch" areas.

---

## Suggested First Tasks

Three good starter tasks — small, self-contained, in areas that aren't fragile.
These give you a win in the first session and build familiarity before touching anything critical.

1. [Task — e.g. "Fix the typo on the landing page hero text (src/pages/index.js, line 12)"]
2. [Task — e.g. "Add a missing loading state to the submit button on the signup form"]
3. [Task — e.g. "Improve an error message to be more helpful for users"]

[If the codebase gives no obvious starter tasks, look in this order before falling back to asking:
1. Grep for TODO or FIXME comments in non-fragile files — these are pre-flagged low-stakes tasks
2. Check .vibe/debt.md for items tagged Low risk
3. Check open issues in GitHub (if the repo is linked) for anything labeled "good first issue" or similar
If none of those surface anything concrete, write: "Ask the project owner for a small,
self-contained first task before diving into the main codebase."]

---

## About This Project's Setup

[Include this section only if the project actually uses vibe-skills — check for a `.vibe/` directory before adding it. If `.vibe/` does not exist, omit this section entirely.]

This project uses the vibe-skills toolkit for AI-assisted development.
The `.vibe/` folder holds the project's memory:

- `project.md` — stack and deployment context
- `sessions.md` — log of what was worked on and what was left fragile
- `debt.md` — known shortcuts, with risk levels
- `decisions.md` — architectural choices and why they were made

When working with AI tools on this project, the behavioral baseline is active by default.
~~~

---

### Designer Version

~~~
# Onboarding — [Project Name] (Designer)
Welcome. This doc covers what you need to start working on the frontend.
Generated: [today's date]

---

## What This Is
[One paragraph. What the product does, who uses it, where it's at.]

---

## The Frontend

[From the codebase — identify where frontend code lives:]
- Main pages / views: [e.g. `src/pages/`, `app/`, `templates/`]
- Shared components: [e.g. `src/components/`, `components/`]
- Styles: [e.g. `src/styles/`, Tailwind config at `tailwind.config.js`, CSS modules, etc.]
- Design tokens / colors: [e.g. in `tailwind.config.js` → `theme.colors`, or `src/styles/variables.css`]
- Static assets: [e.g. `public/images/`, `src/assets/`]

---

## How to See Your Changes Locally

1. Clone the repo: `git clone [url]`
2. Copy environment variables: `cp .env.example .env` — ask the project owner to fill these in
3. Install dependencies: `[npm install / etc.]`
4. Start the app: `[npm run dev / etc.]`
5. Open: [http://localhost:3000 or equivalent] — changes to frontend files reload automatically

You shouldn't need a database or backend credentials to work on static UI. If the app won't
start without them, ask the project owner to share the env vars.

---

## What's Fragile in the Frontend

[Source from debt.md and sessions.md as in the developer version, filtered to UI/frontend items.]

---

## What Not to Touch

- Don't modify auth-related UI components without talking to the project owner first
- [Any frontend-adjacent fragile areas from debt.md]
~~~

---

### Non-Technical Collaborator Version

If `.vibe/` files don't exist and the codebase gives no clear picture of what the app does, ask the project owner directly before writing anything:
> "Can you walk me through what the app does and what you'd be most nervous about breaking? I'll write the doc from there."

~~~
# Onboarding — [Project Name]
Welcome. Here's what you need to know to help out.
Generated: [today's date]

---

## What This Is
[One paragraph — what the app does, who uses it, where it stands today.]

---

## Where the App Lives

- **Live app:** [URL]
- **Dashboard (Vercel / Railway / etc.):** [URL — or "ask the project owner for access"]
- **Database (Supabase / etc.):** [URL — or "you probably don't need this"]
- **Analytics:** [if any — or "not set up yet"]

---

## What's Working

[Source from debt.md "Working" items and sessions.md entries. If those files don't exist,
ask the project owner to walk you through the app before writing this section. Don't invent it.]

- [Feature that's solid — e.g. "Users can sign up and log in"]
- [Feature that's solid — e.g. "The main dashboard loads and displays data correctly"]

[If you can't determine this without input: "Ask the project owner to walk you through the app
so you can document what's solid versus what's still rough."]

---

## What Isn't Working Yet

- [From debt.md / sessions.md — e.g. "Email confirmation is not sent yet — users get added but don't receive a welcome email"]
- [From debt.md / sessions.md — e.g. "Mobile layout is not finished on the settings page"]

[If debt.md is empty or missing: ask the project owner what they'd be nervous about you accidentally triggering or breaking.]

---

## How to Give Feedback

[If there's a task tracker or shared doc: point to it.
If not: "Send feedback directly — screenshots help more than descriptions."]
~~~

---

## Step 5 — Show it to the project owner before sharing

Before handing the document to anyone:

> "Before you share this — does it describe the project accurately? Is anything wrong or missing?"

The project owner is the final check. You may have inferred things that are slightly off, and surprises in an onboarding doc cost trust.

---

## Verification Checklist

- [ ] New person's role identified before generating (developer / designer / non-technical)
- [ ] For non-technical path: if .vibe/ files were missing, project owner was asked to walk through the app before writing
- [ ] Local setup instructions mentally tested — would a fresh clone work with these exact steps?
- [ ] Every required env var listed with where to get it — no "fill in your credentials" vagueness
- [ ] "What's Fragile" sourced from debt.md and sessions.md (or directly from the project owner) — not invented
- [ ] "What Not to Touch" is specific — not just "be careful with auth"
- [ ] Project owner reviewed the document before it was shared
- [ ] Document saved to ONBOARDING.md (or the location the project owner specified)
