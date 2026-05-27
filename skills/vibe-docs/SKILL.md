---
name: vibe-docs
description: Write or update the project README — what the project is, how to run it, and how to use it.
---

# vibe-docs

Writes the public-facing README for the project. Run this before making a repo public, before sharing a project link, or when the README is still the placeholder that the framework put there.

This is not vibe-handoff (emergency developer escalation) and not vibe-onboard (first-hour guide for a new collaborator). This is the README — the document anyone sees when they land on the project.

---

## Step 1 — Ask who this is for

One question before starting:

> "Who's the main audience — people who might use the app, developers who might contribute, or both?"

- **Users**: what it does, how to get started, screenshots if available
- **Developers**: setup instructions, environment variables, architecture notes
- **Both** (most common): user section first, developer section after

Don't start writing until you have an answer.

---

## Step 2 — Read what exists

Read these silently — don't ask the user:

- `.vibe/project.md` — project name, stack, deployment platform, current state
- `.vibe/sessions.md` — recent work, to understand what's actually built
- `package.json` or `requirements.txt` — exact stack, version, scripts
- `.env.example` — every environment variable that needs to be documented
- Any existing `README.md` — preserve anything accurate, replace what's stale. If an existing README has content you can't verify (a feature you haven't confirmed exists, a setup step you can't trace to current code): keep it but add `<!-- unverified — check this is still accurate -->` as a comment. Don't delete content you're unsure about — a developer would rather see an unverified note than find a missing section.
- `CLAUDE.md` if it has project context
- Check for screenshots: `public/`, `images/`, `docs/`, `assets/` folders

If the project has no `.vibe/` folder, infer stack from the codebase and note what you inferred.

---

## Step 3 — Write the README

Use this structure for a mixed audience (most common case). Trim sections that don't apply.

Each section below shows **what to write** followed by the template content. The template content is what goes into the README file — the instruction text above it is for you.

**What to write:** The project name as an H1, followed by a one-sentence description. Not a mission statement. Not "powerful" or "seamless." Just what it does.

```markdown
<!-- README template section — write this to the file -->
# [Project Name]

[One sentence. What it does.]
```

> Example: "A personal reading tracker that syncs with Kindle and sends weekly summaries by email."

**What to write:** A 2–3 sentence description: what problem it solves, who it's for, current state (live / in development / personal project). Then a screenshot or demo link — only if there's an actual image in the repo or a real URL. Don't add a placeholder.

```markdown
<!-- README template section — write this to the file -->
[2–3 sentence description: what problem it solves, who it's for, current state.]

[Screenshot or demo link — omit this line if no image exists in the repo]
```

---

**What to write:** Getting Started section — for user-facing projects only.

```markdown
<!-- README template section — write this to the file -->
## Getting Started

- [Where to access it — production URL if live]
- [How to sign up or get started]
- [One "first thing to try"]
```

---

**What to write:** Running Locally section — for projects with a developer audience.

```markdown
<!-- README template section — write this to the file -->
## Running Locally

​```bash
git clone [url]
cd [project-name]
cp .env.example .env
# Fill in required variables — see Environment Variables below
npm install
npm run dev
​```

Open http://localhost:3000

## Environment Variables

| Variable | What it's for | Where to get it |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | Your database host |
| `STRIPE_SECRET_KEY` | Stripe payments | stripe.com → Developers → API keys |
```

Generate the environment variables table from `.env.example` — every variable should appear here. If there's no `.env.example`, say so and list any variables you can infer from the codebase.

---

**What to write:** Stack and project status. Be specific about the stack — from `.vibe/project.md` or inferred from `package.json` / `requirements.txt`. Be honest about status.

```markdown
<!-- README template section — write this to the file -->
## Built With

[List actual stack — e.g. "Next.js 14 with PostgreSQL on Railway", not "modern web stack"]

## Project Status

[One of: "Live at [url] — actively developed" / "Personal project — used by the author only" / "Early access — expect rough edges" / "Archived — no longer maintained"]
```

---

**What to write:** License — only if a LICENSE file exists in the repo.

```markdown
<!-- README template section — write this to the file -->
## License

[License name] — see LICENSE file.
```

---

## Step 4 — What makes a bad README

Avoid these before saving:

- **Vague opening line**: "A powerful tool for managing your workflow." What workflow? What does it do?
- **Developer's story**: three paragraphs on why they built it. Cut it — users don't care.
- **Skipped setup steps**: every "obvious" step must be written out. A fresh clone means a fresh machine.
- **Marketing language**: "blazing fast", "delightful", "seamless". Say what it does, not how great it is.
- **Outdated screenshots**: if they don't show the current UI, remove them.
- **Missing project status**: readers can't tell if this is live, abandoned, or in progress. Say so.
- **Undocumented env vars**: if `.env.example` has 8 variables and the README documents 3, the other 5 will break anyone who tries to run it.

---

## Step 5 — Verify before saving

Before writing the file, check:

- Stack list matches what's actually in `package.json` or `requirements.txt`
- Every variable in `.env.example` has a row in the Environment Variables table
- The setup commands trace through a fresh clone — no assumed steps
- The production URL is real (from `.vibe/project.md` or confirmed by the user)
- Any screenshots exist in the repo and show the current UI
- Project status is honest

If anything can't be confirmed, note it in the README with "(verify this)" rather than inventing it.

---

## Step 6 — Save and offer extras

Default save location: `README.md` in the project root. If one already exists, replace it.

After saving:

> "README is written. Want me to also add a CONTRIBUTING.md with how to submit changes, or a CHANGELOG.md with what's changed in recent versions?"

Only offer these if they'd be relevant — a solo personal project probably doesn't need a CONTRIBUTING guide.

If creating a CHANGELOG.md, use this format (Keep a Changelog style) so the output is consistent:

```markdown
## [Unreleased]
### Added
- [Feature or change]

## [1.0.0] — YYYY-MM-DD
### Added
- Initial release
```

---

## Tone in the README

- First sentence describes the project, not the developer's feelings about it
- Active voice: "Tracks your reading" not "Reading is tracked"
- Specific: "Next.js 14 with PostgreSQL on Railway" not "modern web stack"
- Honest about status — "early access, expect rough edges" if it isn't polished
- Short paragraphs — if a section is getting long, it belongs in separate docs

---

## Verification checklist

- [ ] Asked about audience before writing (users / developers / both)
- [ ] README sourced from actual project files — nothing invented
- [ ] Every variable in `.env.example` is documented in the README
- [ ] Setup instructions trace through a fresh clone — no skipped steps
- [ ] Project status is honest (live / in development / personal / archived)
- [ ] No marketing language — describes what it does, not how great it is
- [ ] Screenshots included only if they exist in the repo and show current UI
- [ ] Saved to `README.md` at the project root
