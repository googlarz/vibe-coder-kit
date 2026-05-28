---
name: vibe-db
description: Safe database operations for vibecoders — migrations, schema changes, data inspection, and backups, with environment verification before every operation.
---

# vibe-db

The database is the one part of your app where a mistake is permanent and silent. Code bugs crash loudly. Database mistakes erase data quietly, and there's no undo button. This skill makes sure every operation is understood before it runs.

Core principle: **read before write, verify the environment, never assume local.**

---

**If your project uses Prisma:** run `npx prisma studio` to open a visual database browser — no SQL needed. You can browse tables, view rows, and verify data visually. Use the command-line steps below when Prisma Studio isn't available or for migrations and backups.

---

## Step 1 — Environment check (ALWAYS first, NEVER skipped)

Before doing anything else, check where the database actually is.

```bash
grep -E "DATABASE|POSTGRES|MONGO|REDIS|MYSQL|DB_HOST|DB_URL" .env 2>/dev/null | head -5
```

Then check:
```bash
grep -E "NODE_ENV|APP_ENV|VERCEL_ENV" .env 2>/dev/null
```

**What to look for:**

If `DATABASE_URL` contains any of these, you are looking at a live production database:
- `supabase.co`
- `railway.app`
- `planetscale.com`
- `neon.tech`
- `render.com`
- `.rds.amazonaws.com`

If it contains `localhost` or `127.0.0.1` — this is your local machine. Lower stakes.

**If there is ANY production indicator, say this at the top of your response — not buried:**

> "This is pointing at your live database. Real user data is there. I'll proceed, but confirm you want to run this against production, not a local copy."

Do not proceed until confirmed. Every single time.

---

## Migration operations

A migration is a change to your database structure — (adding a column, removing a table, changing a data type). The content of your database stays; only the shape changes.

### Step 2 — Read the migration file first

Do not run it. Read it. Translate every operation into plain English.

Examples:
- `ALTER TABLE users ADD COLUMN email_verified boolean` → "Adding a new column to the users table. Existing rows will have this set to blank (null) until they're updated."
- `DROP COLUMN password_hash` → "**Permanently deleting** the password_hash column and every value stored in it, across every row. This cannot be undone."
- `ALTER TABLE orders ALTER COLUMN total SET NOT NULL` → "Making the total column required. This will fail if any existing rows have no value there — check first."
- `CREATE INDEX idx_users_email ON users(email)` → "Adding a search index on email addresses. Makes lookups faster. Takes disk space but won't delete anything."
- `ALTER TABLE orders RENAME TO purchases` (PostgreSQL) / `RENAME TABLE orders TO purchases` (MySQL) → "Renaming a table. Any code that says 'orders' will break until it's updated to say 'purchases'."

Show this translation to the user before moving on.

### Step 3 — Assess the risk

**HIGH RISK** — these cannot be undone (see the Destructive Operations section below for the full confirmation protocol):
- Anything with `DROP` (column, table, index, database)
- Anything with `DELETE`
- Renaming a column or table that existing code references
- Adding a `NOT NULL` column to a table that already has rows

**LOW RISK** — additive changes can be reversed by removing what was added:
- Adding a new column (with a default or allowing null)
- Adding a new table
- Adding an index
- Adding a constraint to an empty table

Say the risk level out loud before running anything.

### Step 4 — Backup check (required for HIGH RISK operations)

For HIGH RISK migrations, confirm a backup exists before running.

**Supabase:** Dashboard → Settings → Database → Backups. Check when the last backup was taken.

**Railway:** Dashboard → your project → the database service → check for backup settings.

**PlanetScale:** Branches act as snapshots. Check if you have a branch that's at a safe state before merging.

**Neon:** Branches work like PlanetScale — check if there's a backup branch.

**Local PostgreSQL:** Check for a recent dump file:
```bash
find . -name "*.sql" -newer package.json 2>/dev/null
```

If no recent backup exists, offer to create one before proceeding:

> I'll run this backup command — you don't need to understand SQL or touch the terminal. I'll use the credentials from your `.env` file and tell you when the backup is done.

```bash
# PostgreSQL — I'll substitute your DATABASE_URL automatically
pg_dump $DATABASE_URL > backup-$(date +%Y%m%d-%H%M).sql

# MySQL
mysqldump $DATABASE_URL > backup-$(date +%Y%m%d-%H%M).sql
```

