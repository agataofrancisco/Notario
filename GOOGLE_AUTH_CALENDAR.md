# Google sign-in and Calendar setup

The app uses Google only for identity at sign-in. Calendar and Tasks scopes are
requested later, when the authenticated user presses **Ligar** in the agenda.
The app stores the connection choice locally; disconnecting keeps cached tasks
and events on the device.

## Firebase and Google Cloud project

1. In Firebase Console, open project `notario-6961f`, enable **Authentication →
   Sign-in method → Google**, and configure the support email.
2. In **Project settings → Your apps → Android**, add the release/debug SHA-1
   and SHA-256 fingerprints. Download the updated `google-services.json` into
   `android/app/` and keep the Firebase Android package name in sync.
3. In Google Cloud Console for the same project, enable **Google Calendar API**
   and **Google Tasks API**.
4. Configure the OAuth consent screen with the app name, support/developer
   contact, and the Google accounts allowed during testing. Add the accounts
   as test users while the app remains in testing. Before public release, submit
   the requested Calendar/Tasks scopes for Google's verification; do not ask
   users to bypass the unverified-app warning in production.

## Platform configuration

- **Android:** Use the Firebase-generated `google-services.json`. Re-run the
  signing report after changing the signing key:

  ```powershell
  cd android
  .\gradlew signingReport
  ```

- **iOS:** Add the matching `GoogleService-Info.plist` to `ios/Runner`, use the
  registered bundle ID, and configure the reversed client ID as a URL scheme in
  `ios/Runner/Info.plist`.
- **Web:** Register the exact hosted origins and configure the web OAuth client
  in Firebase and the Google Sign-In web integration. Supply the server/web
  client ID through build configuration where required.

The Flutter source contains no fixed OAuth client ID or client secret. If the
build target needs an explicit server client ID, provide it at build time, for
example:

```powershell
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Never put a client secret in the mobile app or in a `--dart-define` value.

## Firestore rules and indexes

Deadline recommendations are calculated from SQLite and do not query Firestore
by deadline, so no deadline index is needed. The current Firestore rules restrict
task and note access to the signed-in owner and prevent ownership changes.
Deploy rules and the current index manifest from the repository root with:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project notario-6961f
```

Firestore sync remains optional; local task creation, deadline guidance, and
offline Calendar cache do not depend on Firestore billing.
