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

Run both commands:

```bash
# All commits from the last 24 hours with file-level details
git log --oneline --stat --since="1 day ago" 2>/dev/null

# Files changed but not yet committed
git diff --stat 2>/dev/null
```

Use both. The `--stat` flag is important — without it, `git log` lists commit SHAs but not which files changed, making it impossible to know what the session actually touched. The second command captures work still in progress. If a session spans multiple days, extend the `--since` window to match.

If git log returns nothing (fresh repo, no commits yet, or git not initialized): describe what was worked on based on what you can see in the current conversation. Note: "Git history wasn't available — this summary is based on the session conversation."

Also check `.vibe/sessions.md` — if today's session entry exists, it has useful context.

### Step 2 — Translate file changes into plain English

Before writing the summary, map what changed to what it means for the user. Do not describe files — describe features and areas.

| If these files changed | Write this |
|---|---|
| `auth.js`, `login.js`, `session.js`, `middleware.js` | "The login system was updated" |
| `stripe.js`, `checkout.js`, `payment.js`, `orders.js` | "The payment flow was updated" |
| `api/users.js`, `routes/profile.js`, `profile.ts` | "The profile page was updated" |
| Any page or component file | "The [page name] page was updated" |
| `.env.example`, `config.js`, `settings.ts` | Put in Under the Hood: "Configuration was updated" |
| `package.json`, `requirements.txt`, `*.lock` | Put in Under the Hood: "New packages were added" |
| `*.test.js`, `*.spec.ts`, `*.test.ts` | Omit — tests aren't user-facing |
| CSS, style, theme files | "The visual design was adjusted" |

If multiple files changed in the same area, write **one bullet** for the area — not one bullet per file.

### Step 3 — Produce the plain-English summary

Before writing the Watch sentence, scan the last 3–5 entries in `.vibe/sessions.md`. If the same area appears in 2 or more prior "Fragile:" entries, note this in the Watch sentence and suggest `/vibe-health`.

Write exactly three sentences. No more. No headers, no bullet points, no "Here's a summary of..." opener.

**Sentence 1 — Built:** What users can now do that they couldn't before.
> "We added [X] — [what it lets the user do in plain English]."

**Sentence 2 — Try:** One specific action to verify right now, with the expected result.
> "Try [exact action] — you should see [expected result]."

**Sentence 3 — Watch:** One thing to keep an eye on. If nothing is fragile or untested, say so.
> "Keep an eye on [specific concern]." — or — "Nothing fragile — this session was clean."

If the Watch sentence surfaces a recurring pattern (same area has been fragile multiple sessions in a row), suggest: "This has come up before — might be worth a `/vibe-health` check before the next big session."

**Note on spoken vs. written format:** What you say in Step 3 (three plain sentences) and what you write to sessions.md in Step 4 (structured `- Changed:`, `- Added:`, `- Fragile:`, `- Test manually:` blocks) are intentionally different. The spoken version is conversational — it's for the person in the session. The written version is structured — it's for future sessions to load as context. Don't conflate them.

If there were multiple changes, still write one sentence per slot. Pick the most important thing for each. "We added email notifications and fixed the login timeout" is fine — don't split into sub-bullets.

If there were only invisible changes (config, deps, security):
> "Under the hood we [what changed]. Try [any visible side-effect to verify]. Nothing fragile — this session was clean."

**The goal:** someone who wasn't in the session reads three sentences and knows exactly what happened, what to click, and what to watch. If they need more, they'll ask.

### Step 4 — Update vibe-brain

After producing the summary, write it to `.vibe/sessions.md` if not already written this session.

**Prepend to the top of the file** (newest entry first) — do not append to the bottom. The session-start hook reads the first entries; appending means the next session loads the oldest history instead of the most recent.

If today's `## YYYY-MM-DD` entry already exists (vibe-scope or vibe-think ran earlier), add this block under the existing header rather than creating a duplicate.

```
## [YYYY-MM-DD] — [one-line summary]
- Changed: [file list]
- Added: [features]
- Fragile: [concerns from "Watch out for" above]
- Test manually: [from "Test these manually" above]
```

### Step 5 — Save point

If there are unstaged changes, offer:
> "Want me to save a checkpoint of this work before you go? Takes 10 seconds."

If yes: `git add -A && git commit -m "session: [one-line summary from Step 3]"`

## Language rules

- Write as if explaining to someone who has never written code
- "We added a new page" not "Created route handler for /settings"
- "The button now does X" not "Implemented onClick handler"
- Be honest in "Watch out for" — don't sanitize real risks

## Verification

After running vibe-explain:
- [ ] Summary is exactly three sentences — no more, no headers, no bullets
- [ ] The summary could be read by someone who wasn't in the session and they'd understand what changed
- [ ] "Try" sentence describes a specific action with an expected result — specific enough that someone could verify it on their own after reading the summary
- [ ] `.vibe/sessions.md` has today's entry
- [ ] Any risky or untested areas are named in "Watch"
