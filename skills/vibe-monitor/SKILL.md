---
name: vibe-monitor
description: Set up error tracking and uptime alerts so you find out when something breaks before your users do.
---

# vibe-monitor

You can't fix what you don't know is broken. A crashed API, a failing signup, a payment that silently errors — these all fail quietly unless something is watching. This skill sets up two things: a way to catch errors inside your app, and a way to know if your app stops responding entirely.

Two tools, in order of importance:
1. **Error tracking** — alerts you when your app throws an error
2. **Uptime monitoring** — alerts you when your app is completely unreachable

---

## Step 1 — Check what's already there

Before recommending anything, look silently:

```bash
grep -r "sentry\|logrocket\|datadog\|posthog\|bugsnag\|rollbar" package.json package-lock.json requirements.txt 2>/dev/null
```

Also check environment variables:

```bash
grep -iE "SENTRY|LOGROCKET|DATADOG|POSTHOG" .env .env.example 2>/dev/null
```

If something monitoring-related is found: check whether it's actually configured, not just installed. It's common to have Sentry in `package.json` with no `SENTRY_DSN` in `.env` and no `Sentry.init()` call in the code — installed but never connected. Say what you found.

If nothing is there: move to Step 2.

---

## Step 2 — Set up error tracking

**Recommended: Sentry** — free tier handles most small projects, and it has SDKs for every major stack. "SDK" just means the code that connects your app to Sentry.

Ask one question first: "What's your app built with?" Then use the right setup below.

---

### Next.js

Run the setup wizard — it handles everything automatically:

```bash
npx @sentry/wizard@latest -i nextjs
```

The wizard will ask for a Sentry project. If they don't have a Sentry account: send them to sentry.io to create one (free). Then come back and run this again.

---

### Node.js / Express

```bash
npm install @sentry/node
```

At the very top of the main server file — before any routes are defined:

```javascript
const Sentry = require("@sentry/node");
Sentry.init({ dsn: process.env.SENTRY_DSN });
```

Then add to `.env`:
```
SENTRY_DSN=https://...
```

The DSN (the URL that connects your app to Sentry) comes from: Sentry dashboard → your project → Settings → Client Keys (DSN).

---

### Python / Django / Flask

```bash
pip install sentry-sdk
```

At the top of your app's entry point:

```python
import sentry_sdk
import os

sentry_sdk.init(dsn=os.environ.get("SENTRY_DSN"))
```

Then add to `.env`:
```
SENTRY_DSN=https://...
```

---

### Alternatives to Sentry

- **LogRocket** — better if you want to see a video replay of what the user was doing when it broke
- **Posthog** — if they're already using it for analytics, it includes basic error tracking; no extra install needed

---

### Test that it actually works

Don't skip this. Add a temporary route or endpoint that deliberately throws an error:

```javascript
// Temporary — remove after testing
app.get("/test-error", (req, res) => {
  throw new Error("Test: Sentry is working");
});
```

Visit that URL in your browser. Go to the Sentry dashboard. The error should appear within 30 seconds. If it doesn't show up, the setup isn't working — don't move on until it does.

Then remove the test route.

---

## Step 3 — Set up uptime monitoring

Error tracking only catches errors that reach your code. It won't tell you if the server is completely down, if a deployment silently failed, or if your domain expired. Uptime monitoring covers that gap.

**Recommended: UptimeRobot** — free tier checks your app every 5 minutes and emails you if it goes down.

1. Create an account at uptimerobot.com
2. Click "Add New Monitor"
   - Monitor type: HTTP(s)
   - Friendly name: whatever you want (e.g. "My App")
   - URL: your production URL (e.g. `https://myapp.vercel.app`)
   - Monitoring interval: every 5 minutes
3. Under "Alert Contacts": add your email address
4. Save

**Test it:** Temporarily type a fake URL into the monitor (e.g. add `-broken` to the end). Within 10 minutes you should get an email saying the site is down. Then fix the URL back.

---

### If they're on Vercel, Railway, or Render

These platforms have built-in uptime dashboards — point the user there first:
- Vercel: dashboard → your project → the status indicator at the top
- Railway: your project → Metrics tab
- Render: dashboard → your service → the status dot

UptimeRobot is still worth adding on top — platform dashboards don't email you.

**Alternatives:**
- **Better Uptime** — slightly nicer interface
- **Checkly** — useful if you want to verify that a specific page loads correctly (not just that the server responds)

---

## Step 4 — Enable deployment failure notifications

This is optional but catches a common failure: you pushed something new and it silently failed to deploy, so the old version kept running.

- **Vercel:** Project Settings → Notifications → Failed Deployments → enable email
- **Railway:** Project → Settings → Notifications → enable failed deploy emails
- **Render:** Dashboard → your service → Settings → Notifications

---

## Step 5 — Tell the user what they're now set up for

Be concrete about what they'll receive:

> "You'll now get an email if:
> - Any unhandled error occurs in your app (Sentry — within seconds)
> - Your app is completely down or unreachable (UptimeRobot — within 5 minutes)
> - A deployment fails (Vercel/Railway notification — immediately)
>
> These won't catch every problem, but they'll catch the ones your users would report."

---

## When an alert fires — what to do

**Sentry error alert:**
Go to your Sentry dashboard → click the error → read the stack trace. It shows the file and line number where it happened. That's where to look first.

**UptimeRobot "site is down" alert:**
Check your deployment platform dashboard first — is there a failed deploy sitting there? If the app was working and suddenly isn't, run `/vibe-rollback` to get back to a working version, then figure out what broke.

**Deployment failure email:**
Your hosting platform will show the build logs. Look for the first red line — that's usually the actual error. If you pushed a change just before this, that change probably caused it.

---

## Verification checklist

- [ ] Checked for existing monitoring before installing anything new
- [ ] Error tracking installed and configured for the right stack
- [ ] `SENTRY_DSN` (or equivalent) added to `.env` and `.env.example`
- [ ] Test error triggered and confirmed visible in Sentry dashboard within 30 seconds
- [ ] Test route or test code removed after verification
- [ ] Uptime monitor created at UptimeRobot (or equivalent) pointing at production URL
- [ ] Alert email confirmed on the uptime monitor
- [ ] Uptime monitor tested by temporarily breaking the URL
- [ ] Deployment failure notifications enabled on hosting platform
- [ ] User knows what to do when each type of alert fires
