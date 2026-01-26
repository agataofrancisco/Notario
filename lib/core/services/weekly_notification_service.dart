import 'dart:async';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/task_firestore_repository.dart';
import 'notification_service.dart';

/// Serviço para gerenciar notificações semanais automáticas
class WeeklyNotificationService {
  static final WeeklyNotificationService _instance = WeeklyNotificationService._internal();
  factory WeeklyNotificationService() => _instance;
  WeeklyNotificationService._internal();

  final TaskFirestoreRepository _taskRepository = TaskFirestoreRepository();
  final NotificationService _notificationService = NotificationService();
  
  Timer? _weeklyTimer;
  bool _isInitialized = false;

  /// Inicializar serviço de notificações semanais
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    await _notificationService.initialize();
    await _scheduleWeeklyNotifications(userId);
    
    _isInitialized = true;
  }

  /// Agendar notificações semanais automáticas
  Future<void> _scheduleWeeklyNotifications(String userId) async {
    // Cancelar timer anterior se existir
    _weeklyTimer?.cancel();

    // Calcular próximo domingo às 20h para resumo semanal
    final now = DateTime.now();
    final daysUntilSunday = (7 - now.weekday) % 7;
    final nextSunday = now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
    final nextSummaryTime = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      20, // 20h
      0,
    );

    // Se já passou das 20h de domingo, agendar para próximo domingo
    final finalSummaryTime = nextSummaryTime.isBefore(now) 
        ? nextSummaryTime.add(const Duration(days: 7))
        : nextSummaryTime;

    // Calcular tempo até a próxima notificação
    final timeUntilNext = finalSummaryTime.difference(now);

    // Agendar timer para executar semanalmente
    _weeklyTimer = Timer.periodic(const Duration(days: 7), (timer) async {
      await _sendWeeklySummary(userId);
    });

    // Agendar primeira execução
    Timer(timeUntilNext, () async {
      await _sendWeeklySummary(userId);
    });

    // Agendar notificação de planejamento (domingo às 19h)
    await _notificationService.scheduleWeeklyPlanningReminder(userId: userId);
  }

  /// Enviar resumo semanal
  Future<void> _sendWeeklySummary(String userId) async {
    try {
      // Calcular início da semana (segunda-feira)
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final mondayStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      // Obter estatísticas da semana
      final stats = await _taskRepository.getWeeklyStats(userId, mondayStart);

      // Agendar notificação com as estatísticas
      await _notificationService.scheduleWeeklyNotifications(
        userId: userId,
        weeklyStats: stats,
      );

      // Salvar última execução
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_weekly_notification', now.toIso8601String());

    } catch (e) {
      developer.log('Erro ao enviar resumo semanal: $e', name: 'WeeklyNotificationService');
    }
  }

  /// Verificar se deve enviar notificação semanal (para recuperar notificações perdidas)
  Future<void> checkAndSendMissedNotifications(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationStr = prefs.getString('last_weekly_notification');
      
      if (lastNotificationStr == null) {
        // Primeira vez - agendar notificações
        await _scheduleWeeklyNotifications(userId);
        return;
      }

      final lastNotification = DateTime.parse(lastNotificationStr);
      final now = DateTime.now();
      final daysSinceLastNotification = now.difference(lastNotification).inDays;

      // Se passou mais de 7 dias, enviar notificação perdida
      if (daysSinceLastNotification >= 7) {
        await _sendWeeklySummary(userId);
      }
    } catch (e) {
      developer.log('Erro ao verificar notificações perdidas: $e', name: 'WeeklyNotificationService');
    }
  }

  /// Parar serviço de notificações semanais
  void stop() {
    _weeklyTimer?.cancel();
    _weeklyTimer = null;
    _isInitialized = false;
  }

  /// Cancelar todas as notificações semanais
  Future<void> cancelAllWeeklyNotifications() async {
    await _notificationService.cancelWeeklyNotifications();
    stop();
  }

  /// Forçar envio de resumo semanal (para testes)
  Future<void> forceSendWeeklySummary(String userId) async {
    await _sendWeeklySummary(userId);
  }

  /// Obter próxima data de notificação semanal
  DateTime getNextWeeklyNotificationDate() {
    final now = DateTime.now();
    final daysUntilSunday = (7 - now.weekday) % 7;
    final nextSunday = now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
    
    return DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      20, // 20h
      0,
    );
  }

  /// Verificar se as notificações semanais estão ativas
  bool get isActive => _isInitialized && _weeklyTimer != null;
}