---
name: vibe-auth
description: Audits an existing authentication implementation for silent failures before going live or when something feels off.
---

# vibe-auth

Auth bugs don't crash your app — they just let the wrong people in, or lock the right people out. By the time you notice, real users have been affected. This skill audits what you already built.

**Not for building auth from scratch** — that's what vibe-guardian does during development. Run vibe-auth after auth is built, before launch, or when something feels off.

**Run one check at a time** — confirm findings with the user before moving to the next. You don't have to do all 7 in one session. If the user wants to stop after 3 checks, that's fine — just document which checks remain in `.vibe/debt.md`.

Two things need to work correctly:
- **Authentication** — proving who you are (login, logout, sessions, tokens)
- **Authorization** — proving you're allowed to do something (only admins can delete, only you can edit your own post)

They fail in different, often invisible ways. Let's check both.

---

## Check 1 — Login rejects bad inputs correctly

**Your role in this check:** test the login form in your browser — I'll tell you what each result means. No code reading needed.

Test these in the login form:

- Empty email + empty password → should show an error, not crash or log you in
- Real email + wrong password → should reject with a message like "Invalid email or password" — not "wrong password" (that tells attackers which emails are registered)
- Type this in the email field: `' OR '1'='1` — you'll type this exactly as shown. This is a SQL injection attempt (a trick to bypass login by confusing the database). Just tell me whether you got an error or got logged in — I'll tell you what the result means.
- Paste 500 characters into the email field → should handle it without freezing or erroring out

**Note on ORMs:** If the project uses an ORM (Prisma, Sequelize, Mongoose, Django ORM, ActiveRecord) rather than raw SQL queries — SQL injection is handled automatically. Skip the manual SQL injection test and note "ORM provides protection" in the summary.

---

## Check 2 — Sessions expire

A session is the record of "this person is logged in." It should have a time limit.

Test this:
1. Log in normally
2. Close the browser completely (not just the tab)
3. Reopen the browser and go directly to a protected page (like /dashboard)
4. Note whether you're still logged in — and how long before it expires

**I'll scan the code for this — you don't need to read it.** Your role here is just to do the browser test above and tell me what you see.

Then check the code for the session duration setting:

```bash
grep -r "maxAge\|expires\|session.*duration\|ttl\|TOKEN_EXPIRY" . --include="*.js" --include="*.ts" --include="*.py" --include="*.rb" --include="*.env*" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null
```

A reasonable duration depends on what the app does. A banking tool: 1 hour. A personal blog tool: 30 days. If there is NO expiry set at all (tokens never expire), that's a required fix — flag it with 🚨. If expiry exists but seems long for a sensitive app, flag with ⚠️ and suggest a shorter duration.

---

## Check 3 — Protected pages actually require login

This is the most common silent failure. A page that should need login loads fine without it.

**I'll scan the code for this — you don't need to read it.** Your role in this check is to test the routes I flag by trying to open them in an incognito window.

I'll find all the routes in the codebase. If a file has more than 50 route definitions, I'll say so and focus only on routes that handle user data or sensitive actions.

The grep I'll run:

```bash
grep -rn "router\.\|app\.get\|app\.post\|getServerSideProps\|loader\|createBrowserRouter\|Route path" . --include="*.js" --include="*.ts" --include="*.tsx" --include="*.py" --include="*.rb" --exclude-dir=node_modules --exclude-dir=.git | grep -v "//.*router"
```

If the output is long, focus only on lines that contain `/api/` or route-defining keywords (`app.get`, `app.post`, `router.get`, `router.post`, `@app.route`) — those are the actual endpoints. Ignore import lines and comments.

Don't try to understand every line — just look for routes that are missing the word 'auth', 'protect', 'requireAuth', or 'middleware' in the output above. Those are the ones to manually test by trying to access them without logging in first.

For each route that holds anything private (dashboard, settings, profile, admin, any user data): open an incognito window (a fresh browser session with no cookies — no login), paste the URL directly, and tell me what loads — whether it shows the page or redirects you to login.

If the page loads without being redirected to login, the protection is missing.

---

## Check 4 — Users can't access each other's data

This is an authorization bug (not authentication — you're logged in, just as the wrong person's data).

If the app has URLs like `/profile/123` or `/orders/456`, try changing the number to another user's ID while logged in as someone else. Can you see their data?

If the app uses long IDs (like `/profile/a3f8e21b-d4e5-...`) instead of numbers: look at the URL when you're on your profile or dashboard. Copy that ID, change the last character, paste it back into the URL bar and press Enter.

**I'll scan the code for this — you don't need to read it.** Your role is to do the URL test above: log in, find a URL with an ID in it, change the ID, and tell me what you see.

In the code, look for database queries that fetch by ID:

```bash
grep -rn "findById\|WHERE id\|params\.id\|req\.params\." . --include="*.js" --include="*.ts" --include="*.py" --include="*.rb" --exclude-dir=node_modules --exclude-dir=.git
```

