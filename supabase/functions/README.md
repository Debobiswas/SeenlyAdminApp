# Seenly Admin Edge Functions

These functions keep the Supabase service-role key out of the Flutter admin app.

Deploy these functions with JWT verification enabled:

- `admin_approve_profile`
- `admin_reject_profile`
- `admin_audit_logs`

Each function expects the caller's Supabase access token in the normal
`Authorization: Bearer ...` header. The Flutter Supabase client sends this
automatically when an admin is signed in.

The functions use `SUPABASE_SERVICE_ROLE_KEY` only after verifying that the
caller exists in `public.admins` with `is_admin = true` and `role = 'admin'`.

Required secrets:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
