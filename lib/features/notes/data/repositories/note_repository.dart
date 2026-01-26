import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/note.dart';

class NoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notesCollection => _firestore.collection('notes');

  // Criar nota
  Future<void> create(Note note) async {
    await _notesCollection.doc(note.id).set(note.toJson());
  }

  // Obter nota por ID
  Future<Note?> getById(String id) async {
    final doc = await _notesCollection.doc(id).get();
    if (!doc.exists) return null;
    return Note.fromJson(doc.data() as Map<String, dynamic>);
  }

  // Obter todas as notas do utilizador (Stream para sync em tempo real)
  Stream<List<Note>> watchUserNotes(String userId) {
    return _notesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Manter compatibilidade com Future se necessário, mas preferir Stream
  Future<List<Note>> getByUserId(String userId) async {
    final snapshot = await _notesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('criadoEm', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Note.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Obter notas com lembretes pendentes
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

  // Atualizar nota
  Future<void> update(Note note) async {
    await _notesCollection.doc(note.id).update(note.toJson());
  }

  // Deletar nota
  Future<void> delete(String id) async {
    await _notesCollection.doc(id).delete();
  }

  // Marcar notificação como enviada
  Future<void> markNotificationSent(String id) async {
    await _notesCollection.doc(id).update({
      'notificacaoEnviada': true,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Limpar todas as notas
  Future<void> clear() async {
    // Implementação perigosa no Firestore, melhor evitar ou deletar por lote
    // Deixando vazio por segurança ou implementando delete por batch por user
    // Mas como é 'clear', assumindo logout, não precisa deletar do server.
  }
}
