# Firebase to Supabase Migration Notes

## Firebase integration inventory (before migration)

- App bootstrap in `lib/main.dart` used `Firebase.initializeApp()` with `lib/firebase_options.dart`.
- Auth in `lib/services/auth_service.dart` used `FirebaseAuth` for email/password and `GoogleSignIn` -> Firebase credential exchange.
- Auth state in `lib/providers/auth_provider.dart` and `lib/main.dart` depended on Firebase `User` stream/type.
- Cloud sync in `lib/services/sync_service.dart` used Firestore:
  - `users/{uid}` profile document.
  - `users/{uid}/expenses/{uuid}` collection.
- Expense serialization in `lib/models/isar_expense.dart` used Firestore `Timestamp` maps.
- Dependency wiring in `lib/providers/expense_providers.dart` injected `FirebaseFirestore.instance`.
- Android project had FlutterFire integration:
  - `android/settings.gradle.kts` (`com.google.gms.google-services` plugin declaration).
  - `android/app/build.gradle.kts` (`com.google.gms.google-services` plugin application).
  - `android/app/google-services.json`.
- Project-level Firebase config files:
  - `firebase.json`
  - `firestore.rules`
  - `lib/firebase_options.dart`

## Supabase migration implemented

- Added `supabase_flutter` dependency and removed Firebase dependencies from `pubspec.yaml`.
- Added startup config via `lib/core/config/supabase_config.dart` using:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
- Replaced Firebase initialization with `Supabase.initialize()` in `lib/main.dart`.
- Added `AuthUser` domain model in `lib/models/auth_user.dart`.
- Migrated `AuthService` to Supabase Auth (`lib/services/auth_service.dart`):
  - Email/password sign in and sign up.
  - Google native sign-in token exchange via `signInWithIdToken`.
  - Auth state stream mapped to `AuthUser`.
- Migrated auth providers to `AuthUser` (`lib/providers/auth_provider.dart`).
- Migrated sync service to Supabase Postgres tables (`lib/services/sync_service.dart`):
  - Profile upsert to `profiles`.
  - Initial sync from `expenses` where `is_deleted = false`.
  - Queue upsert/delete operations against `expenses`.
- Migrated expense serialization from Firestore maps to Supabase maps in `lib/models/isar_expense.dart`.
- Updated provider wiring (`lib/providers/expense_providers.dart`) to remove Firestore injection.
- Removed Firebase files and Android Google services plugin wiring.
- Added production SQL schema + RLS migration:
  - `supabase/migrations/20260423_001_initial_traxer_schema.sql`

## Supabase production checklist

1. Create a Supabase project and enable Auth providers:
   - Email/Password
   - Google
2. Configure Google provider in Supabase dashboard with correct client credentials.
3. Apply SQL migration from `supabase/migrations/20260423_001_initial_traxer_schema.sql`.
4. Set app runtime variables:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
5. Verify auth and sync flow end-to-end:
   - signup/login
   - create/update/delete expense
   - offline queue + reconnect sync
   - logout/login with another account

