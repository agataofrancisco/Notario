# Firestore rules tests

These tests exercise the committed `firestore.rules` in the local Firestore
Emulator. They do not deploy rules or access the production database.

From the repository root:

```powershell
npm --prefix tooling/firestore-rules-test ci
npx --yes firebase-tools@15.36.0 emulators:exec --config firebase.json --project notario-6961f --only firestore "npm --prefix tooling/firestore-rules-test run verify"
```

The assertions cover deadline-bearing task create/read/update/delete ownership,
preventing a user from changing document ownership, and note ownership.
