---
name: vibe-check
description: Pre-push security scan with plain-English explanations. Runs vibe-safe if installed, explains every finding, gives a clear verdict.
---

# vibe-check

Pre-push security and sanity check for solo vibecoders. Translates technical security findings into plain English so you know exactly what's at risk and what to do.

## Overview

Before you push code to GitHub, run vibe-check. It scans for the problems that can get you hacked, expose your users' data, or rack up surprise cloud bills — and it tells you what each problem means in plain language.

vibe-check wraps `vibe-safe` if it's installed. If not, it runs its own basic scan. Either way, every finding comes with:
- What the problem is
- What happens to you or your users if someone exploits it
- One concrete step to fix it

## Process

### Step 1 — Detect what's available

Check for vibe-safe in this order:
1. `~/.claude/skills/vibe-safe/hooks/pre-commit` (standard install path)
2. `vibe-safe` command on PATH
3. `./vibe-safe.sh` in the project root

If none found, proceed to inline checks. To install vibe-safe:
```bash
git clone https://github.com/googlarz/vibe-safe ~/.claude/skills/vibe-safe
```

### Step 2 — Run the scan

**If vibe-safe is available:** Run `bash ~/.claude/skills/vibe-safe/hooks/pre-commit` (or wherever it was found). Capture both the output and the exit code.

Parse the output:
- `vibe-safe: all N checks passed -- clear` (exit 0) → show as `✅ vibe-safe: all N checks passed — nothing to fix`
- Lines matching `vibe-safe: [description]` (exit 0) → warnings; translate each through the guide below
- Any output + exit code 1 → STOP findings; translate each and mark the run as 🚨

For each `vibe-safe: [description]` line, strip the `vibe-safe: ` prefix and match against the translation guide. The description IS the issue — your job is to add the RISK and FIX for it. Use the vibe-safe translation table first, then fall back to the general table for anything not listed.

**If vibe-safe is not available:** Run the inline checks (see section below), then translate each finding.

### Step 3 — .gitignore check (always)

On every scan, not just first-time:
- Does `.gitignore` exist?
- Are `.env`, `node_modules`, `.DS_Store`, `*.log`, `*.sqlite`, `*.db` listed in it?

A `.gitignore` entry can be accidentally removed in any commit. Check every time.

If no `.vibe/.check-history` file exists, this is a first-time scan — note it in the report.

### Step 4 — Report findings

For each finding, output exactly:

```
ISSUE: [one plain sentence — what is wrong]
RISK:  [one plain sentence — what happens if exploited]
FIX:   [one concrete action]
```

Then give the verdict (see below).

### Step 5 — Record history

After a clean run, create or update `.vibe/.check-history` with today's date. This marks the project as previously scanned.

```bash
mkdir -p .vibe
```
Create the directory if it doesn't exist — writing to `.vibe/` will fail silently if the directory isn't there.

---

## Translation Guide

### vibe-safe Output Translations

When vibe-safe is installed, use this table first. Match by keyword in the `vibe-safe: ` description.

