import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Serviço de notificações locais
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(String payload)? _onPayloadTap;

  /// Inicializar serviço de notificações
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();

    // Configurações Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permissões no Android 13+ (API 33+)
    await _requestPermissions();

    _initialized = true;
  }

  /// Solicitar permissões necessárias
  Future<void> _requestPermissions() async {
    // Android 13+ requer permissão explícita para notificações
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Solicitar permissão para notificações
      await androidPlugin.requestNotificationsPermission();

      // Solicitar permissão para alarmes exatos (Android 12+)
      await androidPlugin.requestExactAlarmsPermission();
    }

    // iOS - permissões já solicitadas na inicialização
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Registrar callback para quando o usuário tocar na notificação.
  /// Exemplo de payloads:
  /// - task:<taskId>
  /// - note:<noteId>
  /// - execution:<taskId>
  void setOnPayloadTap(void Function(String payload) handler) {
    _onPayloadTap = handler;
  }

  /// Callback quando notificação é tocada
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _onPayloadTap?.call(payload);
  }

  /// Agendar notificação de tarefa (15 min antes)
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime startTime,
    int minutesBefore = 15,
  }) async {
    if (!_initialized) await initialize();

    final reminderTime = startTime.subtract(Duration(minutes: minutesBefore));

    // Não agendar se já passou
    if (reminderTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      taskId.hashCode, // ID único baseado no taskId
      'Tarefa em 15 minutos',
      title,
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Lembretes de Tarefas',
          channelDescription: 'Notificações para lembrar de tarefas próximas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task:$taskId',
    );
  }

  /// Agendar notificação de nota
  Future<void> scheduleNoteReminder({
    required String noteId,
    required String title,
    required String content,
    required DateTime reminderTime,
  }) async {
    if (!_initialized) await initialize();

    // Não agendar se já passou
    if (reminderTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      noteId.hashCode,
      title,
      content,
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'note_reminders',
          'Lembretes de Notas',
          channelDescription: 'Notificações para lembretes de notas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'note:$noteId',
    );
  }

  /// Agendar notificações do timer de execução
  Future<void> scheduleTimerNotifications({
    required String taskId,
    required String title,
    required DateTime endTime,
  }) async {
    if (!_initialized) await initialize();

    // Notificação de término (0 minutos restantes)
    if (endTime.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        'end_$taskId'.hashCode,
        'Tempo esgotado! ⏳',
        'O tempo para "$title" terminou.',
        tz.TZDateTime.from(endTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'timer_end',
            'Término de Timer',
            channelDescription: 'Notificações de término de atividade',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'timer_end:$taskId',
      );
    }

    // Aviso de 5 minutos restantes (se houver tempo)
    final warningTime = endTime.subtract(const Duration(minutes: 5));
    if (warningTime.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        'warn_$taskId'.hashCode,
        '5 minutos restantes ⏱️',
        'Finalize "$title" em breve.',
        tz.TZDateTime.from(warningTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'timer_warning',
            'Aviso de Timer',
            channelDescription: 'Avisos de pouco tempo restante',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'timer_warn:$taskId',
      );
    }
  }

  /// Cancelar notificação
  Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
  }

  /// Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Mostrar notificação imediata
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate',
          'Notificações Imediatas',
          channelDescription: 'Notificações instantâneas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Solicitar permissões (iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return result ?? true;
  }

  /// Agendar notificações semanais (domingo às 20h)
  Future<void> scheduleWeeklyNotifications({
    required String userId,
    required Map<String, dynamic> weeklyStats,
  }) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();

    // Calcular próximo domingo às 20h
    final daysUntilSunday = (7 - now.weekday) % 7;
    final nextSunday =
        now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
    final notificationTime = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      20, // 20h
      0,
    );

    // Se já passou das 20h de domingo, agendar para próximo domingo
    final finalTime = notificationTime.isBefore(now)
        ? notificationTime.add(const Duration(days: 7))
        : notificationTime;

    final tarefasDefinidas = weeklyStats['tarefasDefinidas'] as int;
    final tarefasConcluidas = weeklyStats['tarefasConcluidas'] as int;
    final percentualConclusao = weeklyStats['percentualConclusao'] as int;

    String title = 'Resumo Semanal 📊';
    String body;

    if (tarefasDefinidas == 0) {
      body =
          'Nenhuma tarefa foi definida esta semana. Que tal planejar a próxima?';
    } else {
      body =
          'Definidas: $tarefasDefinidas | Concluídas: $tarefasConcluidas ($percentualConclusao%)';

      if (percentualConclusao >= 80) {
        body += ' 🎉 Excelente semana!';
      } else if (percentualConclusao >= 60) {
        body += ' 👍 Boa semana!';
      } else if (percentualConclusao >= 40) {
        body += ' 💪 Pode melhorar!';
      } else {
        body += ' 🎯 Foque na próxima semana!';
      }
    }

    await _notifications.zonedSchedule(
      'weekly_summary'.hashCode,
      title,
      body,
      tz.TZDateTime.from(finalTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_summary',
          'Resumo Semanal',
          channelDescription:
              'Notificações com resumo semanal de produtividade',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'weekly_summary:$userId',
    );
  }

  /// Agendar notificação de planejamento semanal (domingo às 19h)
  Future<void> scheduleWeeklyPlanningReminder({
    required String userId,
  }) async {
    if (!_initialized) await initialize();

    final now = DateTime.now();

    // Calcular próximo domingo às 19h
    final daysUntilSunday = (7 - now.weekday) % 7;
    final nextSunday =
        now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
    final notificationTime = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      19, // 19h
      0,
    );

    // Se já passou das 19h de domingo, agendar para próximo domingo
    final finalTime = notificationTime.isBefore(now)
        ? notificationTime.add(const Duration(days: 7))
        : notificationTime;

    await _notifications.zonedSchedule(
      'weekly_planning'.hashCode,
      'Hora de Planejar! 📅',
      'Reserve um tempo para organizar as tarefas da próxima semana.',
      tz.TZDateTime.from(finalTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_planning',
          'Planejamento Semanal',
          channelDescription: 'Lembretes para planejar a semana',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'weekly_planning:$userId',
    );
  }

  /// Cancelar notificações semanais
  Future<void> cancelWeeklyNotifications() async {
    await _notifications.cancel('weekly_summary'.hashCode);
    await _notifications.cancel('weekly_planning'.hashCode);
  }
}
