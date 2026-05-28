---
name: vibe-env
description: Check that secrets aren't exposed, environment variables are consistent, and nothing will break on deploy.
---

# vibe-env

## Overview

Environment problems are the sneakiest kind — everything works locally, then breaks the moment you deploy. Or worse: it deploys fine and you don't realize your database password is visible to anyone on the internet.

Run this before pushing, before deploying, or any time something mysteriously works on your machine but breaks in production.

I'll run five checks silently, then tell you what I found.

---

## Step 1: Detect the stack

Don't ask the user. Look for:
- `package.json` → Node.js / JavaScript
- `requirements.txt` or `pyproject.toml` → Python
- `Gemfile` → Ruby
- `go.mod` → Go
- `composer.json` → PHP

This tells me which environment variable patterns to grep for. If I can't detect the stack, I'll ask once.

---

## Check 1: Is .env committed to git?

Run:
```
git ls-files .env
```

**If no .env file exists at all** (e.g. Vercel-only projects where all env vars live in the platform dashboard): note this explicitly and check the deployment platform dashboard instead. List what's configured there (variable names, not values). Continue to Check 2.

**If this shows anything:** Stop. Say this before anything else:

> "Your .env file is being tracked by git. That means your database password, API keys, and any other secrets in it are visible to anyone who can see your GitHub repository — and they're in your git history permanently, even if you delete the file later. We need to fix this right now before anything else."

Then:
1. Add `.env` to `.gitignore`
2. Run `git rm --cached .env` to remove it from tracking (this doesn't delete the file, just stops git from watching it)
3. Commit: `git commit -m "stop tracking .env — secrets should never be in git"`
4. Tell the user: "The file is still on your computer — I only removed it from git's memory. But if this repository was ever pushed to GitHub while .env was tracked, the secrets are already in the history. If you have real production keys in there, you should rotate them (generate new ones and update your deployment platform)."

Do not continue to the other checks until this is resolved.

---

## Check 2: Does .env.example exist?

Check if `.env.example` exists in the project root.

**If it doesn't exist:**

> "There's no .env.example file. That's the file that tells anyone setting up this project (including future-you on a new computer) which environment variables they need. Want me to create one from your .env with all the values blanked out?"

If yes: create `.env.example` by copying `.env` and replacing every value with a placeholder like `your_value_here`. Don't expose the actual values.

**If it exists:** move on.

---

## Check 3: Variables in code but missing from .env.example

Grep the codebase for environment variable access patterns based on the detected stack:

- Node.js: `process.env.`
- Python: `os.environ[`, `os.getenv(`, `env[`
- Ruby: `ENV[`

Extract the variable names. Compare against `.env.example`.

**If any variable appears in code but not in .env.example:**

> "I found [N] variables your code uses that aren't documented in .env.example: [list]. If someone clones this project without knowing about these, their app will break silently. Want me to add them?"

---

## Check 4: Variables in .env.example but missing from local .env

Compare `.env.example` against the local `.env`.

**If any variable is in .env.example but not in local .env:**

> "Your .env is missing [variable]. It's in .env.example, which means it's probably needed. If you don't have a value for it, that might be why something isn't working locally."

---

## Check 5: Hardcoded secrets in source files

Grep for patterns that look like real credentials embedded directly in code:

- `sk_live_` (Stripe live key)
- `sk_test_` (Stripe test key — still worth flagging)
- `sk-` (OpenAI API keys)
- `AIza` (Google API keys)
- `xox[bp]-` (Slack tokens)
- `ghp_` or `github_pat_` (GitHub tokens)
- `postgres://` followed by a host that isn't `localhost` or `127.0.0.1` (non-local database URLs with credentials — grep for `DATABASE_URL` and flag if the value contains a domain name other than `localhost` or `127.0.0.1`)
- `Bearer [A-Za-z0-9+/]{20,}` (long Bearer tokens)
- `api_key\s*=\s*["'][^"']{10,}` (variable assignments that look like real keys)
- `AKIA[0-9A-Z]{16}` (AWS access keys)

For each match, open the file and look at the line in context before flagging — don't cry wolf on example strings or comments. A false positive looks like: a variable name containing the word 'key' with no value, a comment mentioning API keys, or an example value like `your-api-key-here`. A real finding looks like: a string that starts with `sk-`, `AKIA`, or matches the format of a real key from a known service. When in doubt, flag it.

**If anything looks like a real credential:**

> "I found something that looks like a hardcoded [type of secret] in [file]. Hardcoding secrets in your code means they get committed to git and are visible to anyone who can see the repo. Let me help you move it to .env instead."

---

## Summary verdict

After all five checks, give one of three verdicts:

**All clear:**
> "All clear — your environment setup looks clean. Secrets are out of git, .env.example is up to date, and I didn't find anything hardcoded."

**A few things to tighten up:**
> "A few things to tighten up:" + list each issue with a one-line fix. "None of these are blocking, but they're worth cleaning up before you share this project."

**Something serious:**
> "Found something I want to flag before we go further: [specific issue]. This one's worth fixing now, not later."

---

## Write to .vibe/gotchas.md

If any check surfaced a surprise — a library that uses an unexpected env var name, a platform that requires a variable you wouldn't have guessed — write it down:

```
## [Date] — env: [short description]
**The surprise:** [what it does unexpectedly]
**Workaround:** [how to handle it]
```

---

## Verification checklist

- [ ] Check 1 passed: .env is not committed to git (or no .env exists and platform dashboard vars noted)
- [ ] Check 2 passed: .env.example exists
- [ ] Check 3 passed: no variables used in code are missing from .env.example
- [ ] Check 4 passed: no variables in .env.example are missing from local .env
- [ ] Check 5 passed: no hardcoded secrets found in source files
- [ ] Any surprises written to .vibe/gotchas.md
