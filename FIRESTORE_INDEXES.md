# Firestore Indexes Setup

This document explains how to deploy the Firestore indexes required for the Notário app.

## Prerequisites

- Firebase CLI installed (`npm install -g firebase-tools`)
- Logged in to Firebase (`firebase login`)

## Deployment Steps

1. **Initialize Firebase (if not already done)**:

   ```bash
   firebase init firestore
   ```

   - Select your project: `notario-6961f`
   - Accept the default `firestore.rules` file
   - Accept the default `firestore.indexes.json` file (it will use the one we created)

2. **Deploy the indexes**:

   ```bash
   firebase deploy --only firestore:indexes
   ```

3. **Wait for index creation**:
   - Index creation can take several minutes
   - You can monitor progress in the Firebase Console: https://console.firebase.google.com/project/notario-6961f/firestore/indexes

## Required Indexes

The `firestore.indexes.json` file defines **4 composite indexes**:

### Tasks Indexes

#### Index 1: Daily Tasks Query

- **Collection**: `tasks`
- **Fields**: `userId` (ASC) + `dataInicio` (ASC)
- **Purpose**: Efficiently query tasks for a specific user on a specific day

#### Index 2: Weekly Statistics Query

- **Collection**: `tasks`
- **Fields**: `estado` (ASC) + `userId` (ASC) + `dataInicio` (ASC)
- **Purpose**: Query tasks by status for weekly statistics

### Notes Indexes

#### Index 3: User Notes Query

- **Collection**: `notes`
- **Fields**: `userId` (ASC) + `criadoEm` (DESC)
- **Purpose**: Query all notes for a user ordered by creation date (most recent first)

#### Index 4: Pending Reminders Query

- **Collection**: `notes`
- **Fields**: `userId` (ASC) + `notificacaoEnviada` (ASC) + `lembrete` (ASC)
- **Purpose**: Query notes with pending reminders for notifications

## Troubleshooting

If you see errors like:

```
The query requires an index. You can create it here: https://console.firebase...
```

This means:

1. The indexes haven't been deployed yet, OR
2. The indexes are still being created (check Firebase Console)

You can also create indexes manually by clicking the URL in the error message.
