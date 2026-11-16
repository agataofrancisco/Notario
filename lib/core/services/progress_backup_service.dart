import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/progress/data/progress_repository.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

/// Optional progress-only backup adapter. It never receives a Task object,
/// Google Calendar IDs, titles, notes, or schedules.
class ProgressBackupService {
  ProgressBackupService({
    required ProgressRepository repository,
    required AuthService authService,
    http.Client? client,
  })  : _repository = repository,
        _authService = authService,
        _client = client ?? http.Client();

  final ProgressRepository _repository;
  final AuthService _authService;
  final http.Client _client;

  bool get isConfigured => AppConfig.progressBackendUrl.isNotEmpty;

  Future<void> sync(String userId) async {
    if (!isConfigured) return;
    final token = await _authService.googleIdToken();
    if (token == null) return;
    final events = await _repository.pending(userId);
    if (events.isEmpty) return;
    final operationIds = events.map((event) => event.operationId).toList();
    await _repository.recordAttempt(operationIds);
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.progressBackendUrl}/v1/progress/push'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(
                {'events': events.map((e) => e.toBackupJson()).toList()}),
          )
          .timeout(const Duration(seconds: AppConfig.httpTimeout));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accepted =
          (data['acceptedOperationIds'] as List<dynamic>? ?? const [])
              .whereType<String>();
      await _repository.markSynced(accepted);
    } on Exception {
      // SQLite queue is deliberately retained for the next attempt.
    }
  }
}