| vibe-safe output contains | Plain-English translation |
|---|---|
| `STOP -- credential pattern found` | A real password or API key is committed to the repo. Anyone who has ever cloned or forked this repo already has it — even if you delete it now, it's in git history. Rotate the credential immediately, then remove it from the code. |
| `STOP -- committing directly to main` / `master` | You're working on the main branch. If something goes wrong, there's no safety net. Create a separate branch: `git checkout -b feature/your-change`. |
| `GitHub Action not pinned to SHA` | Your automated CI/CD runs code fetched from the internet at runtime. If that dependency gets hacked, your automation runs the malicious version. Pin to a specific commit hash. |
| `SCOPE WARNING -- N files staged` | More files changed than the developer contract allows. Review the list carefully — Claude may have modified things outside the intended scope. |
| `possible missing await on async call` | A database or API call result is probably a Promise object, not the actual data. The code looks like it works but is silently returning wrong values. Add `await`. |
| `test added without assertions` | A test was added but it doesn't actually check anything — it will always pass regardless of what the code does. Add at least one assertion. |
| `coverage threshold lowered` | The test coverage minimum was reduced — likely so CI would pass. This means less of your code is being tested. Restore the threshold and fix the underlying tests. |
| `possible sensitive data in log output` | Passwords, tokens, or user data are being printed to logs. Anyone who can read your server logs — or a monitoring service — can see this. Remove the log statement. |
| `helmet removed` | A security library that sets protective HTTP headers was removed. Your app is now missing defenses against common browser-based attacks. Restore it or replace with equivalent headers. |
| `new route...has no rate limiting` | A new API endpoint has no limit on how many requests a user can send. An attacker can hammer it indefinitely — to scrape data, brute-force passwords, or run up your bill. Add rate limiting. |
| `admin/internal route...has no visible auth` | An admin endpoint has no visible authentication check. Anyone who knows the URL can access it. Verify auth is enforced — either in this file or upstream middleware. |
| `webhook route...no visible signature verification` | Your webhook accepts any payload without checking it's really from the service that's supposed to send it. An attacker can send fake events. Verify the signature from the header. |
| `jwt.sign...without expiresIn` | Your login tokens never expire. If a token is stolen, the attacker has access forever. Add `expiresIn` when signing tokens. |
| `jwt.verify...without algorithms whitelist` | Your token verification accepts any algorithm, including `none` (no signature). An attacker can forge tokens. Specify `algorithms: ['HS256']` or whichever you use. |
| `auth token stored in localStorage` | Login tokens stored in localStorage can be stolen by any JavaScript running on your page (including injected scripts). Use httpOnly cookies instead. |
| `STOP -- Math.random() in auth` | Your login or token generation uses a predictable random number generator. An attacker can predict the values. Use `crypto.randomBytes()` or equivalent. |
| `STOP -- SQL string concatenation` | User input is being pasted directly into a database query. An attacker can type special characters to read or delete your entire database. Use parameterized queries. |
| `STOP -- shell: true` / `shell=True` | A subprocess is being run with shell mode enabled, and user input may flow into it. An attacker can run any command on your server. Disable shell mode and validate input. |
| `dangerouslySetInnerHTML` / `innerHTML =` | Raw HTML is being written directly to the page. If any of that HTML comes from user input or an API, an attacker can inject scripts that run in your users' browsers. Use safe alternatives. |
| `eval(` added | Your code runs a string as code. If that string comes from user input or an external source, an attacker can execute arbitrary commands. Replace with a safe alternative. |
| `STOP -- SSL verification disabled` | HTTPS certificate checking was turned off. Your app will accept fake or expired certificates, making it trivially easy for an attacker to intercept traffic. Remove this. |
| `CORS wildcard` | Your API accepts requests from any website. A malicious site can make requests on behalf of your users without their knowledge. Restrict to specific domains. |
| `private key / cert file staged` | A private key or certificate file is about to be committed. This is a credential — once in git history, it's compromised. Remove it immediately and rotate the key. |
| `gitleaks` | An entropy-based scanner found something that looks like a real credential. Even if it looks like a test value, rotate it — entropy scanners have very low false positive rates. |
| `.gitignore entries removed` | Files that were previously excluded from git are now being tracked. If any were security-sensitive (env files, generated credentials), they may now be committed. Restore the entries. |
| `TODO` / `FIXME` in implementation | Placeholder code was shipped instead of a real implementation. This usually means the feature is incomplete or a known problem was intentionally left unfixed. Address it before pushing. |
| `commented-out code` | Working code was commented out instead of deleted. This often means Claude wasn't sure whether to remove it. Review and decide: delete it or restore it. |
| `rm -rf` in committed script | A destructive shell command is in a script that will be committed. If this runs in production with the wrong path, it can delete critical files. Add explicit path validation. |
| `npm audit` / `pip-audit` / `semgrep` | A known security vulnerability was found in an installed package. The package has a published CVE — update or replace it. |

For any vibe-safe output line not in this table, apply the general format: explain what it is, what the real-world harm is, and what to do.

---

### General Translation Guide

Translate every technical finding into plain English using these patterns. For findings not listed, apply the same format: explain what it is, what the real-world harm is, and what to do.

| Technical finding | Plain-English translation |
|---|---|
| Potential credential exposure | Your API key or password might be in the code. Anyone who sees your repo can use your accounts, rack up charges on your behalf, or access your users' data. Remove it from the code and put it in a `.env` file instead. |
| Hardcoded secret / hardcoded API key | Your password or secret key is written directly in the code. If your repo is public or ever becomes public, that key is compromised. Move it to `.env` and never commit that file. |
| SQL injection vulnerability | A malicious user could steal or delete your entire database by typing special characters into a form. Use parameterized queries instead of building SQL strings by hand. |
| Missing .gitignore entry for .env | Your `.env` file — which contains your passwords and API keys — could get uploaded to GitHub. Anyone could read it. Add `.env` to your `.gitignore` right now. |
| Missing .gitignore | You have no `.gitignore`, which means Git will track everything including sensitive files and generated folders. Create one immediately. |
| node_modules not in .gitignore | Your `node_modules` folder (hundreds of megabytes of installed packages) could be uploaded to GitHub. It slows everyone down and wastes space. Add it to `.gitignore`. |
| Unpinned GitHub Actions / unpinned dependency | Your automated tasks run code from the internet without locking the version. Someone could change that code and your automation would run the malicious version. Pin dependencies to exact versions or commit hashes. |
| eval() usage / unsafe eval | Your code runs arbitrary strings as code. An attacker who can control that string can run any command on your server. Replace `eval` with a safe alternative. |
| Insecure random number generator | Your code uses a predictable random number for something that needs to be unpredictable (like a session token or password reset link). An attacker can guess these values. Use a cryptographically secure random generator. |
| Console.log of sensitive data | You're printing passwords, tokens, or user data to your logs. Anyone who can read your logs — including log-monitoring services — can see this. Remove the log line or replace with a non-sensitive placeholder. |
| Missing HTTPS / HTTP endpoint | Passwords and data sent over HTTP are visible to anyone on the same network (coffee shop, hotel Wi-Fi). Switch to HTTPS. |
| Directory traversal | A user could request files outside your intended folder — including system files or other users' data — by using `../` in a URL. Validate and restrict file paths. |
| Command injection | Your code passes user input directly to a shell command. An attacker can run any command on your server. Never pass user input to shell commands; use a library that handles it safely. |
| Exposed stack trace / verbose error | When something breaks, your app shows the full technical error to the user. This tells attackers which libraries you use, where files live, and what's misconfigured. Show a friendly error to users and log the details privately. |

