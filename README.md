# SocietyOS — Property Management Demo

A mobile-friendly, single-file demo for housing-society plot inventory, customer records, payment logs, and basic reports.

## Run it
1. Open the repository on GitHub.
2. Go to **Settings → Pages**.
3. Under **Build and deployment**, choose **Deploy from a branch**.
4. Select branch **main** and folder **/(root)**, then press **Save**.
5. Wait a few minutes. The site URL should be `https://abdullahdogar2331-beep.github.io/societyOS/`.

## Important demo limitations
- This is a front-end prototype. It uses browser localStorage; records stay in the current browser and are not shared with another device or user.
- The demo does not provide real authentication, tenant isolation, cloud backups, or production security.
- Do not store real CNICs, phone numbers, customer financial data, or confidential society records in this prototype.
- Before using this for a real society or selling it commercially, add a backend such as Supabase, authentication, strict row-level security (RLS), tenant/society membership checks, audit logs, backups, and security testing.
