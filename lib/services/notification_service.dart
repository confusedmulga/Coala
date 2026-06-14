import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Service for scheduling local notifications for note reminders.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static String? _pendingNoteId;
  static String? get pendingNoteId {
    final id = _pendingNoteId;
    _pendingNoteId = null;
    return id;
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _pendingNoteId = details.payload;
      },
    );

    // Request Android notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule a reminder notification for a note.
  Future<void> scheduleReminder({
    required String noteId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      noteId.hashCode,
      title.isNotEmpty ? title : 'Coala Reminder',
      body.isNotEmpty ? body : 'You have a reminder',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'koala_reminders',
          'Reminders',
          channelDescription: 'Note reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: noteId,
    );
  }

  /// Cancel a scheduled reminder.
  Future<void> cancelReminder(String noteId) async {
    await _plugin.cancel(noteId.hashCode);
  }

  /// Cancel all reminders.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