---

## Inline Checks (when vibe-safe is not available)

Run these grep patterns on the project files. Skip `node_modules`, `.git`, and binary files.

```bash
# Hardcoded secrets
grep -rn \
  --include="*.js" --include="*.ts" --include="*.py" \
  --include="*.rb" --include="*.php" --include="*.go" \
  --include="*.jsx" --include="*.tsx" \
  -E "(password|secret|api_key|apikey|token|AUTH|PRIVATE_KEY)\s*=\s*['\"][^'\"]{6,}" \
  . | grep -v node_modules | grep -v ".git"

# .env not in .gitignore
if [ -f ".env" ] && ! grep -q "^\.env" .gitignore 2>/dev/null; then
  echo "FINDING: .env file exists but is not in .gitignore"
fi

# SQL injection patterns (string concatenation into queries)
grep -rn \
  --include="*.js" --include="*.ts" --include="*.py" \
  --include="*.rb" --include="*.php" --include="*.go" \
  -E "(\bquery\b|\bexecute\b|\braw\b)\s*\(.*\+" \
  . | grep -v node_modules | grep -v ".git"

# eval usage (JS/TS) and exec() usage (Python — runs shell commands)
grep -rn --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" \
  -E "\beval\s*\(" . | grep -v node_modules | grep -v ".git"
grep -rn --include="*.py" \
  -E "\bexec\s*\(|\bos\.system\s*\(|\bsubprocess\.call\s*\(" \
  . | grep -v node_modules | grep -v ".git"

# console.log with sensitive-looking names
grep -rn --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" \
  -E "console\.log\(.*?(password|token|secret|key|auth)" \
  . | grep -v node_modules | grep -v ".git"

# Unpinned GitHub Actions
grep -rn --include="*.yml" --include="*.yaml" \
  -E "uses: [^@]+@(main|master|latest)" .github/ 2>/dev/null
```

Translate each match through the translation guide above.

> If any grep returns more than 10 results: don't present every match. Open the first 3 results, check if they're real findings or false positives (test files, comments, placeholder values). If the first 3 are false positives, note "X pattern returned Y matches — none of the first 3 are real findings" and move on. Don't list all 50 matches — that's noise.

**Also suggest:** If the project has a `package.json`, offer to run `npm audit` for known vulnerabilities in installed packages. This catches issues vibe-safe's static analysis can't see. Translate findings the same way — in plain English with a clear verdict.

---

## Verdict

After all findings are listed, end with exactly one of these:

**No critical or medium issues found:**
```
✅ Looks safe to push. Run /vibe-git and I'll handle the commit and upload.
```

**Medium issues found (e.g. missing .gitignore entries, console.log of non-critical data, unpinned actions):**
```
⚠️ Fix these before pushing:
   [list each issue in one line]

Fix each one above, then run /vibe-check again before uploading.
```

**Critical issues found (credentials in code, SQL injection, .env not gitignored, command injection):**
```
🚨 Do not deploy or sync to GitHub yet — fix these first:
   [list each issue in one line]
```

Critical issues are anything that could expose passwords, API keys, user data, or allow remote code execution. Everything else is medium.

---

## Known Limitations

These grep patterns catch common, obvious problems. They cannot catch:

- **ORM misuse** — incorrect parameterized queries inside Prisma, ActiveRecord, SQLAlchemy, or Django ORM look syntactically correct but can still be vulnerable
- **Authentication logic errors** — insecure session handling, broken password comparison, missing authorization checks between routes
- **Business logic vulnerabilities** — pricing errors, permission gaps between features, privilege escalation
- **Transitive dependency vulnerabilities** — `npm audit` covers direct dependencies; deeply nested packages require a full audit

For projects with real users and real money: this scan is a starting point. Minimum next steps: run `npm audit` (Node) or `pip-audit` (Python) to catch known CVEs in installed packages. For anything involving user data, payments, or sensitive information at scale, consider a professional security review. `/vibe-handoff` in PLANNED mode can generate a brief for that conversation.

---

## Verification Checklist

After running vibe-check, confirm:

- [ ] No hardcoded passwords, API keys, or tokens in any committed file
- [ ] `.env` is in `.gitignore` and not tracked by Git
- [ ] `node_modules` is in `.gitignore`
- [ ] No user input flows directly into SQL strings or shell commands
- [ ] No `eval()` on user-controlled input
- [ ] Error messages shown to users don't include stack traces or file paths
- [ ] GitHub Actions (if any) are pinned to a commit hash or exact version tag
- [ ] `.vibe/.check-history` updated with today's scan date
