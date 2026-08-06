import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles all local notifications for MediAssist: setup, permissions, and
/// scheduling medication/appointment reminders. Single shared instance.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // One notification "channel" for all MediAssist reminders.
  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'mediassist_reminders',
    'MediAssist Reminders',
    channelDescription: 'Reminders for medications and appointments',
    importance: Importance.max,
    priority: Priority.high,
  );
  static const NotificationDetails _details = NotificationDetails(android: _androidDetails);

  /// Call once when the app starts.
  Future<void> init() async {
    // MediAssist targets users in Sri Lanka — a single time zone with no
    // daylight saving — so we set the location directly. A multi-region app
    // would detect the device's time zone instead.
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    await _createChannel();
  }

  /// Create the Android notification channel explicitly at HIGH importance.
  /// Android locks a channel's importance after creation, so this must be
  /// correct from the start.
  Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'mediassist_reminders',
      'MediAssist Reminders',
      description: 'Reminders for medications and appointments',
      importance: Importance.max,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Request notification permission and ensure exact-alarm permission is
  /// granted (required on Android 12+ for scheduled reminders). If exact alarms
  /// are not yet allowed, this opens the system settings screen. Returns true
  /// if exact alarms are allowed afterwards.
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Notification permission (Android 13+).
    await android?.requestNotificationsPermission();

    // Exact-alarm permission (Android 12+).
    final canExact = await android?.canScheduleExactNotifications() ?? true;
    if (!canExact) {
      // Opens the system "Alarms & reminders" screen for this app.
      await android?.requestExactAlarmsPermission();
    }
    return await android?.canScheduleExactNotifications() ?? false;
  }

  /// Whether the OS currently allows this app to schedule exact alarms.
  Future<bool> canScheduleExact() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  /// Show a notification immediately — used to test that setup works.
  Future<void> showNow(int id, String title, String body) async {
    await _plugin.show(id, title, body, _details);
  }

  /// Schedule a one-off notification at a specific date and time
  /// (used for appointment reminders).
  Future<void> scheduleOnce(int id, String title, String body, DateTime when) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  /// Schedule a notification that repeats every day at the given time
  /// (used for medication reminders).
  Future<void> scheduleDaily(int id, String title, String body, int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (first.isBefore(now)) first = first.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      first,
      _details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily at this time
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}
