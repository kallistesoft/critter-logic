import '../daily.dart';
import '../l10n/app_localizations.dart';
import '../services/reminder_service.dart';
import '../services/stats_store.dart';

/// Re-plans the daily reminders: on every app open and after a daily is solved, so they skip a finished day and
/// stop after 3 ignored ones.
Future<void> planReminders(StatsStore stats, ReminderService reminders, AppLocalizations l10n, DateTime now) {
  final today = dailyNumberFor(now);
  final streak = stats.streak(today);
  return reminders.plan(
    enabled: stats.remindersOn,
    todayDone: stats.allDailiesDone(today),
    text: ReminderText(
      title: l10n.reminderTitle,
      body: l10n.reminderBody,
      streakBody: streak > 0 && !stats.dayCounts(today) ? l10n.reminderStreak(streak) : null,
      channel: l10n.reminderChannel,
    ),
  );
}
