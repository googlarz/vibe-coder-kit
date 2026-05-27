---
name: vibe-launch
description: Pre-launch checklist — 6 checks before telling real users about your app. Secrets, deployment, core flow, monitoring, user contact, rollback.
---

# vibe-launch

## Overview

`vibe-launch` is the pre-production checklist for solo vibecoders. Run it before sharing your app with real users for the first time — or before any significant public moment: Product Hunt, a social post, sending a link to a client.

The problem it solves: vibecoders often "launch" by pasting a URL into a message before checking if the basics are safe. This skill makes you pause for 10 minutes so you don't spend the next 3 hours putting out fires.

Run it once. Then go ship.

---

## Before you start

Ask the user:

> "Before we run through the checklist — what's the live URL? And who are you about to share it with?"

This frames everything that follows. A link to a friend is different from a Product Hunt post.

---

## The 6 Checks

> Work through each check one at a time. Ask the user to confirm before moving to the next. This is a conversation, not a form — don't present all six checks at once.

Run these in order. Present each as a section. Wait for the user's input where needed. Do not skip any check.

---

### Check 1 — Secrets safe?

This is the only hard blocker. A leaked API key or exposed database password can cost real money or compromise real users within minutes of going public.

**Do all three:**

1. **Check for exposed secrets in the codebase.** Run `/vibe-check`. If vibe-check isn't set up yet, scan manually for common patterns: files containing `sk-`, `AIza`, `AKIA`, `Bearer `, database connection strings with passwords, or anything that looks like `password=`, `secret=`, `api_key=` with a real value next to it.

2. **Confirm `.env` is in `.gitignore`.** Run: `cat .gitignore | grep .env` or ask the user to check. If `.env` is not listed there, add it before doing anything else.

3. **Confirm the git history is clean.** Ask: "Has your `.env` file ever been committed to git by accident?" If yes, the key is already exposed — it must be rotated, not just deleted from the latest commit.

**Result:**
- ✅ **Safe** — no exposed secrets found, `.env` is gitignored, history is clean
- 🚨 **Fix before launching** — leaked secrets found; do not proceed until rotated and removed

If there's a 🚨, stop here. Help the user fix it. Do not continue until Check 1 passes.

---

### Check 2 — Is it actually deployed?

A surprising number of "launches" share a URL that returns a 404, shows a Vercel build error, or still points to `localhost`.

**Ask the user to verify in an incognito/private browser:**

> "Open this URL in a private browser window — not your regular browser where you're logged in. Does it load? What do you see?"

Incognito is important: your normal browser has cached versions and active sessions that can hide broken deployments.

Then ask:

- "Is this using your production environment variables — not your local `.env`?" If they're on Vercel, the env vars need to be set in the Vercel dashboard, not just in the local `.env` file. A common failure: the app deploys but can't connect to anything because the keys are missing.

- If the app uses a database: "Is it pointing at the production database, not a local or test one?"

**Result:**
- ✅ **Live** — URL confirmed working in private browser, production env confirmed
- ⚠️ **Not confirmed** — user couldn't verify, or env variables not checked

If there's a ⚠️, help them resolve it before continuing.

---

### Check 3 — Does the core thing work?

The app might be "live" but broken in ways you haven't noticed because you've been testing the same account for weeks.

**Ask the user:**

> "What's the one thing a new user comes to your app to do? Describe it in one sentence."

Then walk through it together, step by step, as a brand-new user. The user must do this test — you can't access the browser. Guide them:

1. Open the live URL in an incognito window (not logged in, fresh state)
2. If there's signup: try signing up with a fresh email right now
3. Complete the main action from start to finish
4. Check: any blank pages, error messages, or buttons that do nothing?

**Also ask:** "Open it on your phone. Does it look usable on a small screen?" Many vibecoders only test on desktop — a broken mobile layout on launch day is a common surprise.

**Result:**
- ✅ **Core flow works** — new user can sign up and complete the main action; mobile looks usable
- 🚨 **Core flow broken** — this is a launch blocker. Do not share the link until the main thing works. Help the user fix it, or if it's complex, suggest running `/vibe-oops`.
- ⚠️ **Minor issues found** — something non-critical is broken (a secondary page, an edge case). State what it is and ask: "Is this something users will hit on their first visit? If yes, fix it first. If no, you can launch and fix it after."

---

### Check 4 — What happens if it breaks?

This check is awareness, not a blocker. Most solo vibecoders find out their app is down when a user messages them — or they don't find out at all.

**Ask:**

> "If your app goes down at 2am, how will you know?"

Explain the options in plain English:
- **Vercel** has basic deployment status and some uptime visibility in the dashboard — not full alerting, but better than nothing
- **Sentry** (free tier) catches runtime errors and sends you an email when something breaks — for full setup steps, run `/vibe-monitor`
- **UptimeRobot** (free) pings your URL every 5 minutes and emails you if it goes down

