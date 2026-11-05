# Personal Stat Sheet: Supabase edition

Static site (GitHub Pages) + Supabase for accounts and data. You only ever edit `index.html`.

## Setup
1. Create a project at supabase.com. SQL Editor: paste and run `schema.sql`.
2. Project Settings, API: copy the **Project URL** and **anon public key** into the two
   constants near the bottom of `index.html` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
3. Authentication, URL Configuration: set **Site URL** to your Pages URL
   (`https://<you>.github.io/<repo>/`) and add the same URL under **Redirect URLs**.
4. Sign-in methods:
   - Email link works out of the box (Supabase's built-in mailer is rate-limited; add custom SMTP for real use).
   - GitHub login (optional): Authentication, Providers, GitHub. Create a GitHub OAuth app whose callback
     is `https://<project-ref>.supabase.co/auth/v1/callback`, then paste its client ID and secret.
5. Push to GitHub, enable Pages (Deploy from branch, `main`, root).

## How it works
- `#/your-slug` is a profile URL; `#/discover` searches listed profiles by shared interests.
- Profiles are not enumerable: the table is private and public reads go through `get_profile(slug)`.
- Interests are pulled from Hobbies, Favorite Topics and Hyperfixation (lowercased, parentheses stripped)
  and matched exactly.
- Edits autosave about a second after you stop typing.
