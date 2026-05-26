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
1. `vibe-safe` command on PATH
2. `./vibe-safe.sh` in the project root
3. `.vibe/vibe-safe.sh`

If found, run it and capture the output. If not found, proceed to inline checks.

### Step 2 — Run the scan

**If vibe-safe is available:** Run it, then pass every line of output through the translation guide below.

**If vibe-safe is not available:** Run the inline checks (see section below), then translate each finding.

### Step 3 — First-time check

If no `.vibe-check-history` file exists in the project root, this is a first-time scan. Also check:
- Does `.gitignore` exist?
- Are `.env`, `node_modules`, `.DS_Store`, `*.log`, `*.sqlite`, `*.db` listed in it?

### Step 4 — Report findings

For each finding, output exactly:

```
ISSUE: [one plain sentence — what is wrong]
RISK:  [one plain sentence — what happens if exploited]
FIX:   [one concrete action]
```

Then give the verdict (see below).

### Step 5 — Record history

After a clean run, create or update `.vibe-check-history` with today's date. This marks the project as previously scanned.

---

## Translation Guide

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

```
# Hardcoded secrets
grep -rn --include="*.js" --include="*.ts" --include="*.py" --include="*.env*" \
  -E "(password|secret|api_key|apikey|token|AUTH|PRIVATE_KEY)\s*=\s*['\"][^'\"]{6,}" .

# .env not in .gitignore
if [ -f ".env" ] && ! grep -q "^\.env" .gitignore 2>/dev/null; then
  echo "FINDING: .env file exists but is not in .gitignore"
fi

# SQL injection patterns
grep -rn --include="*.js" --include="*.ts" --include="*.py" \
  -E "query\s*\+|execute\s*\(.*\+|\"SELECT.*\+|\"INSERT.*\+" .

# eval usage
grep -rn --include="*.js" --include="*.ts" \
  -E "\beval\s*\(" .

# console.log with sensitive-looking names
grep -rn --include="*.js" --include="*.ts" \
  -E "console\.log\(.*?(password|token|secret|key|auth)" .

# Unpinned GitHub Actions
grep -rn --include="*.yml" --include="*.yaml" \
  -E "uses: [^@]+@(main|master|latest)" .github/ 2>/dev/null
```

Translate each match through the translation guide above.

---

## Verdict

After all findings are listed, end with exactly one of these:

**No critical or medium issues found:**
```
✅ Looks safe to push.
```

**Medium issues found (e.g. missing .gitignore entries, console.log of non-critical data, unpinned actions):**
```
⚠️ Fix these before pushing.
   [list each issue in one line]
```

**Critical issues found (credentials in code, SQL injection, .env not gitignored, command injection):**
```
🚨 Do not push until fixed.
   [list each issue in one line]
```

Critical issues are anything that could expose passwords, API keys, user data, or allow remote code execution. Everything else is medium.

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
