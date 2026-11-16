import 'package:uuid/uuid.dart';

import '../../../core/config/app_timezone.dart';
import '../../../core/database/database_helper.dart';

class ProgressEvent {
  const ProgressEvent({
    required this.operationId,
    required this.userId,
    required this.completedAt,
    required this.actualMinutes,
  });

  final String operationId;
  final String userId;
  final DateTime completedAt;
  final int actualMinutes;

  Map<String, dynamic> toBackupJson() => {
        'operationId': operationId,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'actualMinutes': actualMinutes,
        'kind': 'completed',
      };

  factory ProgressEvent.fromMap(Map<String, Object?> map) => ProgressEvent(
        operationId: map['operation_id']! as String,
        userId: map['user_id']! as String,
        completedAt: DateTime.parse(map['completed_at']! as String),
        actualMinutes: map['actual_minutes']! as int,
      );
}

class ProgressRepository {
  ProgressRepository({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<void> enqueueCompletion({
    required String userId,
    required int actualMinutes,
    DateTime? completedAt,
  }) async {
    final db = await _dbHelper.database;
    final now = (completedAt ?? AppTimeZone.now()).toUtc();
    await db.insert('progress_events', {
      'operation_id': const Uuid().v4(),
      'user_id': userId,
      'completed_at': now.toIso8601String(),
      'actual_minutes': actualMinutes,
      'kind': 'completed',
      'sync_status': 'pending',
      'attempts': 0,
      'created_at': now.toIso8601String(),
    });
  }

  Future<List<ProgressEvent>> pending(String userId, {int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.query('progress_events',
        where: 'user_id = ? AND sync_status = ?',
        whereArgs: [userId, 'pending'],
        orderBy: 'created_at ASC',
        limit: limit);
    return rows.map(ProgressEvent.fromMap).toList();
  }

  Future<void> markSynced(Iterable<String> operationIds) async {
    if (operationIds.isEmpty) return;
    final db = await _dbHelper.database;
    final marks = List.filled(operationIds.length, '?').join(',');
    await db.update('progress_events', {'sync_status': 'synced'},
        where: 'operation_id IN ($marks)', whereArgs: operationIds.toList());
  }

  Future<void> recordAttempt(Iterable<String> operationIds) async {
    if (operationIds.isEmpty) return;
    final db = await _dbHelper.database;
    final marks = List.filled(operationIds.length, '?').join(',');
    await db.rawUpdate(
        'UPDATE progress_events SET attempts = attempts + 1 WHERE operation_id IN ($marks)',
        operationIds.toList());
  }
}
