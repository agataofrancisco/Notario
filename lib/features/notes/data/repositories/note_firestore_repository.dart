import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/note.dart';

/// Repositório de notas usando Firestore
class NoteFirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notesCollection => _firestore.collection('notes');

  /// Criar nota
  Future<void> create(Note note) async {
    await _notesCollection.doc(note.id).set(note.toJson());
  }

  /// Obter notas do usuário (Stream)
  Stream<List<Note>> watchUserNotes(String userId) {
    return _notesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Obter notas com lembrete pendente
  Stream<List<Note>> watchPendingReminders(String userId) {
    final now = DateTime.now();

    return _notesCollection
        .where('userId', isEqualTo: userId)
        .where('notificacaoEnviada', isEqualTo: false)
        .where('lembrete', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Atualizar nota
  Future<void> update(Note note) async {
    await _notesCollection.doc(note.id).update(note.toJson());
  }

  /// Marcar notificação como enviada
  Future<void> markNotificationSent(String noteId) async {
    await _notesCollection.doc(noteId).update({
      'notificacaoEnviada': true,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Deletar nota
  Future<void> delete(String noteId) async {
    await _notesCollection.doc(noteId).delete();
  }

  /// Obter nota por ID
  Future<Note?> getById(String noteId) async {
    final doc = await _notesCollection.doc(noteId).get();
    if (!doc.exists) return null;
    return Note.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Limpar notas do usuário
  Future<void> clearUserNotes(String userId) async {
    final snapshot =
        await _notesCollection.where('userId', isEqualTo: userId).get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
