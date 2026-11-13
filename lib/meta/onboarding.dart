import '../services/stats_store.dart';
import 'progress_store.dart';

/// A calmer first session: home starts with the puzzles, and the extras appear as the player plays.
/// Derived from what the player already did, so nothing extra is saved and earlier players see everything.
class Onboarding {
  const Onboarding(this.stats);

  final StatsStore stats;

  /// Set by tests and screenshot tools to show the full home at once.
  static const skipKey = 'progress.onboarding.skip';

  bool get _skip => stats.prefs.getBool(skipKey) ?? false;

  /// Shop and Lucky Nest: after the first solved puzzle (a daily or a level).
  bool get shopOpen => _skip || stats.dailiesSolved > 0 || stats.levelsWon > 0;

  /// The login calendar: from the player's second day.
  bool calendarOpen(DateTime now) => _skip || localDay(stats.firstLaunch()) < localDay(now);

  /// The weekly event banner: after 3 solved dailies.
  bool get eventOpen => _skip || stats.dailiesSolved >= 3;
}
