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
- Check for existing screenshots: `find . -name '*.png' -o -name '*.gif' -o -name '*.jpg' | grep -v node_modules | grep -iE '(screenshot|demo|preview|screen)' | head -10`. If any are found, include them in the README. If none, don't invent placeholder screenshot instructions.

If the project has no `.vibe/` folder, infer stack from the codebase and note what you inferred.

---

## Step 3 — Write the README

Note: The template below assumes a web app with npm. For CLI tools, Python projects, or libraries: adjust the "Quick Start" section to use the appropriate install/run commands (`pip install`, `cargo run`, `go run`, etc.) and omit the browser URL step.

Use this structure for a mixed audience (most common case). Trim sections that don't apply. The `<!-- -->` comments in the template explain how to fill in each section — remove them from the final output.

~~~markdown
# [Project Name]

<!-- One sentence. What it does. Not a mission statement — not "powerful" or "seamless." Example: "A personal reading tracker that syncs with Kindle and sends weekly summaries by email." -->

<!-- 2–3 sentences: what problem it solves, who it's for, current state (live / in development / personal project). -->

<!-- Screenshot or demo link — omit this line entirely if no image exists in the repo or no real URL. -->

## Getting Started

<!-- Include only for user-facing projects. -->
- [Where to access it — production URL if live]
- [How to sign up or get started]
- [One "first thing to try"]

## Running Locally

<!-- Include only for projects with a developer audience. -->

```bash
git clone [url]
cd [project-name]
cp .env.example .env
# Fill in required variables — see Environment Variables below
npm install
npm run dev
```

Open http://localhost:3000

## Environment Variables

<!-- Generate this table from `.env.example` — every variable must appear. If there's no `.env.example`, list any variables inferred from the codebase and note "verify this." -->

| Variable | What it's for | Where to get it |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | Your database host |
| `STRIPE_SECRET_KEY` | Stripe payments | stripe.com → Developers → API keys |

## Built With

<!-- List actual stack from `.vibe/project.md` or `package.json`/`requirements.txt` — e.g. "Next.js 14 with PostgreSQL on Railway", not "modern web stack" -->

## Project Status

<!-- One of: "Live at [url] — actively developed" / "Personal project — used by the author only" / "Early access — expect rough edges" / "Archived — no longer maintained" -->

## License

<!-- Include only if a LICENSE file exists in the repo. -->
[License name] — see LICENSE file.
~~~

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

> "README is written. Want me to also add a CONTRIBUTING.md or a CHANGELOG.md with what's changed in recent versions?"

CONTRIBUTING.md makes sense if: the repo is public, the user has mentioned wanting collaborators, or there are open issues. Skip it for a solo private project. If offering it, say: "I can add a CONTRIBUTING.md with setup instructions, code style notes, and PR guidelines — this is worth having if anyone else will contribute to the project. Want me to draft one based on what I found in the codebase?"

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
