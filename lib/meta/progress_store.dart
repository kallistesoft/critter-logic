import 'package:shared_preferences/shared_preferences.dart';

import '../daily.dart';

/// The local calendar day of [now] as a number (the daily puzzle number): it changes at the player's local
/// midnight and never skips or repeats across a daylight saving change. Negative before the daily epoch, which
/// is fine: only differences and equality matter here.
int localDay(DateTime now) => dailyNumberFor(now);

/// Counters the retention systems track that [StatsStore] doesn't have (login calendar, achievements, weekly
/// events, cosmetics). Kept in their own SharedPreferences keys, all prefixed with `progress.`.
class ProgressStore {
  ProgressStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<ProgressStore> open() async => ProgressStore(await SharedPreferences.getInstance());

  static const prefix = 'progress.';

  int _int(String key) => _prefs.getInt('$prefix$key') ?? 0;
  Future<void> _setInt(String key, int value) => _prefs.setInt('$prefix$key', value);
  Set<String> _set(String key) => (_prefs.getStringList('$prefix$key') ?? const []).toSet();
  Future<void> _addTo(String key, String value) => _prefs.setStringList('$prefix$key', {..._set(key), value}.toList());

  // ---- Counters (achievements) ----

  /// A counter by name (see [Counter]).
  int count(Counter counter) => _int('count.${counter.name}');
  Future<void> increment(Counter counter, [int by = 1]) => _setInt('count.${counter.name}', count(counter) + by);

  // ---- Login calendar ----

  /// Calendar rewards claimed so far, all loops (the next step is this modulo 7).
  int get calendarClaims => _int('cal.claims');

  /// Local day of the last calendar claim; null before the first one.
  int? get calendarLastDay => _prefs.getInt('${prefix}cal.lastDay');

  Future<void> recordCalendarClaim(int day) async {
    await _setInt('cal.claims', calendarClaims + 1);
    await _setInt('cal.lastDay', day);
  }

  /// Local day the calendar popup was last shown automatically (once a day).
  int? get calendarShownDay => _prefs.getInt('${prefix}cal.shownDay');
  Future<void> setCalendarShownDay(int day) => _setInt('cal.shownDay', day);

  // ---- Achievements ----

  /// Claimed tiers, as 'id:tier'.
  Set<String> get achievementClaims => _set('ach.claimed');
  Future<void> addAchievementClaim(String id, int tier) => _addTo('ach.claimed', '$id:$tier');

  /// Claimable tiers already announced to the player ("Trophy unlocked!"), as 'id:tier'.
  Set<String> get achievementsAnnounced => _set('ach.announced');
  Future<void> setAchievementsAnnounced(Set<String> value) =>
      _prefs.setStringList('${prefix}ach.announced', value.toList());

  // ---- Weekly events ----

  int eventTokens(String weekId) => _int('event.$weekId.tokens');
  Future<void> setEventTokens(String weekId, int tokens) => _setInt('event.$weekId.tokens', tokens);

  Set<int> eventClaimed(String weekId) => _set('event.$weekId.claimed').map(int.parse).toSet();
  Future<void> addEventClaimed(String weekId, int threshold) => _addTo('event.$weekId.claimed', '$threshold');

  // ---- Cosmetics ----

  /// Owned cosmetics, e.g. event frames ('frame.polar').
  Set<String> get cosmetics => _set('cosmetics');
  Future<void> addCosmetic(String id) => _addTo('cosmetics', id);
}

/// Counters behind the achievements that StatsStore can't derive.
enum Counter {
  /// Dailies and levels won without a hint.
  noHintSolves,

  /// Dailies solved in under [fastDailyMillis] (ranked time), per game.
  fastNests,
  fastPairs,

  /// Dailies with no mistake and no hint.
  perfectDailies,

  /// Days where both dailies were solved.
  bothDailiesDays,
  shares,
  capsulesOpened,

  /// Weekly events whose top reward was claimed.
  eventsCompleted,
}

/// A "fast" daily for the achievements: under a minute, penalties included.
const fastDailyMillis = 60000;
