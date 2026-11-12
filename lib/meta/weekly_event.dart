import 'dart:convert';
import 'dart:math';

import 'album.dart';
import 'economy.dart';
import 'progress_store.dart';
import 'rewards.dart';

/// A week's theme: [id] names it (l10n key `event_<id>`, e.g. "Panda Week") and [set] is the album set it
/// features.
class EventTheme {
  const EventTheme(this.id, this.set);

  final String id;
  final String set;

  @override
  bool operator ==(Object other) => other is EventTheme && other.id == id && other.set == set;

  @override
  int get hashCode => Object.hash(id, set);

  @override
  String toString() => 'EventTheme($id, $set)';
}

/// A threshold prize. [critter] is resolved when claimed: a critter of the event's set the player doesn't
/// have yet (common or rare; golden ones stay capsule luck), or [critterFallbackCoins] when they have them all.
/// [cosmetic] gives the event frame `frame.<theme id>`.
class EventPrize {
  const EventPrize({this.coins = 0, this.capsules = 0, this.goldenCapsules = 0, this.critter = false, this.cosmetic = false});

  final int coins;
  final int capsules;
  final int goldenCapsules;
  final bool critter;
  final bool cosmetic;

  bool get isEmpty => coins == 0 && capsules == 0 && goldenCapsules == 0 && !critter && !cosmetic;

