# Bandwise

Independent IELTS Academic prep app (Flutter). Not affiliated with IELTS, the British Council, IDP, or Cambridge.

See `CLAUDE.md` for stack, design tokens, and product rules.

## Run

```sh
flutter pub get
cp env.example.json env.json   # then fill in the two values (see below)
flutter run --dart-define-from-file=env.json
flutter analyze && flutter test
```

`env.json` holds `SUPABASE_URL` and `SUPABASE_ANON_KEY` (the anon or publishable key, which is public by design). It is gitignored; only `env.example.json`, with empty values, is committed. **Never put the service_role key in the app, `env.json` or the repo.**

Without `env.json` (or with empty values) the app runs fully offline as a guest, exactly as before; the auth screens show "Accounts aren't configured in this build".

In debug builds, Profile → "Component gallery" shows every shared widget in every state.

## Accounts and sync

- Local storage stays the source the UI reads. When signed in, `SyncService` pushes changed documents about 3 s after a change and when the app goes to the background, and pulls on login and app start. Each document (`onboarding`, `progress`, `settings`) is last-write-wins by `updated_at`; essays merge by id. Offline changes are retried.
- A guest who signs up has their device progress uploaded. A guest with progress who logs in to an account that already has progress chooses: keep the account's progress (default) or replace it with the device's.
- Sign out syncs, then clears the device. Delete account calls the `delete-account` Edge Function.

## Supabase dashboard checklist

1. **Create a project** at supabase.com.
2. **Run the schema**: SQL Editor → New query → paste `supabase/migrations/001_init.sql` → Run. Check under Table Editor that `user_documents`, `essays` and `profiles` exist with RLS enabled.
3. **Email sign-in**: Authentication → Sign In / Providers → Email: enabled. Set the minimum password length to 8 (the app requires 8 with letters and numbers).
4. **Email confirmation** (your choice): Authentication → Sign In / Providers → Email → "Confirm email". On: new users see "Check your inbox to confirm your email" and log in after confirming. Off: they are signed in straight away.
5. **Password reset code**: Authentication → Emails → "Reset Password" template: include the code, e.g. `Your Bandwise code is {{ .Token }}`. (The app uses the 6-digit code, not the link.) Make sure the email OTP length is 6 (Authentication → Sign In / Providers → Email).
6. **Site URL**: Authentication → URL Configuration → Site URL: a page that says the email is confirmed and to return to the app (the confirmation link lands there).
7. **Email sending**: the built-in email service is heavily rate-limited; set up custom SMTP (Authentication → Emails → SMTP Settings) before real users. Review Authentication → Rate Limits.
8. **Deploy the delete-account function**: install the Supabase CLI, then `supabase login`, `supabase link --project-ref <ref>`, `supabase functions deploy delete-account`. Keep "Verify JWT" on. `SUPABASE_SERVICE_ROLE_KEY` is provided to the function by Supabase; don't copy it anywhere.
9. **Keys for the app**: Project Settings → API: copy the Project URL into `SUPABASE_URL` and the anon (or publishable) key into `SUPABASE_ANON_KEY` in `env.json`.
10. **Google sign-in** comes later (the button shows "Coming soon").
