---
name: vibe-perf
description: Performance investigation when something feels slow — measure first, find the actual bottleneck, fix only the biggest thing.
---

# vibe-perf

## When to use this

Use `/vibe-perf` when something in your app feels slow:
- A page takes too long to load
- A button freezes for a moment before responding
- A search or filter is sluggish
- Data takes forever to appear

The rule here is: **measure first, then fix**. Never optimize based on a feeling. Without a measurement, you might spend an hour fixing the wrong thing.

---

## Step 1 — Name the specific slow thing

"The app feels slow" is too vague to work from. Before doing anything, get specific.

Ask yourself (or the user):
- Which page or action exactly?
- How slow? (Takes 3 seconds to load? Freezes for 1 second? Never finishes?)
- On what device and connection? (Fast laptop? Phone? Home WiFi? Mobile data?)
- Does it happen every time, or only with a lot of data?

Write down the answer before moving on. Something like:
> "The Posts page takes about 4 seconds to load on my laptop at home. It happens every time."

That's your target. Everything from here is about fixing that specific thing.

---

## Step 2 — Measure it

Before touching a single line of code, get a real number. This is your **baseline** — the number you'll compare against after any fix.

### For web apps — use your browser's built-in tools

1. Open Chrome DevTools: press **F12** (or right-click anywhere on the page → Inspect)
2. Click the **Network** tab at the top
3. Check the **"Disable cache"** checkbox (this makes sure you're measuring a real load, not a cached one)
4. Reload the page or trigger the slow action
5. Look at the bottom of the Network tab — it shows total load time and number of requests
6. Look for the **biggest or slowest row** — that's usually the bottleneck

Write down: total load time + the slowest/largest item.

Alternatively, use the **Lighthouse** tab in DevTools for an automated performance score with specific recommendations.

### For API response times — add a timer in code

Wrap the slow operation in a timer:
```javascript
console.time('fetch-posts')
// the slow operation here
console.timeEnd('fetch-posts')
```

```python
# Python
import time
start = time.time()
# ... the slow operation ...
print(f"took {time.time() - start:.2f}s")
```

```ruby
# Ruby
start = Time.now
# ... the slow operation ...
puts "took #{Time.now - start}s"
```

Open the browser console (F12 → Console tab) to see the JavaScript result. Write down the number.

### For database queries — turn on query logging

```javascript
// Prisma — add to your client setup
const prisma = new PrismaClient({ log: ['query'] })
```

```python
# Django — in settings.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
    },
}
```

Look for queries taking more than 100ms — those are worth investigating.

---

## Step 3 — Find the bottleneck

Time is going somewhere. These are the three places to look.

### Frontend (what the browser is doing)

Check the Network tab for:

**Bundle size** — is the JavaScript file huge? Large JS files make the page wait before showing anything.
- In the Network tab, filter by "JS" and look for files over 500KB
- A well-optimized app usually has JS files under 200KB

**Images** — are images too big and uncompressed?
- Filter by "Img" in the Network tab
- Any image over 500KB is suspicious — that's a photo-sized file being sent for every page load

**Too many requests** — is the page making 30+ separate network calls?
- Count the rows in the Network tab
- Each request has overhead; 50 small requests often takes longer than 5 larger ones

**For React apps — use the built-in Profiler:** open Chrome DevTools → Profiler tab → Record → interact with the slow part → Stop. Look for bars labeled with component names — tall bars mean slow renders. Components that render repeatedly on every interaction are good candidates for `React.memo` or `useMemo`.

### Backend (what the server is doing)

**Slow endpoints** — which API route takes the longest?
- In the Network tab, sort by "Time" column to find the slowest call
- Check your server logs for response times

**N+1 queries** — this is the most common backend performance killer.

An N+1 query means your code runs one database query to get a list, then runs *another separate query for each item in the list*. For 20 posts, that's 21 database calls instead of 1.

You'll recognize it in your query logs as many nearly identical queries running in a row:
```
SELECT * FROM users WHERE id = 1
SELECT * FROM users WHERE id = 2
SELECT * FROM users WHERE id = 3
... (20 more times)
```

**Missing index** — an index is a lookup table that makes searching fast, like the index at the back of a book. Without an index on the columns you filter by, the database reads every single row every time.

Signs: a query that worked fine with 100 rows suddenly slows down with 10,000 rows.

### Network (where the server lives)

- Is your server far from your users? A server in Australia serving users in Europe adds ~300ms per request
- Vercel, Netlify, and Cloudflare have CDNs (global edge networks) — self-hosted servers usually don't

### External APIs (third-party services)

If a slow request is going to an external service (Stripe, Cloudinary, a slow REST API), the bottleneck isn't in your code — it's the round-trip to another server.

To confirm, time the call in isolation:
```javascript
console.time('stripe-call'); await stripe.charges.retrieve(id); console.timeEnd('stripe-call')
```

If the external service is the bottleneck, your options are:
- **Cache the result** — store it for N minutes so subsequent requests don't wait
- **Run it in the background** — don't make the user wait; fire it async and update the UI when it's done
- **Add a loading state** — if you can't avoid the wait, make the slowness feel intentional rather than broken

---

## Step 4 — Name the bottleneck

After measuring, write one sentence describing what's actually slow and why:

> "The `/api/posts` endpoint takes 2.3 seconds. The query logs show it runs one database query per post to fetch the author — that's 21 queries for 20 posts. This is an N+1 problem."

Or:

> "The page loads 1.8MB of JavaScript before anything shows. Looking at the bundle, the charting library is 1.2MB and it's loaded even on pages that don't have charts."

Pick **one bottleneck** to fix. If there are several, pick the biggest. You can come back for the rest.

---

## Step 5 — Fix it

First, create a checkpoint so you can get back here if the fix makes things worse:
```bash
git add -A && git commit -m "checkpoint before performance fix"
```

### Fix: N+1 queries

Use a JOIN or your ORM's `include` to fetch related data in one query instead of many:

```javascript
// Prisma — before (N+1: one query per author)
const posts = await prisma.post.findMany()
// then a separate query per post...

// Prisma — after (one query total)
const posts = await prisma.post.findMany({ include: { author: true } })
```

```python
# Django — before (N+1)
posts = Post.objects.all()  # then a query per post.author

# Django — after (one query total)
posts = Post.objects.select_related('author').all()
```

### Fix: missing database index

Add an index on any column you filter or sort by:

```sql
-- PostgreSQL / MySQL
CREATE INDEX idx_posts_user_id ON posts(user_id);
```

With Prisma, add `@@index` to your schema and run a migration:
```prisma
model Post {
  userId Int
  @@index([userId])
}
```

### Fix: large images

- Compress images before uploading (use [Squoosh](https://squoosh.app/) — free, runs in the browser)
- Add `loading="lazy"` to images that aren't visible on initial load:
  ```html
  <img src="photo.jpg" loading="lazy" alt="..." />
  ```

### Fix: large JavaScript bundle

First check if the project uses Vite — look for `vite.config.js` or `vite` in `package.json` devDependencies. If it uses webpack instead, use `npx webpack-bundle-analyzer` or the Create React App built-in: `npm run build -- --stats`.

```bash
npx vite-bundle-visualizer   # Vite projects
npx webpack-bundle-analyzer  # Webpack projects
```

For Rollup or esbuild projects: check the build output file sizes directly with `ls -lh dist/` — if any file is over 500KB, it likely needs code splitting or lazy loading.

Look for large libraries used in only one place — they might load on demand instead.

---

## Step 6 — Measure again

After the fix, measure the same thing you measured in Step 2.

Did it get faster? Write down the new number.

State the improvement:
> "The endpoint went from 2.3 seconds to 180ms. That's a 12× improvement."

If the fix didn't help: go back to Step 3 and look at a different bottleneck. One hypothesis at a time.

---

## What NOT to do

- Don't optimize something already under 200ms — that's fast enough
- Don't "add caching" as a first move — caching hides problems without fixing them
- Don't rewrite the backend because "it feels slow" — measure first
- Don't optimize JavaScript rendering before checking the database — the database is almost always the bottleneck

If the bottleneck turns out to be on the user's device or network rather than the app, note this and suggest testing from a different device or connection before optimizing.

---

## Verification checklist

Before calling this done:

- [ ] Specific slow thing named — not just "the app feels slow"
- [ ] Baseline measurement taken before any code was changed
- [ ] Bottleneck identified from measurement, not intuition
- [ ] ONE fix applied
- [ ] Post-fix measurement confirms improvement
- [ ] Improvement stated as a specific number ("from 2.3s to 180ms")
- [ ] Checkpoint commit exists before the fix
