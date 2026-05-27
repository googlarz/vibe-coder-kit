---
name: vibe-log
description: Paste an error from Vercel, Railway, or your server and I'll tell you what it means and exactly what to do.
---

## Overview

Deployment logs are written for developers. The error messages assume you know what "ECONNREFUSED" means, or why a "502 Bad Gateway" happens. You don't need to know any of that.

Paste the error, and I'll translate it.

---

## Step 1: Get the log

Ask — just this, nothing more:

> "Paste the error or log output and I'll tell you what it means."

Wait. Don't prompt for context, don't ask what they were doing. The log usually contains everything needed.

---

## Step 2: Read context before responding

If the log references a file path that exists in the project — like `Error in lib/db.js line 42` or `Cannot find module './utils/auth'` — open and read that file before responding. A one-line translation without looking at the code is often wrong.

---

## Step 3: Translate — two sentences

Lead with the plain-English explanation before anything else. Two sentences:

1. **What happened** — in terms of what the app was trying to do, not the technical mechanism.
   - "Your app tried to connect to the database and got refused."
   - "Your app is looking for a file that doesn't exist."
   - "The build failed because a package it needs isn't installed."

2. **Where** — if you can identify the location.
   - "The error is coming from `lib/db.js` where it opens the database connection."
   - "The build is failing at the `npm install` step, before your code even runs."
   - "This is happening when a user tries to log in."

Don't lead with the fix. Understand first, fix second.

---

## Step 4: One concrete next step

Specific, not generic. Name the file, the setting, the dashboard location.

Not this: "Check your database connection."

This: "Check that `DATABASE_URL` in your `.env` file matches the connection string in your Supabase dashboard — go to Settings → Database → Connection string → URI. They need to match exactly."

---

## Common error patterns — translate these on sight

**`ECONNREFUSED`**
Your app is trying to reach a server (database, Redis, an external API) and it's refusing the connection — nothing is listening there. Either the service isn't running, or the URL/port is wrong. Check the service is up and the URL in your `.env` is correct.

**`ENOTFOUND [hostname]`**
The hostname in your URL doesn't exist. Either there's a typo in the URL, or you're pointing at the wrong environment variable. Double-check the URL character by character.

**`Cannot find module '[path]'`**
A package isn't installed, or the import path has a typo. If it's a package name (like `cannot find module 'express'`): run `npm install`. If it's a relative path (like `cannot find module './utils/helpers'`): the file doesn't exist at that location.

**`relation "[table]" does not exist`**
A database table your app expects isn't there. Your database migration hasn't run — or ran in the wrong environment. Check whether the migration was applied to the production database, not just your local one.

**`invalid input syntax for type uuid`**
Something is passing an ID in the wrong format. Usually a string like `"123"` where a UUID like `"a1b2c3d4-..."` is expected. Look at what's being passed as an ID in the function the error points to.

**`JWT expired` / `invalid signature`**
A user's login token has expired or doesn't match your secret key. Usually means `JWT_SECRET` in your production environment is different from the one that signed the token, or is missing entirely. Check that `JWT_SECRET` is set correctly in your deployment platform's environment variables.

**`Cannot find module` in build output**
A dependency is missing from `package.json`. Run `npm install [package-name] --save` locally, then push again.

**`Function Timeout`**
A serverless function (on Vercel, Netlify, etc.) took longer than the platform allows — usually 10 seconds. Something is slow: a database query, an external API call, or an infinite loop. Look at what that function does and what might be taking a long time.

**`502 Bad Gateway`**
The platform got a response of nothing from your app — your app crashed before it could respond. The 502 is the symptom, not the cause. Look at the lines in the log *before* the 502 for the real error.

**`Module not found: Error: Can't resolve '[package]'`** (build error)
Package isn't in `package.json`. Run `npm install [package] --save` locally and push.

**`Heap out of memory`** / `JavaScript heap out of memory`
Your app is running out of RAM. Usually caused by a large file being loaded entirely into memory, a loop creating too many objects, or a memory leak. Look at what the function is doing with data — is it loading an entire database table? Processing a huge file?

---

## Step 5: Where to find more context

If the error came from a deployment platform, tell the user where the full picture is:

- **Vercel:** "More detail is in your Vercel dashboard → Deployments → [latest deployment] → Build Logs (for build errors) or Functions (for runtime errors)."
- **Railway:** "Check your Railway project → click the service → Deployments → click the failed deployment → View Logs."
- **Render:** "In your Render dashboard → your service → Logs tab. Filter to 'Error' level."
- **Fly.io:** Run `fly logs` in your terminal to stream live logs.
- **Netlify:** "Go to your Netlify site → Deploys → click the failed deploy → Deploy log."

---

## When the error isn't in the list above

Read it carefully and translate it literally. What object does it mention? What operation was it trying to do? Where in the call stack?

If you genuinely can't identify what's happening, say: "I'm not sure what's causing this — let me look at the relevant file." Then look. Don't translate blind.

If you look and still can't identify it: "This one's complex enough that I'd recommend getting a developer to look at the full context." Then run `/vibe-handoff`.
