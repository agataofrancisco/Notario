import { readFile } from 'node:fs/promises';
import { after, before, test } from 'node:test';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const currentDir = fileURLToPath(new URL('.', import.meta.url));
const rules = await readFile(resolve(currentDir, '../../firestore.rules'), 'utf8');
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'notario-6961f',
    firestore: { rules },
  });
});

after(async () => {
  await environment?.cleanup();
});

test('deadline-bearing tasks are readable and writable only by their owner', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const bob = environment.authenticatedContext('bob').firestore();
  const aliceTask = doc(alice, 'tasks', 'alice-deadline-task');
  const bobView = doc(bob, 'tasks', 'alice-deadline-task');
  const deadlineTask = {
    userId: 'alice',
    titulo: 'Task with deadline',
    deadline: new Date('2026-12-01T12:00:00.000Z'),
  };

  await assertSucceeds(setDoc(aliceTask, deadlineTask));
  await assertSucceeds(updateDoc(aliceTask, { titulo: 'Updated by owner' }));
  await assertFails(setDoc(doc(bob, 'tasks', 'forged-owner'), deadlineTask));
  await assertFails(getDoc(bobView));
  await assertFails(updateDoc(bobView, { titulo: 'Updated by another user' }));
  await assertFails(deleteDoc(bobView));
  await assertFails(updateDoc(aliceTask, { userId: 'bob' }));
});

test('notes also remain scoped to the authenticated owner', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const bob = environment.authenticatedContext('bob').firestore();
  const aliceNote = doc(alice, 'notes', 'alice-note');

  await assertSucceeds(setDoc(aliceNote, { userId: 'alice', titulo: 'Private' }));
  await assertFails(getDoc(doc(bob, 'notes', 'alice-note')));
  await assertFails(deleteDoc(doc(bob, 'notes', 'alice-note')));
  await assertSucceeds(deleteDoc(aliceNote));
});
