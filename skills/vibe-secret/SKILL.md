---
name: vibe-secret
description: Emergency response when a secret — API key, password, or token — may have been exposed. Rotate first, investigate second.
---

# vibe-secret

Something sensitive may have been exposed. Move fast — the steps below are in priority order.

The key rule: **rotate first, audit second.** Every minute the old key is still active, someone could be using it. Don't investigate while the door is still open.

---

## Step 1 — Confirm what was exposed

Ask the user these four questions before doing anything:

1. **What kind of secret?** (API key, database password, private token, webhook secret)
2. **Where was it exposed?** (committed to git, pushed to a public GitHub repo, pasted in a chat, shown in a screenshot, left in a public file)
3. **When?** (today, last week, months ago — approximately)
4. **Is the service still active?** (Is this key still connected to a live account?)

If the user isn't sure whether the repo is public: check with them — "Is your GitHub repo set to public or private?" This changes the urgency.

---

## Step 2 — Rotate or revoke the key RIGHT NOW

Do this before anything else. The key must be killed immediately.

Below are instructions for the most common services. Go to the one that matches.

**Stripe:**
Dashboard → Developers → API keys → click "Roll key" next to the exposed key. Copy the new key.

**OpenAI:**
platform.openai.com → API keys → find the exposed key → Delete → Create new key. Copy it.

**GitHub personal access token:**
github.com → Settings → Developer settings → Personal access tokens → Delete the exposed token → Generate new token.

**Supabase:**
Project dashboard → Project Settings → API → click "Rotate" next to the anon or service key. Copy the new one.

**Vercel environment variable:**
Project dashboard → Settings → Environment Variables → find the variable → edit it → replace the value with the new key → Save.

**Resend:**
Dashboard → API Keys → find the exposed key → Delete → Create API Key. Copy the new one.

**SendGrid:**
Settings → API Keys → find the exposed key → click the action menu → Delete → Create API Key. Copy the new one.

**Railway:**
Project → your service → Variables → find the variable containing the exposed value → click to edit → replace the value with the new key → Save.

**Any other service:**
Go to the service's dashboard. Look for "API keys", "Credentials", "Developer settings", or "Security". Find the exposed key and delete or regenerate it. If you can't find it, look for the service name + "rotate API key" in your browser.

---

**After rotating:**
Open your `.env` file and replace the old key with the new one. Test that your app still connects — you don't want to rotate the key and then discover nothing works.

Tell the user: "The old key is dead. No one can use it anymore. The new one is in your `.env`."

---

## Step 3 — Remove it from git history

Important: deleting the file or removing the key in a new commit does **not** erase it from history. Anyone who can access the repo can still see the old commits where the key appeared. "Deleting" it just means it's gone from the current version — the history remembers everything.

**I'll run the git history commands for you — you don't need to understand the git internals.** Just tell me the first 8 characters of the old (rotated) key when I ask.

**First, I'll check if it's actually in the history:**

```bash
git log --all --pickaxe-regex -S 'FIRST8CHARS'
```

I'll replace `FIRST8CHARS` with the first 8 characters of the old key. If nothing comes back, the key was never committed and we can skip this step.

If the fast check finds nothing and I want to be thorough, I'll run the slower full-history search: `git log --all -p | grep -i "FIRST8CHARS"` — this reads every commit's diff and may take a minute on large repositories.

**If it shows up in the history:**

**Option A — if the repo is not public yet (or was never pushed):**

Use `git-filter-repo` to rewrite history and remove the file that contained the secret:

```bash
pip install git-filter-repo
git filter-repo --path .env --invert-paths
```

This rewrites every commit in the repo so `.env` never existed. Powerful and permanent.

Note: `git-filter-repo` is a tool you install once. If `pip` isn't available, try `pip3` or `brew install git-filter-repo`.

**Option B — if the repo is already public:**

History rewriting on a public repo is unreliable — forks and caches mean the old commits may already be out there. In that case, focus on what actually matters: the key you rotated in Step 2 is already dead. That's the fix. Rewriting history on a public repo is cleanup, not safety.

Tell the user honestly: "The old key was visible in your repo history. That's not great, but the key itself is already dead — no one can use it. We can try to clean the history, but we can't guarantee every copy is gone."

