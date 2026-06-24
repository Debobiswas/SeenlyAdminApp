# Seenly Admin App

Flutter admin application for Seenly moderation workflows.

## V1 Features

- Admin email/password sign-in
- Admin authorization gate
- Pending influencer and business review queue
- Approve and reject actions
- Rejection reason capture
- Audit history page

## Setup

1. Create a `.env` file from `.env.example`.
2. Add your Supabase project URL and anon key.
3. Run the SQL migration in [supabase/migrations/20260620_seenly_admin.sql](/C:/Users/debob/Documents/SeenlyAdminAPP/supabase/migrations/20260620_seenly_admin.sql:1).
4. Install Flutter dependencies with `flutter pub get`.
5. Run the app with your preferred Flutter target.

## Notes

- This workspace contains the Flutter source scaffold and Supabase migration needed for the admin app.
- Flutter was not available on the current machine path during implementation, so the code could not be compile-verified in-session.