If they have none of these, this isn't a blocker — but UptimeRobot takes 2 minutes to set up and is free. Offer to walk them through it:
> "Want to set this up right now? It takes 2 minutes and you'll never find out your app is down from an angry user again."

If yes: **uptimerobot.com** → create free account → "Add New Monitor" → choose "HTTP(s)" → paste the live URL → leave everything else as defaults → "Create Monitor". Done. They'll get an email the moment the URL stops responding.

**Result:**
- ✅ **Has alerting** — some form of error tracking or uptime monitoring is in place
- ⚠️ **No alerting** — not a hard blocker, but: "You'll find out about problems when users tell you, which means things can break silently. Worth setting up before you share widely."

---

### Check 5 — Can you communicate with users?

If something breaks after launch, can you reach the people who signed up?

**Ask:**

> "If you need to tell your users 'the app is down, we're fixing it' — can you do that? Do you have their emails?"

And:

> "If you need to take the app down for an hour to fix something, is there any way to let people know?"

Common answers:
- Email collection at signup: ✅
- A Twitter/X or Instagram account for the project: ✅
- Nothing: ℹ️

This is not a blocker for a first launch. But it becomes important fast once real people are using the app.

**Result:**
- ✅ **Can reach users** — email list, social account, or some communication channel exists
- ℹ️ **No way to reach users** — not a blocker, but worth setting up: "If something breaks, your users will just leave quietly and you won't be able to explain what happened."

---

### Check 6 — What's your rollback plan?

If the first deploy after launch breaks something, can you get back to a working state quickly?

**Ask:**

> "Do you have a recent git commit you could go back to if things went wrong?"

And cover the three common scenarios:

1. **Git checkpoint:** Run `git log --oneline -5` — do the last few commits look like clean checkpoints? If not, make one now: `git add -A && git commit -m "checkpoint before launch"`

2. **Database:** If the app has a database, ask: "Do you have a backup?" For Supabase: Dashboard → Settings → Database → Backups. For Railway/Render: check the dashboard for backup options. For local Postgres: `pg_dump $DATABASE_URL > backup-$(date +%Y%m%d).sql`.

3. **Vercel rollback:** If they're on Vercel, they can roll back instantly — go to the Vercel dashboard, find the previous deployment, click "Redeploy." Takes 60 seconds. Make sure they know this exists.

**Result:**
- ✅ **Can roll back** — git checkpoint exists, Vercel rollback understood
- ⚠️ **No rollback plan** — help them create a git checkpoint before launching; it takes 30 seconds

---

## Final Verdict

After all 6 checks, summarize with one of three verdicts:

### ✅ Ready to launch

All critical checks pass (no 🚨 on secrets, no ⚠️ on deployment or core flow, rollback plan exists).

> "You're clear. Here's what you confirmed:
> - No exposed secrets
> - App is live and responding
> - Core flow works end to end
> - [Note any ℹ️ items as 'things to add later']
>
> Go ship it. You built something real."

---

### ⚠️ Launch with awareness

Minor issues found — nothing critical, but things the user should know about before sharing widely.

List each ⚠️ or ℹ️ item and what the risk is in plain English. Then:

> "You can launch, but go in with eyes open. [List the specific things to watch for.] If any of these bite you in the first 24 hours, come back and we'll fix them."

---

### 🚨 Fix before launching

One or more critical issues found — most likely an exposed secret or the app not actually being live.

> "Not yet. Here's what needs fixing first: [list the blockers]. Once these are resolved, run vibe-launch again — it'll go fast."

Do not soften this. A leaked API key that gets scraped from a public repo within an hour of launch is a real outcome.

---

## Edge cases

**"I just want to share it with one friend to test"**
Still run Check 1 (secrets) and Check 2 (is it live). Skip or abbreviate 3–6. Even one person sharing a link can make a URL public.

**"I've already launched, I'm doing a Product Hunt post"**
Run all 6 checks. A Product Hunt post can send thousands of people to your app in an hour. Check 3 (core flow) is especially important — test it fresh, not from memory.

**"The app doesn't have a database / doesn't have users"**
Skip the database parts of Check 6 and the communication parts of Check 5. Note it explicitly so the user knows you're not forgetting it.

---

## Verification checklist

- [ ] Check 1 passed: no secrets in code, .env is in .gitignore, git history clean
- [ ] Check 2 passed: deployment confirmed working on real device
- [ ] Check 3 passed: core user flow tested end-to-end
- [ ] Check 4 passed: uptime monitor created and alert email set
- [ ] Check 5 passed: contact/support method exists for users
- [ ] Check 6 passed: rollback path confirmed (know how to undo the deploy)
- [ ] Each check presented conversationally — user responded before moving to next
