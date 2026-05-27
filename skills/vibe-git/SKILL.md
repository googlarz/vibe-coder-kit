---
name: vibe-git
description: Clean git workflow for vibecoders — branch check, meaningful commit message, push with upstream tracking, and optional PR description. Prevents the "update" commit history problem.
---

# vibe-git

Clean git workflow after a session. "update", "fix", and "changes" in git history make it impossible to know what happened when something breaks. This skill produces commits you can actually read six months from now.

## When to use

- After finishing and verifying a feature or fix (after /vibe-test)
- When you want to push to GitHub
- When opening a pull request

---

## Process

### Step 1 — Branch check

```bash
git branch --show-current
```

If the command fails or shows no output: **stop**. This project doesn't have git set up yet. Say:
> "This project doesn't have git set up yet. Want me to initialize it? Takes one command."

If yes: check for `.env` files first. If any exist, ensure `.gitignore` includes `.env` before the first add — initial commits are the most common place secrets get accidentally committed. Then: `git init && git add -A && git commit -m "initial commit"`, and continue from Step 2.

If on `main` or `master`: **stop**. Do not commit directly to main.

```bash
git checkout -b feature/[short-description]
```

Name the branch after what you built: `feature/email-settings-page`, `fix/login-redirect-loop`, `chore/update-dependencies`. Short, descriptive, kebab-case — typically 2-4 words. The goal is recognizability, not a word count. No "update" or "changes."

If on a feature branch: confirm it's the right one. If it's been open for more than a week with no commits, ask whether this should be a new branch instead.

### Step 2 — Review what's changing

```bash
git diff --stat
git status
```

Show the user what's staged and unstaged. For each changed file, translate it to user-facing terms — not "modified src/auth/login.js" but "login page behavior."

Check for things that should never be committed:
- `.env` files
- `node_modules/`
- `*.log` files
- Any file containing a real password or API key

If any of those are present, stop and address them before proceeding. If `.env` isn't in `.gitignore`, add it now.

### Step 3 — Write the commit message

Commit messages follow this format:

```
type(scope): what changed, in plain English

[optional: one sentence on why, if not obvious]
```

**Types:**
- `feat` — something new that users can see or do
- `fix` — something broken that now works
- `refactor` — code reorganization, nothing visible changed
- `chore` — dependencies, config, tooling
- `docs` — documentation only

**Scope** — the area of the app in one word: `auth`, `settings`, `payments`, `dashboard`, `api`.

**The message** — imperative tense, plain English, under 72 characters:
- ✅ `feat(settings): add email change form with confirmation step`
- ✅ `fix(auth): redirect to login when session expires instead of crashing`
- ❌ `update settings`
- ❌ `fixed the bug`
- ❌ `changes`

Draft the message and show it to the user before committing. If they want to adjust it, do so.

If `git status` shows changes across unrelated concerns (e.g., a bug fix AND a dependency update AND a config change): split into separate commits. Run `git add [specific-files]` for each logical group and commit them separately — one commit per concern.

### Step 4 — Checkpoint (if not already done)

If there's no recent checkpoint commit for this session, create one now:

```bash
git add -A
git commit -m "[drafted message]"
```

Always unstage `.env` after `git add -A` — even if you think it's in `.gitignore`, this is a safe no-op when it's not staged:
```bash
git add -A
git restore --staged .env 2>/dev/null
git status  # verify .env is not staged
```

### Step 5 — Push

```bash
git push -u origin [branch-name]
```

This uploads your code to GitHub. (The `-u` flag means future pushes from this branch work with just `git push` — no need to repeat the full command.)

If the push fails because the remote branch has changes: **do not force push**. Explain what diverged and offer:
1. Pull and merge: `git pull origin [branch]`
2. Pull and rebase: `git pull --rebase origin [branch]`

Never suggest `--force` unless explicitly asked and the consequences are explained.

### Step 6 — Pull request (if pushing to a shared repo or main branch)

Create a PR if: (a) this branch will be merged into main by someone else, or (b) you want a review before merging. If you're the only developer and you're merging immediately, a PR is optional — `git merge` and push directly.

If this branch should become a PR, draft the description:

```
## What changed
[2-3 bullets — user-facing changes, not file names]

## How to test
[The happy path steps from /vibe-test, or a short equivalent]

## What's not included
[Anything deliberately left out of this PR]
```

Ask: "Want me to open the PR now, or just prepare the description?"

If yes and `gh` is available:
```bash
gh pr create --title "[commit message]" --body "[description]"
```

---

## Verification checklist

- [ ] Not on main/master
- [ ] No `.env` or secrets in the staged files
- [ ] Commit message uses a valid type, has a scope, and describes what changed in plain English
- [ ] Code uploaded to GitHub successfully
- [ ] If PR: description has what changed, how to test, and what's not included
