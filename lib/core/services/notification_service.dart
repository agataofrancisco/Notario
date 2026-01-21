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

    _initialized = true;
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
}
