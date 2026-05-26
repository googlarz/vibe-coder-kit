---
name: vibe-health
description: Weekly project health dashboard — debt level, momentum, safety signals, and honest assessment of whether you need a real developer yet.
---

# vibe-health

Weekly checkup for your project. Run it on Monday morning, or whenever something feels "off." It reads what's been logged about your project and gives you a straight answer: how is this thing actually doing?

No technical knowledge required. The output reads like a doctor's checkup — honest, calm, and specific about what needs your attention.

## When to run

- Once a week (Monday is a good habit)
- After a rough session where things kept breaking
- Before showing the project to someone new
- Before adding a big new feature

---

## Process

### Step 1 — Read the project context

Read `.vibe/project.md` if it exists. Note:
- What the project is
- Whether real users are using it yet
- Where it runs (Vercel, local, etc.)

If `.vibe/project.md` doesn't exist, note that and proceed — some signals are still checkable.

---

### Step 2 — Assess Dimension 1: Debt Level

Read `.vibe/debt.md` if it exists.

Count items tagged or described as:
- **High-risk** — things that could break the app or expose user data
- **Medium** — shortcuts that will need fixing eventually
- **Low** — minor annoyances, cosmetic issues

If `.vibe/debt.md` doesn't exist, score as Green (no logged debt).

**Scoring:**
- 🟢 Green — No high-risk items. Debt is manageable.
- 🟡 Yellow — 1–2 high-risk items, or 4+ medium items accumulating.
- 🔴 Red — 3+ high-risk items, or debt log shows the same area mentioned repeatedly.

**Plain-English summary:** Describe the top 1–2 highest-risk debt items in one sentence each, using non-technical language. Example: "The payment page is skipping a validation step that could let someone pay less than the listed price."

---

### Step 3 — Assess Dimension 2: Session Velocity

Read `.vibe/sessions.md` if it exists. Look at the last 4–6 sessions.

Look for:
- **Fix loops** — Did a session fix something, only for a later session to fix it again, or say something broke because of the fix? That's a sign of a deeper problem.
- **Area concentration** — Is the same file, page, or feature mentioned in 3+ sessions? Repeated attention to the same area often means the underlying structure is fragile.
- **Session goals achieved** — Did the session "Test manually" section indicate things worked, or were there unresolved issues?

If `.vibe/sessions.md` doesn't exist, score as Green (no signal either way).

**Scoring:**
- 🟢 Green — Sessions are moving forward. Different areas. Fixes are holding.
- 🟡 Yellow — One area keeps coming up, or 1–2 sessions ended with unresolved issues.
- 🔴 Red — Fix loops detected, or the same problem has appeared in 3+ sessions.

**Plain-English summary:** One sentence on what the session log is telling you. Example: "The login area has come up in 4 of the last 6 sessions — it may need a more thorough fix rather than small patches."

---

### Step 4 — Assess Dimension 3: Codebase Signals

Run the following checks from the project root:

**File count check:**
```bash
find . -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.jsx" -o -name "*.tsx" | grep -v node_modules | grep -v .git | wc -l
```
Note the count. Over 100 files is worth flagging; over 200 is a signal that complexity is high.

**Copy-paste patterns:**
```bash
find . -maxdepth 3 -name "*.js" -o -name "*.ts" -o -name "*.py" | grep -v node_modules | grep -v .git | sed 's/[0-9]//g' | sort | uniq -d
```
Look for files with nearly identical names (e.g., `checkout.js`, `checkout2.js`, `checkout_new.js`). These often mean the same logic is duplicated in multiple places — a source of bugs.

**TODO/FIXME count:**
```bash
grep -r "TODO\|FIXME\|HACK\|XXX" --include="*.js" --include="*.ts" --include="*.py" --include="*.jsx" --include="*.tsx" . | grep -v node_modules | grep -v ".git" | wc -l
```
Note the count. Over 10 is worth mentioning.

**.env in the wrong place:**
```bash
find . -maxdepth 2 -name ".env" | grep -v node_modules
```
If any `.env` files are found, check whether they appear in `.gitignore`. If `.gitignore` doesn't exist or doesn't list `.env`, flag this as a safety issue (report in Dimension 4, not here).

**Scoring:**
- 🟢 Green — Under 100 files, no obvious duplication, under 5 TODOs.
- 🟡 Yellow — 100–200 files, or 5–15 TODOs, or 1–2 duplicated file patterns.
- 🔴 Red — Over 200 files, or 15+ TODOs, or clear copy-paste duplication of important files (auth, payment, database).

**Plain-English summary:** One sentence on the most notable signal. Example: "There are 3 files with similar names in the payment folder — this may mean the same logic is in multiple places, which makes bugs harder to fix."

---

### Step 5 — Assess Dimension 4: Safety Signals

Check the following:

**Git initialized:**
```bash
git status 2>&1
```
If this errors, git is not set up. Flag immediately.

**Recent commits:**
```bash
git log --oneline -5 2>&1
```
If the most recent commit is more than 2 weeks ago (or there are no commits), flag it. No recent commits means no backup of recent work.