If `pg_dump` or `mysqldump` isn't installed, or if the database is on a hosted platform: use your provider's dashboard instead (Supabase: Project Settings → Backups; Railway: your DB service → Backups tab; PlanetScale: Branches → export). Dashboard backups are always the easiest option.

### Step 5 — Run the migration

```bash
# Prisma
npx prisma migrate deploy

# Django
python manage.py migrate

# Rails
rails db:migrate

# Laravel
php artisan migrate

# Raw SQL file
psql $DATABASE_URL < migrations/your-migration.sql
```

If you have a `.sql` migration file and are not using an ORM: read the file first and assess the risk the same way, then run:
```bash
# PostgreSQL
psql $DATABASE_URL < path/to/migration.sql

# MySQL
mysql -h host -u user -p database < migration.sql
```
Verify by checking the table structure afterwards (see Step 6 below).

### Step 6 — Verify it worked

Check that the schema now matches what you expected:

```bash
# Prisma — visual browser
npx prisma studio

# Direct SQL — check columns on a table
psql $DATABASE_URL -c "\d table_name"
```

Or query the schema directly:
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'your_table'
ORDER BY ordinal_position;
```

Show the result. Confirm the column or change is there (or gone, if it was a drop).

---

## Data inspection

When the user wants to see what's in their database.

**Always use SELECT.** Never run UPDATE or DELETE to "see what would be affected" — it changes data.

Safe inspection queries to run (always explain what each one does before running it):

```sql
-- How many rows are in this table?
SELECT COUNT(*) FROM table_name;

-- What does recent data look like?
SELECT * FROM table_name ORDER BY created_at DESC LIMIT 5;

-- Are there any blank values in an important column?
SELECT COUNT(*) FROM table_name WHERE email IS NULL;

-- What's the range of dates in the data?
SELECT MIN(created_at), MAX(created_at) FROM table_name;
```

For Prisma projects, `npx prisma studio` opens a visual table browser in your browser — safer and easier than raw SQL for inspecting data.

---

## Destructive operations (DELETE, TRUNCATE, DROP)

These require explicit confirmation every time, no exceptions.

For each one, before running:

1. Say exactly what will be deleted — rows, columns, or entire tables
2. Estimate how much data: "this will delete approximately 4,200 rows"
3. Say whether it's reversible: it is not
4. Ask: "This will permanently delete [what]. There is no undo. Confirm?"
5. Only proceed with a clear "yes"

If operating on production data, create a backup first (see Step 4 above).

If the vibe-coder-kit hooks are installed, the safety hook will intercept this command and ask for confirmation before proceeding. If not, you'll need to confirm manually before proceeding.

---

## Schema inspection (safe anytime)

These never change data. Run freely to understand the current state:

```bash
# Regenerate your Prisma schema from whatever is actually in the database
npx prisma db pull

# Visual schema browser
npx prisma studio

# Show current migration status
npx prisma migrate status
```

```sql
-- All tables in the database
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- All columns for a specific table
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'your_table';
```

---

## Platform notes

**Supabase** — SQL editor is in the dashboard (Table Editor → SQL Editor). Good for inspection. For schema changes, prefer the Prisma CLI or Supabase migrations to keep history.

**PlanetScale** — Branch-based. Create a branch, test the migration there, then merge to main. This is the safest migration workflow available on any platform.

**Neon** — Also has branches. Use a branch to test migrations before running on main.

**Railway / Render** — Standard database URLs. `psql $DATABASE_URL` works directly. No built-in branching — backups are your safety net.

**Local SQLite** — Low stakes. The database is a single file (usually `dev.db` or `database.sqlite`). If something goes wrong, delete the file and run migrations fresh. Back up with `cp dev.db dev.db.bak` before anything destructive.

---

## Verification checklist

- [ ] Environment confirmed — know whether this is local or production before any operation
- [ ] Migration file read and every operation translated to plain English
- [ ] Risk level assessed — additive (low) or destructive (high)
- [ ] For HIGH RISK: backup exists and its age was checked
- [ ] Backup confirmed before any HIGH RISK operation
- [ ] Operation ran without errors
- [ ] Schema or data verified after the operation — the change is actually there
