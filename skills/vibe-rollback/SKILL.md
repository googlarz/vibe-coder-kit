---
name: vibe-rollback
description: Something broke in production right now — undo the last deployment and get users back online before debugging anything.
---

# vibe-rollback

## Overview

Production is broken. Users are seeing errors, the site is down, or something is clearly wrong.

This is not the time to debug. The priority is getting users back online first. We fix *what* went wrong after the app is working again.

---

## Step 1: Detect the platform — don't ask yet

Look silently for these files in the project:

- `vercel.json` or `.vercel/` folder → **Vercel**
- `railway.toml` or `railway.json` → **Railway**
- `fly.toml` → **Fly.io**
- `render.yaml` or `render.yml` → **Render**
- `netlify.toml` → **Netlify**

If found: say "I can see this is deployed on [platform]. Here's how to roll back right now."

If nothing found: ask one question:

> "Where is your app deployed? (Vercel, Railway, Render, Fly.io, Netlify, or somewhere else?)"

---

## Step 2: Platform-specific rollback instructions

Give exact steps — not concepts. Tell them where to click.

---

### Vercel

> "Go to your Vercel dashboard (vercel.com) → click your project → click the **Deployments** tab. You'll see a list of recent deployments. Find the last one with a green **'Ready'** badge that was there *before* today's change. Click the three dots (...) on the right → **Redeploy**. Takes about 60 seconds."

If they can't tell which deployment was good: "Look at the timestamps. You want the most recent 'Ready' one before the time things broke."

---

### Railway

> "Go to your Railway project (railway.app) → click your service → click the **Deployments** tab. Find the most recent successful deployment before the broken one — it'll have a green checkmark. Click the three dots (...) → **Rollback**. Takes 30–60 seconds."

---

### Fly.io

Two options — give both:

> "You can do this from the Fly.io dashboard: go to fly.io → your app → **Releases** tab → find the last healthy release → click **Rollback to this version**."
>
> Or from the terminal — run this to see your recent releases:
> ```
> fly releases list
> ```
> The output shows version numbers like `v12`, `v11`, `v10`. Copy the version number from the row labeled `deployed` — that's your current version. The one above it is what you're rolling back to:
> ```
> fly deploy --image <image-id-from-that-row>
> ```
> Replace `<image-id-from-that-row>` with the image ID shown in that version's row.

---

### Render

> "Go to your Render dashboard (dashboard.render.com) → click your service → click the **Deploys** tab. You'll see a list of deploys. Find the last successful one before the broken deploy → click **'Rollback to this deploy'**. It'll ask you to confirm." *(Render's UI changes occasionally — look for 'Deploys' or 'Deployments' in the left sidebar if this doesn't match)*

---

### Netlify

> "Go to your Netlify dashboard (app.netlify.com) → click your site → click the **Deploys** tab. Find the last successful deploy before the broken one — look for a green 'Published' badge. Click it → then click **'Publish deploy'** at the top. Confirms in about 30 seconds."

---

### No platform / self-hosted

Run:
```
git log --oneline -5
```

Show the user the list. Say:

> "Here are your last 5 commits. Tell me which one was the last working version and I'll revert to it."

Once they identify it, use `git revert HEAD` (this creates a new commit that undoes the last one — your history is preserved, not erased) to undo the last commit safely, or use `git reset --hard [commit-id]` if multiple commits need undoing — but say explicitly: "This will permanently remove the commits after [ID]. Your local code will change. Are you sure?"

---

## Step 3: While it's deploying

Don't leave them watching a blank screen. Say:

> "While that's deploying — watch the status in your [platform] dashboard. When it shows '[Ready / Live / Deployed]', reload your app in a private/incognito browser window and confirm it's actually working, not just showing cached content."

Tell them what the success indicator looks like on their platform:
- Vercel: "Ready" badge in green
- Railway: green checkmark on the deployment
- Fly.io: release shows "succeeded"
- Render: "Live" status on the service
- Netlify: "Published" badge on the deploy

---

## Step 4: After it's confirmed working

Slow down. Two things before doing anything else:

**1. Save the broken state somewhere.**

> "Before we touch anything — let me create a branch with the broken code so it's not lost. That way we can look at what went wrong without it being in your main code."

```
git checkout -b broken-$(date +%Y-%m-%d)
git push origin broken-$(date +%Y-%m-%d)
```

This creates a branch like `broken-2026-05-27` — you can always come back to it if you need to investigate what went wrong.

Or if they're not comfortable with branches: "I'll just make a note of what the last commit was so we can look at it later."

**2. Write one line to `.vibe/sessions.md`:**
```
## [Date] — rollback: [what broke, one line]
- Rolled back to: [deployment / commit]
- Broken state preserved: broken-[date] branch
- Still needs: root cause investigation
```

Then ask — one question:

> "The app is back up. Want to dig into what caused this now, or come back to it in a fresh session?"

---

## Step 5: What comes next

If now → "Good call. Let's go slowly — this is production. I'd suggest running this in a test environment first." Then suggest `/vibe-oops` for the diagnosis.

If later → "Makes sense. When you're ready, start a new session and I'll walk through what happened." Write the broken branch name to `.vibe/sessions.md` so the next session can find it.

---

## If the rollback itself fails

Say this immediately — don't try to debug the rollback:

> "The rollback didn't work. This needs a developer right now — not because you did anything wrong, but because the situation is outside what's safe to handle without deeper access. Let me write the handoff document."

Then run `/vibe-handoff` in emergency mode. The document should include:
- What broke (as described by the user)
- What rollback was attempted and what happened
- Current production status
- The platform and any access details the developer will need

---

## Verification checklist

- [ ] Platform detected before giving any rollback steps
- [ ] Rollback completed — deployment dashboard shows previous version as live
- [ ] Verified in incognito/private browser that the app actually loads for visitors
- [ ] Broken state preserved on a separate branch (not deleted)
- [ ] .vibe/sessions.md updated: what broke, what was rolled back to, what to investigate next
- [ ] If rollback itself failed: escalated to /vibe-handoff