---

## Step 4 — Fix the root cause

How did the secret end up somewhere it shouldn't be? Fix that now so it can't happen again.

**Check if `.env` is in `.gitignore`:**

```bash
grep .env .gitignore 2>/dev/null
```

If `.env` doesn't appear in the output (or `.gitignore` doesn't exist), add it now:

```bash
echo ".env" >> .gitignore
```

This tells git to ignore the `.env` file completely — it will never show up as something to commit.

**Check if `.env.example` exists:**

This is a file with the same variable names as `.env` but with placeholder values instead of real secrets. It shows other people (or future you) what environment variables the app needs, without exposing the actual values.

If it doesn't exist, create one. Example:
```
STRIPE_SECRET_KEY=sk_live_YOUR_KEY_HERE
DATABASE_URL=postgresql://user:password@host/dbname
OPENAI_API_KEY=sk-YOUR_KEY_HERE
```

Real values never go in `.env.example`. Only the variable names and placeholder text.

**Check if the secret is hardcoded in a source file:**

Search your code for the first 8 characters of the old key. If you find it in a `.js`, `.ts`, `.py`, or any code file (not `.env`), that's the root cause. Move it to `.env` and reference it in code like this:

```javascript
// Instead of:
const apiKey = "sk_live_abc123..."

// Use:
const apiKey = process.env.STRIPE_SECRET_KEY
```

**Final check:**

Run `git status`. If `.env` appears as a file ready to be committed, stop — your `.gitignore` isn't working. Don't commit until `.env` no longer appears in that list.

---

## Step 5 — Assess what was at risk

Now that the key is dead and the root cause is fixed, take an honest look at the damage.

**How long was it exposed?**

If the secret was in `.env`, check when it first appeared in git history:
```bash
git log --all --follow -p .env | grep -A2 "FIRST8CHARS" | head -20
```

The date on the commit is when it was first exposed.

If the secret was hardcoded in a source file (not `.env`), run:
```bash
git log --all -p -- [filename with secret] | grep -c '^+'
```

Replace `[filename with secret]` with the actual file path (e.g. `lib/stripe.js`). This counts how many commits included that file with changes — the first such commit is when it was first exposed.

**What permissions did the key have?**

- Read-only key: someone could have read your data, not modified it
- Full-access key: someone could have read and changed data
- Admin/service key: someone could have had full control of the account

Higher permissions = more worth investigating.

**Check for unusual activity:**

- **Stripe**: Dashboard → Developers → Logs — look for API calls you didn't make
- **OpenAI**: platform.openai.com → Usage — look for a spike you didn't cause
- **Supabase**: Dashboard → Logs → API — filter by time and look for unexpected queries
- **Database password**: Look at your database for unexpected records, deleted rows, or data you don't recognize

**Honest assessment — say this clearly:**

Give a one-paragraph summary: "The key had [permission level] access and was exposed for approximately [time]. Someone could have [what was possible]. [Signs of unauthorized use / no signs of unauthorized use]."

Don't catastrophize, but don't minimize either. "It was a read-only key exposed for 6 hours with no unusual activity" is very different from "it was a database password with full access exposed for 3 months."

---

## Step 6 — Write it down

Write to `.vibe/bugs.md` so future sessions have context:

```
## [Date] — Secret exposure: [type of key]
**What happened:** [how it was exposed — e.g. "committed .env to public GitHub repo"]
**Root cause:** [why it happened — e.g. ".env was not in .gitignore"]
**Exposure window:** [approximately how long]
**Impact:** [what permissions the key had, any signs of unauthorized use]
**Fix:** Rotated key, added .env to .gitignore, created .env.example
```

---

## Verification checklist

Before considering this resolved:

- [ ] Old key is rotated or revoked — it no longer works
- [ ] New key is in `.env` and the app still connects
- [ ] `.env` is listed in `.gitignore`
- [ ] `git status` does not show `.env` as a file to commit
- [ ] Git history checked — secret removed or acknowledged as already public
- [ ] `.env.example` exists with placeholder values (no real secrets)
- [ ] Root cause fixed — secret is no longer hardcoded in source files
- [ ] Usage logs checked for signs of unauthorized access
- [ ] `.vibe/bugs.md` updated with what happened and the fix
