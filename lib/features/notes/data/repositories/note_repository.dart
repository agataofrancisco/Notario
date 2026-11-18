import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/note.dart';

/// Notes are stored on-device so creating and reading them never requires
/// Firestore or an active connection.
class NoteRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> create(Note note) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Note?> getById(String id) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Note.fromMap(rows.first);
  }

  Stream<List<Note>> watchUserNotes(String userId) async* {
    yield await getByUserId(userId);
  }

  Future<List<Note>> getByUserId(String userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'criado_em DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<List<Note>> getPendingReminders(String userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'notes',
      where: 'user_id = ? AND notificacao_enviada = 0 '
          'AND data_lembrete IS NOT NULL AND data_lembrete <= ?',
      whereArgs: [userId, DateTime.now().toIso8601String()],
      orderBy: 'data_lembrete ASC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<void> update(Note note) async {
    final db = await _databaseHelper.database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markNotificationSent(String id) async {
    final db = await _databaseHelper.database;
    await db.update(
      'notes',
      {
        'notificacao_enviada': 1,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clear() async {
    final db = await _databaseHelper.database;
    await db.delete('notes');
  }
}
