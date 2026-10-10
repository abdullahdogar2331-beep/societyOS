# SocietyOS — secure backend setup

The current GitHub Pages site is a front-end demo using browser localStorage. It is **not yet safe for real customer data** and does not yet provide secure multi-society isolation.

## Supabase setup (free tier to start)
1. Create a project at https://supabase.com/ and keep the database password private.
2. In Project Settings → API, copy the Project URL and the **publishable/anon key** only. Never put the `service_role` key in browser code or GitHub.
3. Open SQL Editor and run the full contents of `supabase-setup.sql`.
4. Enable Email/Password auth in Authentication → Sign In / Providers.
5. Do not use the current demo for real customer data until the app's data operations have been connected to Supabase and tested with two separate society accounts.

## Tenant security design
- `societies` stores each branded portal.
- `society_members` maps authenticated users to societies and roles.
- Plots, customers and payments each have a `society_id`.
- Row Level Security policies check the signed-in user's membership on every query/write.
- The first society membership must be provisioned by a trusted admin process. Never let a public sign-up assign itself to a society.

## Current status
Database schema and RLS foundation are prepared. The HTML dashboard still uses localStorage; secure sign-in and cloud data migration must be connected next before this can be sold or used with real data.