**.gitignore exists and covers the basics:**
```bash
cat .gitignore 2>/dev/null
```
Check that `.env`, `node_modules`, `.DS_Store`, `*.log`, `*.sqlite`, `*.db` are listed. Flag any that are missing.

**Obvious hardcoded credentials (quick scan):**
```bash
grep -rn "password\s*=\s*['\"][^'\"]\|api_key\s*=\s*['\"][^'\"]\|secret\s*=\s*['\"][^'\"]\|token\s*=\s*['\"][^'\"]" --include="*.js" --include="*.ts" --include="*.py" --include="*.jsx" --include="*.tsx" . | grep -v node_modules | grep -v ".git" | grep -v ".env" | head -20
```
Flag any hits that look like real values (not placeholder text like `your-api-key-here`).

**Scoring:**
- 🟢 Green — Git active, committed in the last week, `.gitignore` covers the basics, no obvious hardcoded credentials.
- 🟡 Yellow — Git active but no commit in 1–2 weeks, or `.gitignore` is missing one expected entry.
- 🔴 Red — Git not set up, or last commit was over 2 weeks ago, or obvious hardcoded credentials found, or `.env` not in `.gitignore`.

**Plain-English summary:** One sentence on the most important safety issue found. Example: "Your last backup (git commit) was 18 days ago — anything you've built since then could be lost if something goes wrong."

---

### Step 6 — Overall Score and "Need a Real Developer?" Assessment

**Overall score:** Take the worst single dimension score. If two or more dimensions are Yellow, the overall is Yellow. If any dimension is Red, the overall is Red.

**"Need a real developer?" assessment:**

Answer this question directly and specifically. Base it on the following signals:

Say **"Not yet — you're fine"** if:
- No dimension is Red
- No high-risk debt items
- The project doesn't have real users yet, OR it has users but no auth/payment complexity

Say **"Soon — worth a review"** if:
- Any dimension is Yellow AND the project has real users
- The session log shows repeated problems in the same area
- There are 1–2 high-risk debt items

Say **"Yes — before you go further"** (be specific about what needs attention) if:
- Any dimension is Red
- 3+ high-risk debt items
- Auth, payments, or user data is involved AND there are unresolved issues in those areas
- A live product has no monitoring and is growing
- The same class of bug has come up 3+ times

Be specific. Don't just say "you might want a developer." Say what they should look at. Example: "You should have a developer review the authentication system before you add more users — there are 3 sessions mentioning login problems and one debt item flagged as high risk in that area."

---

### Step 7 — Produce the Dashboard

Output exactly this format. Fill in the actual values. Use 🟢 🟡 🔴 for the indicators.

```
─────────────────────────────────────
   PROJECT HEALTH — [today's date]
─────────────────────────────────────
Debt:          [indicator] [short label]
Momentum:      [indicator] [short label]
Code signals:  [indicator] [short label]
Safety:        [indicator] [short label]
─────────────────────────────────────
Overall:       [indicator] [one-line summary]

Top things to watch:
1. [most important item, plain English]
2. [second most important item]
3. [third most important item, or "Nothing else flagged" if only 2]

Need a real developer? [Direct answer, 1–2 sentences]
─────────────────────────────────────
```

After the dashboard, add a **Details** section with the plain-English summaries from each dimension (only for Yellow or Red dimensions — skip Green ones with "No issues noted").

---

## Example output

```
─────────────────────────────────────
   PROJECT HEALTH — 27 May 2026
─────────────────────────────────────
Debt:          🟡 2 items need attention
Momentum:      🟢 Good progress
Code signals:  🟢 Clean
Safety:        🟡 No recent backup
─────────────────────────────────────
Overall:       🟡 Healthy with caveats

Top things to watch:
1. The login page has a known shortcut that skips email
   verification — flagged as high-risk in debt log.
2. No git commit in 11 days — recent work isn't backed up.
3. Login area has come up in 4 of last 6 sessions.

Need a real developer? Not yet — but before you add
more users, have a developer look at the login flow.
The debt log has one high-risk item there and the
session log shows repeated patches in that area.
─────────────────────────────────────

Details:

DEBT: There's a shortcut in the login page that skips checking
whether a user confirmed their email. This means someone could
create an account with a fake email and still get in. It's marked
high-risk in the debt log from 3 weeks ago.

SAFETY: The last git commit (your backup point) was 11 days ago.
Anything built since then isn't saved. Run: git add -A && git commit -m "checkpoint [today's date]"
```

---

## Notes on tone

- Write like a doctor giving a checkup, not like a security scanner printing warnings.
- "Healthy with caveats" is better than "WARNING: ISSUES DETECTED."
- Always end with a specific, actionable "need a real developer?" answer. Don't hedge. Don't say "it depends." Give a real answer based on what you found.
- If `.vibe/debt.md` and `.vibe/sessions.md` don't exist, say so and note that the health check is limited to what can be scanned automatically. Recommend running a few sessions with the vibe-skills baseline so the logs are available next time.
