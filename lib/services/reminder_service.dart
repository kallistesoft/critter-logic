import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reminders are planned for this local hour.
const reminderHour = 19;

/// At most this many reminders are planned ahead; they're re-planned each time the app opens, so a player who
/// ignores this many in a row hears nothing more until they come back (Unarrow's "stop after 3 ignored").
const remindersAhead = 3;

/// The local dates and times of the next reminders: today at 19:00 if it's still ahead and today's dailies aren't
/// done, then the following days at 19:00, [remindersAhead] in all.
List<DateTime> plannedReminders(DateTime now, {required bool todayDone}) {
  final today = DateTime(now.year, now.month, now.day, reminderHour);
  final first = !todayDone && now.isBefore(today) ? 0 : 1;
  return [for (var d = first; d < first + remindersAhead; d++) DateTime(now.year, now.month, now.day + d, reminderHour)];
}

/// What a reminder says; the first one mentions the streak when there is one at stake.
class ReminderText {
  const ReminderText({required this.title, required this.body, required this.streakBody});

  final String title;
  final String body;

  /// Shown on the first reminder when the player has a streak to keep, e.g. "Your 🔥 5-day streak ends tonight".
  final String? streakBody;
}

/// Local scheduled notifications (no server, no background job).
abstract class ReminderService {
  /// Asks for the notification permission (Android 13+, iOS); returns whether reminders can be shown.
  Future<bool> requestPermission();

  /// Cancels pending reminders and, when [enabled], plans the next ones.
  Future<void> plan({required bool enabled, required bool todayDone, required ReminderText text});
}

class NoReminders implements ReminderService {
  const NoReminders();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> plan({required bool enabled, required bool todayDone, required ReminderText text}) async {}
}

class LocalReminderService implements ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
        tzdata.initializeTimeZones();
        try {
          tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
        } catch (_) {
          // Unknown zone name: UTC keeps reminders working, a few hours off.
        }
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
        );
      }();

  @override
  Future<bool> requestPermission() async {
    try {
      await _init();
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _plugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      }
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    } catch (e) {
      debugPrint('reminders permission: $e');
      return false;
    }
  }

  @override
  Future<void> plan({required bool enabled, required bool todayDone, required ReminderText text}) async {
    try {
      await _init();
      await _plugin.cancelAll();
      if (!enabled) return;
      const details = NotificationDetails(
        android: AndroidNotificationDetails('daily', 'Daily puzzle',
            importance: Importance.defaultImportance, priority: Priority.defaultPriority),
        iOS: DarwinNotificationDetails(),
      );
      final times = plannedReminders(DateTime.now(), todayDone: todayDone);
      for (final (i, at) in times.indexed) {
        await _plugin.zonedSchedule(
          id: i,
          scheduledDate: tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: text.title,
          body: i == 0 && text.streakBody != null ? text.streakBody : text.body,
        );
      }
    } catch (e) {
      debugPrint('reminders plan: $e');
    }
  }
}
