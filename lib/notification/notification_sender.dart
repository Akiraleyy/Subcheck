import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data_access/models/reminder.dart';

/// LLD class: NotificationSender. The only class that talks to the phone's
/// notification system.
///
/// Notifications are LOCAL: the phone itself shows them at the planned time,
/// so they work without internet. They are supported on Android and iOS; on
/// other targets (Windows, web) every method quietly does nothing, so you can
/// still run and test the rest of the app there.
class NotificationSender {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Set from Settings > Notifications. When false nothing is scheduled.
  bool enabled = true;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'subcheck_reminders',
      'Subscription reminders',
      channelDescription: 'Upcoming payments, renewals and review reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<bool> _ensureInitialized() async {
    if (!_supported) return false;
    if (_initialized) return true;
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ));
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('Notifications could not start: $e');
      return false;
    }
  }

  /// Asks the user for permission to show notifications (Android 13+ and iOS).
  Future<bool> requestPermission() async {
    if (!await _ensureInitialized()) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
      }
      return true;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  /// Hands the reminder to the phone so it shows it at [Reminder.scheduledDate].
  /// (In the LLD this method is called showNotification.)
  Future<void> showNotification(Reminder reminder) async {
    if (!enabled) return;
    if (!await _ensureInitialized()) return;
    if (!reminder.scheduledDate.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        _notificationId(reminder),
        reminder.title,
        reminder.body,
        // Converting an exact moment to UTC keeps it the same moment, so the
        // reminder still fires at 9:00 AM local time.
        tz.TZDateTime.from(reminder.scheduledDate, tz.UTC),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Could not schedule notification: $e');
    }
  }

  /// Added: removes one planned notification from the phone.
  Future<void> cancel(Reminder reminder) async {
    if (!await _ensureInitialized()) return;
    try {
      await _plugin.cancel(_notificationId(reminder));
    } catch (e) {
      debugPrint('Could not cancel notification: $e');
    }
  }

  /// Added: removes every planned notification (used when notifications are
  /// switched off in Settings).
  Future<void> cancelAll() async {
    if (!await _ensureInitialized()) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Could not cancel notifications: $e');
    }
  }

  /// The phone needs a whole number as the notification id. The first 8
  /// characters of the reminder's UUID are hexadecimal, so they make a
  /// number that is always the same for the same reminder.
  int _notificationId(Reminder reminder) =>
      int.parse(reminder.id.substring(0, 8), radix: 16) & 0x7fffffff;
}
