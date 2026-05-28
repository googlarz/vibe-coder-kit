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

If `.vibe/debt.md` doesn't exist, score as Yellow — no debt log means unobserved debt, not clean debt. Most projects have shortcuts; they just haven't been written down. Prompt the user: "Is there anything in this project you'd be nervous to change? That's your debt."

**Scoring:**
- 🟢 Green — No high-risk items. Debt is manageable.
- 🟡 Yellow — 1–2 high-risk items, or 4+ medium items accumulating.
- 🔴 Red — 3+ high-risk items, or debt log shows the same area mentioned repeatedly.

**Plain-English summary:** Describe the top 1–2 highest-risk debt items in one sentence each, using non-technical language. Example: "The payment page is skipping a validation step that could let someone pay less than the listed price."

---

### Step 3 — Assess Dimension 2: Session Velocity

Read `.vibe/sessions.md` if it exists. Look at the last 4–6 sessions.

Look for:
- **Recency** — When was the most recent session entry? If there are no entries in the last 7 days but git shows recent commits, the session log isn't being maintained — note this explicitly. No recency signal is not the same as Green.
- **Fix loops** — Did a session fix something, only for a later session to fix it again, or say something broke because of the fix? That's a sign of a deeper problem.
- **Area concentration** — Is the same file, page, or feature mentioned in 3+ sessions? Repeated attention to the same area often means the underlying structure is fragile.
- **Session goals achieved** — Did the session "Test manually" section indicate things worked, or were there unresolved issues?

If `.vibe/sessions.md` doesn't exist or has no entries, score as Yellow (not Green) — missing session logs are a signal, not a neutral state. Note: "No session history available — can't assess momentum."

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
find . \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.jsx" -o -name "*.tsx" \) | grep -v node_modules | grep -v .git | wc -l
```
Note the count. Scaffolded frameworks (Next.js, Rails, Django) start with 50–150 files before any custom code is written — factor that in. Over 200 *custom* files is worth flagging; over 400 total is a signal that complexity is high.

**Copy-paste patterns:**
```bash
find . -maxdepth 4 \( -name "*.js" -o -name "*.ts" -o -name "*.py" \) | grep -v node_modules | grep -v .git | xargs -I{} basename {} | grep -iE "(_old|_new|_copy|_bak|_backup|[0-9]\.js$|[0-9]\.ts$|[0-9]\.py$)" | sort 2>/dev/null || true
```
On Linux or if `gtimeout` is installed (`brew install coreutils` on macOS), you can add `timeout 15` as a prefix: `timeout 15 find . -maxdepth 4 ...`. Without it, the command still works fine on most projects.
Look for files with suffixes like `_old`, `_new`, `_copy`, `_backup`, or names ending in a number (e.g., `checkout2.js`, `auth_new.ts`). These often mean the same logic is duplicated in multiple places — a source of bugs. Do NOT flag `.js` and `.ts` variants of the same name (e.g., `checkout.js` and `checkout.ts`) — these are expected in TypeScript projects.

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
- 🟢 Green — Under 200 files, no obvious duplication, under 5 TODOs.
- 🟡 Yellow — 200–400 files, or 5–15 TODOs, or 1–2 duplicated file patterns.
- 🔴 Red — Over 400 files, or 15+ TODOs, or clear copy-paste duplication of important files (auth, payment, database).

**Reading the output — what to focus on vs. ignore:**
- **File count**: the raw number isn't meaningful alone. A scaffolded Next.js or Django project starts at 100–150 files before any custom code. Focus on whether the count seems high *relative to what was actually built*, not the absolute number.
- **Copy-paste hits**: only flag if they match critical-area files. `auth_new.ts`, `checkout2.js`, `payment_backup.py` are signals. `config2.js`, `utils_old.js` are noise.
- **TODO/FIXME count**: filter mentally for location. 15 TODOs in test files is fine. 2 TODOs in `stripe.js` or `auth.ts` is a signal worth surfacing.

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

**Overall score:**
- 🟢 Green — all dimensions Green
- 🟡 Yellow — any dimension is Yellow, OR Safety alone is Red (no git / no recent commits)
- 🔴 Red — Debt or Code Signals is Red, OR two or more dimensions are Red for any reason

A project with no git (Safety 🔴) but clean debt and good code signals is Yellow overall — reserve Red for signals that mean the project itself is fragile, not just unprotected.

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

When the answer is "Yes — before you go further", say so and then immediately offer:
> "Want me to generate a handoff document a developer can act on? Run `/vibe-handoff` and I'll put it together."

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

Need a real developer? [Direct answer, 1–2 sentences. If yes: "Run /vibe-handoff and I'll put together a document a developer can act on."]
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
- If `.vibe/debt.md` and `.vibe/sessions.md` don't exist, say so and note that the health check is limited to what can be scanned automatically. Recommend running a few sessions with the vibe-skills baseline so the logs are available next time. If momentum is stalled, start with `/vibe-scope` to reset focus. If debt is high, run `/vibe-clean`. If the project feels structurally confused, consider `/vibe-think` to re-examine scope.

---

## Verification checklist

- [ ] `.vibe/project.md` read (or noted as absent)
- [ ] All four dimensions assessed: Debt, Momentum, Code Signals, Safety
- [ ] Overall score calculated from dimension scores — not guessed
- [ ] "Need a real developer?" answered directly and specifically
- [ ] Dashboard output produced in the exact format shown above
- [ ] Details section included for any Yellow or Red dimension
- [ ] Next recommended skill named if applicable (`/vibe-clean`, `/vibe-scope`, `/vibe-handoff`)