  /// The concrete reward for [theme] given the critters [owned].
  Reward resolve(EventTheme theme, Set<String> owned, Random random) {
    String? id;
    var extra = 0;
    if (critter) {
      final missing =
          album.where((c) => c.set == theme.set && c.rarity != Rarity.golden && !owned.contains(c.id)).toList();
      if (missing.isEmpty) {
        extra = critterFallbackCoins;
      } else {
        id = missing[random.nextInt(missing.length)].id;
      }
    }
    return Reward(
      coins: coins + extra,
      capsules: capsules,
      goldenCapsules: goldenCapsules,
      critter: id,
      cosmetic: cosmetic ? 'frame.${theme.id}' : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EventPrize &&
      other.coins == coins &&
      other.capsules == capsules &&
      other.goldenCapsules == goldenCapsules &&
      other.critter == critter &&
      other.cosmetic == cosmetic;

  @override
  int get hashCode => Object.hash(coins, capsules, goldenCapsules, critter, cosmetic);
}

/// Coins in place of the event critter when the player has every common and rare of the set.
const critterFallbackCoins = Economy.duplicateCritter * 4;

/// Weekly event tuning: the built-in defaults, overridable by the Remote Config string `weekly_event_json`.
class EventSettings {
  const EventSettings({
    this.enabled = true,
    this.thresholds = const [5, 15, 30],
    this.prizes = const [EventPrize(coins: 40), EventPrize(capsules: 1), EventPrize(critter: true, cosmetic: true)],
    this.tokensPerDaily = 3,
    this.tokensPerLevel = 1,
    this.rotation = defaultRotation,
    this.weeks = const {},
  });

  /// One theme per album set, in the order the weeks go through them (from [rotationStart]).
  static const defaultRotation = [
    EventTheme('polar', 'polar'),
    EventTheme('panda', 'friends'),
    EventTheme('jungle', 'jungle'),
    EventTheme('safari', 'savanna'),
    EventTheme('farm', 'farm'),
  ];

  final bool enabled;

  /// Token counts that unlock [prizes], increasing.
  final List<int> thresholds;
  final List<EventPrize> prizes;

  /// Tokens for a first-attempt daily solve, and for a level win.
  final int tokensPerDaily;
  final int tokensPerLevel;
  final List<EventTheme> rotation;

  /// Themes for specific weeks, by the Monday's date ('2026-12-21'), ahead of the rotation.
  final Map<String, EventTheme> weeks;

  /// Parses [json] (the Remote Config value). Empty means the defaults; each invalid field falls back to its
  /// default on its own (thresholds and prizes together, since they pair up).
  static EventSettings parse(String json) {
    const d = EventSettings();
    if (json.trim().isEmpty) return d;
    Object? root;
    try {
      root = jsonDecode(json);
    } catch (_) {
      return d;
    }
    if (root is! Map) return d;

    int? intIn(Object? v, int min, int max) => v is int && v >= min && v <= max ? v : null;

    EventTheme? theme(Object? v) {
      if (v is! Map) return null;
      final id = v['theme'], set = v['set'];
      if (id is! String || !RegExp(r'^[a-z_]{1,24}$').hasMatch(id)) return null;
      if (set is! String || !albumSets.contains(set)) return null;
      return EventTheme(id, set);
    }

    EventPrize? prize(Object? v) {
      if (v is! Map) return null;
      final coins = v.containsKey('coins') ? intIn(v['coins'], 0, 1000) : 0;
      final capsules = v.containsKey('capsules') ? intIn(v['capsules'], 0, 5) : 0;
      final golden = v.containsKey('golden_capsules') ? intIn(v['golden_capsules'], 0, 1) : 0;
      final critter = v['critter'] ?? false, cosmetic = v['cosmetic'] ?? false;
      if (coins == null || capsules == null || golden == null || critter is! bool || cosmetic is! bool) return null;
      final p = EventPrize(coins: coins, capsules: capsules, goldenCapsules: golden, critter: critter, cosmetic: cosmetic);
      return p.isEmpty ? null : p;
    }

    var thresholds = d.thresholds;
    var prizes = d.prizes;
    final t = root['thresholds'], p = root['prizes'];
    if (t is List && p is List && t.isNotEmpty && t.length <= 5 && t.length == p.length) {
      final ts = t.map((v) => intIn(v, 1, 1000)).toList();
      final ps = p.map(prize).toList();
      var increasing = true;
      for (var i = 1; i < ts.length; i++) {
        if (ts[i] == null || ts[i - 1] == null || ts[i]! <= ts[i - 1]!) increasing = false;
      }
      if (increasing && !ts.contains(null) && !ps.contains(null)) {
        thresholds = ts.cast<int>();
        prizes = ps.cast<EventPrize>();
      }
    }

    var rotation = d.rotation;
    final r = root['rotation'];
    if (r is List && r.isNotEmpty) {
      final rs = r.map(theme).toList();
      if (!rs.contains(null)) rotation = rs.cast<EventTheme>();
    }

    final weeks = <String, EventTheme>{};
    final w = root['weeks'];
    if (w is Map) {
      for (final e in w.entries) {
        final key = e.key, th = theme(e.value);
        if (key is String && th != null && _isMonday(key)) weeks[key] = th;
      }
    }

    final enabled = root['enabled'];
    return EventSettings(
      enabled: enabled is bool ? enabled : d.enabled,
      thresholds: thresholds,
      prizes: prizes,
      tokensPerDaily: intIn(root['tokens_daily'], 0, 100) ?? d.tokensPerDaily,
      tokensPerLevel: intIn(root['tokens_level'], 0, 100) ?? d.tokensPerLevel,
      rotation: rotation,
      weeks: weeks,
    );
  }

  static bool _isMonday(String date) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(date);
    if (m == null) return false;
    final d = DateTime.utc(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    return weekId(d) == date && d.weekday == DateTime.monday;
  }
}

/// The Monday the default rotation starts from (its first theme that week).
final rotationStart = DateTime(2026, 11, 30);

/// 'yyyy-mm-dd' of [date]'s calendar date.
String weekId(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// This week's event, for the banner and the event screen.
class WeeklyEventState {
  const WeeklyEventState({
    required this.weekId,
    required this.theme,
    required this.startsAt,
    required this.endsAt,
    required this.thresholds,
    required this.prizes,
    required this.tokens,
    required this.claimed,
  });

  /// The Monday's date, 'yyyy-mm-dd'; progress is kept per week.
  final String weekId;
  final EventTheme theme;

  /// Local midnight starting Monday, and local midnight ending Sunday (the next Monday).
  final DateTime startsAt;
  final DateTime endsAt;
  final List<int> thresholds;
  final List<EventPrize> prizes;
  final int tokens;
  final Set<int> claimed;

  List<int> get reached => [for (final t in thresholds) if (tokens >= t) t];
  List<int> get claimable => [for (final t in reached) if (!claimed.contains(t)) t];

  /// Next threshold to reach, or null when all are.
  int? get nextThreshold => thresholds.where((t) => tokens < t).firstOrNull;

  /// 0..1 towards the top threshold (the banner's progress bar).
  double get fraction => (tokens / thresholds.last).clamp(0, 1).toDouble();

  EventPrize prizeFor(int threshold) => prizes[thresholds.indexOf(threshold)];

  /// Time left, for "ends in 2d 5h".
  Duration remaining(DateTime now) => endsAt.difference(now);
}

/// Monday-to-Sunday themed weeks (local time) cycling through the album sets. Solving dailies and levels earns
/// tokens; thresholds give prizes, the top one a critter of the featured set and the event frame.
class WeeklyEvent {
  WeeklyEvent(this._progress, {this.settings = const EventSettings()});

  final ProgressStore _progress;
  final EventSettings settings;

  /// The theme of the week starting [monday] (a local date).
  EventTheme themeFor(DateTime monday) {
    final id = weekId(monday);
    final override = settings.weeks[id];
    if (override != null) return override;
    final weeks = (localDay(monday) - localDay(rotationStart)) ~/ 7;
    return settings.rotation[weeks % settings.rotation.length];
  }

  /// This week's event, or null when events are off.
  WeeklyEventState? current(DateTime now) {
    if (!settings.enabled) return null;
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - DateTime.monday));
    final id = weekId(monday);
    return WeeklyEventState(
      weekId: id,
      theme: themeFor(monday),
      startsAt: monday,
      endsAt: DateTime(monday.year, monday.month, monday.day + 7),
      thresholds: settings.thresholds,
      prizes: settings.prizes,
      tokens: _progress.eventTokens(id),
      claimed: _progress.eventClaimed(id),
    );
  }

  /// Adds [n] tokens to this week; returns the thresholds this crossed (for analytics and a toast).
  Future<List<int>> addTokens(DateTime now, int n) async {
    final s = current(now);
    if (s == null || n <= 0) return const [];
    final after = s.tokens + n;
    await _progress.setEventTokens(s.weekId, after);
    return [for (final t in s.thresholds) if (s.tokens < t && after >= t) t];
  }

  /// Claims the prize of [threshold] this week, resolved for the critters [owned]. Null if not reached, already
  /// claimed, or not a threshold. The caller pays it with [grantReward].
  Future<Reward?> claim(DateTime now, int threshold, Set<String> owned, Random random) async {
    final s = current(now);
    if (s == null || !s.claimable.contains(threshold)) return null;
    await _progress.addEventClaimed(s.weekId, threshold);
    return s.prizeFor(threshold).resolve(s.theme, owned, random);
  }
}
