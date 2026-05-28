---
name: vibe-upgrade
description: Update outdated or vulnerable packages one at a time, with a checkpoint before each one and a quick test after.
---

# vibe-upgrade

## Overview

Upgrading packages is not glamorous. It's also one of those things that's easy to put off until it's a problem. The right way to do it is one package at a time — not everything at once.

Running `npm update` or `pip install --upgrade` on everything simultaneously is how you break your app in ways that take hours to untangle. We're not doing that.

---

## Step 1: Detect the ecosystem

Don't ask. Look for:
- `package.json` → Node.js / npm
- `requirements.txt` or `pyproject.toml` → Python
- `Gemfile` → Ruby (note: use `bundle outdated` and `bundle update [gem]`)
- `go.mod` → Go (note: use `go get -u [package]`)

---

## Step 2: Run the audit

**Node.js:**
```
npm audit
npm outdated
```

**Python:**
```
pip list --outdated
```
If `pip-audit` is available: `pip-audit` (gives vulnerability info like npm audit does).

Read the output and translate it. Don't dump raw output at the user. Say:

> "You have [N] packages with known security issues and [M] that are out of date. Here's what actually matters."

Then give them a short, plain-English summary — not the full table. Focus on:
- Severity (critical and high vulnerabilities go first)
- Age (packages that are multiple major versions behind)
- Skip: packages where the only available upgrade is a major version bump that's likely to break things — flag those separately

---

## Step 3: Pick one package to do first

Don't give a list. Pick one and explain why.

Priority order:
1. Any package with a **critical or high severity vulnerability** — name the vulnerability in plain English if npm audit describes it ("this one has a known security issue where someone could inject malicious code through the logger")
2. **Packages far behind** (e.g. 3+ minor versions, or a year+ since last update)
3. **Dev tools** (linters, test runners, TypeScript) — generally safe to upgrade
4. Skip for now: major version upgrades for core packages (React, Next.js, Django, Rails) — these often need careful migration and deserve their own session

Say:

> "Let's start with [package name] — it [reason in one sentence: has a security issue / is two years out of date / is a small upgrade with low risk]. The others can wait."

---

## Step 4: Checkpoint first

Before touching anything:

```
git add -A && git commit -m "checkpoint before upgrading [package]"
```

Tell the user:

> "Saved. If this breaks anything, one command gets us back: `git reset --hard HEAD~1`."

(Explain: "That command moves your code back one step, undoing the upgrade.")

---

## Step 5: Upgrade the one package

**Node.js — minor/patch upgrade (same major version):**
```
npm install [package]@latest
```

If the project uses yarn (`yarn.lock` present): `yarn upgrade [package]@latest`
If the project uses pnpm (`pnpm-lock.yaml` present): `pnpm update [package]`

**Node.js — major version upgrade:**
```
npm install [package]@[specific-version]
```
Don't use `@latest` for major bumps — it can silently jump to a version that breaks your app. Install the specific version you've decided on. Use `npm outdated` to see current vs wanted vs latest before deciding which version to target.

**Python:**
```
pip install --upgrade [package]
```

**Go:**
```
go get [package]@latest
go mod tidy
```
`go mod tidy` updates go.sum to match — always run it after `go get`.

**Ruby:**
```
bundle update [gemname]
```
Don't run `bundle update` without a gem name — that updates everything at once, which is what we're avoiding. Bundler handles the lockfile (`Gemfile.lock`) automatically — no separate lockfile update step needed.

---

## Step 6: Verify

Don't assume it worked. Ask the user to check:

> "Can you start the app and check [the specific feature most likely to be affected by this package]?"

Wait for them to confirm. If the package is a utility (lodash, date-fns, a logger) and there's no obvious UI feature to test: "Can you start the app and make sure it loads without errors?"

---

## Step 7: Commit or revert

**If it works:**

**Node.js:**
```
git add package*.json package-lock.json
git commit -m "upgrade [package] from [old version] to [new version]"
```

**Python — update the lockfile before committing:**
```
pip freeze > requirements.txt
git add requirements.txt
git commit -m "upgrade [package] from [old version] to [new version]"
```
`pip install --upgrade` does not automatically update requirements.txt — this step is required, not optional.

**Go:**
```
git add go.mod go.sum
git commit -m "upgrade [package] from [old version] to [new version]"
```

**Ruby:**
```
git add Gemfile.lock
git commit -m "upgrade [gemname] from [old version] to [new version]"
```

Then: "That worked. Ready to do the next one?"

Wait for their answer. Don't auto-continue.

---

**If it breaks:**

Don't try to fix the breakage now. Revert immediately:

```
git reset --hard HEAD~1
```

Tell the user:

> "That upgrade breaks something, so I've put it back the way it was. I'll make a note of it and we'll skip it for now."

Write to `.vibe/debt.md`:
```
- [Date] [package] [High/Medium/Low] — upgrade to [version] breaks [feature/what errored]. Needs careful migration, not a drop-in upgrade.
```

Then: "Want to try the next one?"

---

## How far to go

After each successful upgrade, ask: "Ready for the next one?"

Stop when:
- The user says stop
- All critical/high severity vulnerabilities are resolved
- You've done 3–5 upgrades in one session (more than that and it gets hard to track what broke what)

At natural stopping points, say:

> "We've handled [N] packages today — the most important ones. The remaining [M] are lower priority and can wait for another session."

---

## A word on major version upgrades

If the audit shows a package needs a major version bump (like React 17 → 18, or Next.js 13 → 14, or Django 3 → 4), don't do it as part of this session. Say:

> "[Package] needs a major version upgrade — that's the kind of change that can break a lot of things and needs its own careful session. I'll note it but we'll skip it for now."

Write to `.vibe/debt.md`:
```
- [Date] [package] [Medium] — currently on v[old], should be on v[new]. Major version upgrade — needs dedicated session with migration guide.
```

Major upgrades deserve their own plan, not a quick `npm install`.

---

## Verification checklist

- [ ] One package at a time — did not upgrade multiple packages in a single step
- [ ] Checkpoint commit exists before each upgrade
- [ ] Tests or manual verification ran after each upgrade
- [ ] Successful upgrades committed with a clear message
- [ ] Failed upgrades reverted with `git reset --hard` before moving on
- [ ] Failed upgrades written to .vibe/debt.md
- [ ] Python: requirements.txt updated with `pip freeze > requirements.txt` after upgrade
- [ ] Major version bumps deferred and written to `.vibe/debt.md`