A safe query checks both: `WHERE id = ? AND user_id = current_user`. A query that only checks `WHERE id = ?` will hand over anyone's data to anyone who guesses the number.

---

## Check 5 — Password reset works and can't be reused

If the app has a "forgot password" flow, test it end to end:

1. Request a reset — does the email arrive?
2. Click the link — does it work?
3. Complete the reset — does the new password work?
4. Try the reset link a second time — it should fail (expired or already used)
5. Try logging in with the old password — it should no longer work

**I'll scan the code for this — you don't need to read it.** Your role is to do the browser tests above: request a reset, click the link, complete the reset, then try the link again and try the old password.

If there's a "remember me" checkbox: check that the persistent token is stored in an HttpOnly cookie (a type of cookie the browser protects from JavaScript — harder for attackers to steal). If it's stored in `localStorage` instead, flag it.

```bash
grep -rn "localStorage.*token\|localStorage.*auth\|localStorage.*session" . --include="*.js" --include="*.ts" --include="*.tsx" --include="*.py" --include="*.rb" --exclude-dir=node_modules --exclude-dir=.git
```

---

## Check 6 — Passwords are stored safely

**I'll scan the code for this — you don't need to read it.** There's no browser test for this check — it's entirely a code inspection I'll do for you.

Passwords must never be stored as plain text. They should be scrambled using a one-way algorithm (called hashing) so that even if your database is stolen, the attacker can't reverse it to get the real password. The safe algorithms are: `bcrypt`, `argon2`, `scrypt`, or `pbkdf2`.

```bash
grep -rn "bcrypt\|argon2\|scrypt\|pbkdf2\|hashSync\|hash(" . --include="*.js" --include="*.ts" --include="*.py" --include="*.rb" --exclude-dir=node_modules --exclude-dir=.git
```

If you don't see any of those, check what's actually happening with passwords:

```bash
grep -r "password" . --include="*.js" --include="*.ts" --include="*.py" --include="*.rb" --exclude-dir=node_modules --exclude-dir=.git -l
```

Open the files that handle user creation and login. If passwords are stored directly, or hashed with `md5` or `sha1` (old algorithms that can be cracked), that's a critical problem.

Also check that passwords aren't being logged by accident:

```bash
grep -rn "console\.log.*password\|logger.*password" . --include="*.js" --include="*.ts" --include="*.py" --include="*.rb" --exclude-dir=node_modules --exclude-dir=.git
```

---

## Check 7 — Logout actually ends the session

Two different things happen when a user logs out:
- The browser deletes the local cookie or token (client-side)
- The server marks the session as ended (server-side)

Client-only logout is the common mistake. The browser cookie is deleted, so the user appears logged out — but the session is still valid on the server. Anyone who captured the token before logout can still use it.

Test it:
1. Log in and go to a protected page
2. Log out
3. Press the browser back button — does the previous page load and work?
4. Try visiting a protected route directly — it should redirect to login

In the code, find the logout handler:

```bash
grep -rn "logout\|signOut\|session\.destroy\|token.*invalidat\|blacklist" . --include="*.js" --include="*.ts" --include="*.py" --include="*.rb" --exclude-dir=node_modules --exclude-dir=.git
```

Look for server-side session destruction (`session.destroy`, `deleteSession`, removing the token from a database or blocklist). If logout only clears a cookie on the client without touching the server, the session lives on.

---

## Report

After all seven checks, I'll give you:

**What's working** — one paragraph summarizing what held up.

**What's not** — each finding gets three lines:
- What's wrong (one sentence)
- What could happen (what does this mean for your users?)
- How to fix it (specific, not vague)

---

## When to escalate to /vibe-handoff

Some findings can be fixed in a sprint. These need to be fixed before anyone uses the app:

- Passwords stored in plain text or hashed with MD5 or SHA1
- Any route holding financial or personal data loads without login
- Session tokens stored in `localStorage` for anything sensitive

When I find these, I'll say so clearly and recommend running `/vibe-handoff` to get a proper handoff document for a developer.

---

## Verification checklist

- [ ] Login form tested with empty inputs, wrong password, SQL injection attempt, and long input
- [ ] Session expiry confirmed — both via browser test and code check
- [ ] Every protected route tested in incognito (no login) to verify it redirects
- [ ] User A cannot access User B's data — tested by changing IDs in URLs, not assumed
- [ ] Password reset tested end to end: email arrives, link works once, old password invalidated
- [ ] Passwords confirmed hashed with bcrypt, argon2, scrypt, or pbkdf2 — not stored plain or with MD5/SHA1
- [ ] No passwords appearing in console.log or logger calls
- [ ] Logout clears session server-side, not just client-side
- [ ] Critical findings escalated to /vibe-handoff if warranted
