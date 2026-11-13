import '../services/analytics_service.dart';
import '../services/stats_store.dart';
import 'album.dart';
import 'economy.dart';
import 'progress_store.dart';

/// The highest critter level (⭐5).
const maxCritterLevel = 5;

/// Copies needed for each critter level, by rarity: `thresholds[r][i]` is the total number of copies for ⭐(i+1).
/// The first one is always 1 (owning a critter is ⭐1). Tunable with the Remote Config string `critter_levels`.
class CritterLevels {
  const CritterLevels({
    this.common = const [1, 2, 4, 7, 10],
    this.rare = const [1, 2, 3, 5, 7],
    this.golden = const [1, 2, 3, 4, 5],
  });

  final List<int> common, rare, golden;

  /// The default `critter_levels` string.
  static const defaultString = 'common=1,2,4,7,10;rare=1,2,3,5,7;golden=1,2,3,4,5';

  List<int> of(Rarity rarity) => switch (rarity) {
        Rarity.common => common,
        Rarity.rare => rare,
        Rarity.golden => golden,
      };

  /// Level 0 (not owned) to [maxCritterLevel] for [copies] of a critter of [rarity].
  int level(Rarity rarity, int copies) => of(rarity).where((t) => copies >= t).length;

  /// The level of critter [id] given [copies] of it.
  int levelOf(String id, int copies) {
    final c = critterById[id];
    return c == null ? 0 : level(c.rarity, copies);
  }

  /// Total copies needed for the level after [level], or null at ⭐5.
  int? nextAt(Rarity rarity, int level) => level >= maxCritterLevel ? null : of(rarity)[level];

  /// Copies needed for the level [level] (1–5) itself.
  int at(Rarity rarity, int level) => of(rarity)[(level - 1).clamp(0, maxCritterLevel - 1)];

  /// Parses `critter_levels`: `rarity=t1,t2,t3,t4,t5` entries separated by `;`. Each list must have 5 strictly
  /// increasing numbers starting at 1, at most 100; a bad or missing entry keeps that rarity's default.
  static CritterLevels parse(String raw) {
    const d = CritterLevels();
    final lists = <String, List<int>>{};
    for (final entry in raw.split(';')) {
      final parts = entry.split('=');
      if (parts.length != 2) continue;
      final values = parts[1].split(',').map((v) => int.tryParse(v.trim())).toList();
      if (values.length != maxCritterLevel || values.any((v) => v == null)) continue;
      final list = values.cast<int>();
      var ok = list.first == 1 && list.last <= 100;
      for (var i = 1; i < list.length && ok; i++) {
        ok = list[i] > list[i - 1];
      }
      if (ok) lists[parts[0].trim().toLowerCase()] = List.unmodifiable(list);
    }
    return CritterLevels(
      common: lists['common'] ?? d.common,
      rare: lists['rare'] ?? d.rare,
      golden: lists['golden'] ?? d.golden,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CritterLevels &&
      _same(other.common, common) &&
      _same(other.rare, rare) &&
      _same(other.golden, golden);

  @override
  int get hashCode => Object.hash(Object.hashAll(common), Object.hashAll(rare), Object.hashAll(golden));

  static bool _same(List<int> a, List<int> b) =>
      a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((e) => e);
}

/// What one more copy of a critter gave.
class CritterGrant {
  const CritterGrant({
    required this.critter,
    required this.isNew,
    required this.levelBefore,
    required this.levelAfter,
    required this.copies,
    required this.coins,
    this.completedSet,
    this.albumFull = false,
  });

  final Critter critter;

  /// First copy: the critter joins the album.
  final bool isNew;
  final int levelBefore;
  final int levelAfter;

  /// Copies owned after this one.
  final int copies;

  /// Coins paid: a level-up bonus, [Economy.duplicateCritter] past ⭐5, plus [Economy.setComplete] for a set.
  final int coins;

  /// The set this critter finished, if any.
  final String? completedSet;

  /// This critter was the last one missing from the whole album.
  final bool albumFull;

  /// An owned critter went up a level.
  bool get leveledUp => !isNew && levelAfter > levelBefore;

  /// A copy past ⭐5: paid as [Economy.duplicateCritter] coins.
  bool get maxed => !isNew && levelBefore >= maxCritterLevel;

  /// Already owned (anything but [isNew]).
  bool get duplicate => !isNew;
}

/// What one more copy of [id] gives, given the current [copies] (pure: nothing is stored).
CritterGrant critterGrantFor(Map<String, int> copies, String id, {CritterLevels levels = const CritterLevels()}) {
  final critter = critterById[id]!;
  final before = copies[id] ?? 0;
  final levelBefore = levels.level(critter.rarity, before);
  final levelAfter = levels.level(critter.rarity, before + 1);
  final isNew = before == 0;
  var coins = 0;
  String? completed;
  var albumFull = false;
  if (isNew) {
    bool has(Critter c) => c.id == id || (copies[c.id] ?? 0) > 0;
    if (album.where((c) => c.set == critter.set).every(has)) {
      completed = critter.set;
      coins += Economy.setComplete;
    }
    albumFull = album.every(has);
  } else if (levelAfter > levelBefore) {
    coins += Economy.levelUpCoins(levelAfter);
  } else if (levelBefore >= maxCritterLevel) {
    coins += Economy.duplicateCritter;
  }
  return CritterGrant(
    critter: critter,
    isNew: isNew,
    levelBefore: levelBefore,
    levelAfter: levelAfter,
    copies: before + 1,
    coins: coins,
    completedSet: completed,
    albumFull: albumFull,
  );
}

/// The one way a critter is given (capsules, event prizes, rewards): adds a copy, pays its coins and logs
/// `critter_level_up` and, the first time the album is full, `album_full`. Set unlocks (hats, bonus coins) come
/// from `grantSetUnlocks`, which [Retention] calls after.
Future<CritterGrant> grantCritter(StatsStore stats, ProgressStore progress, String id,
    {CritterLevels levels = const CritterLevels(), AnalyticsService? analytics}) async {
  final grant = critterGrantFor(stats.critterCopies, id, levels: levels);
  await stats.addCritter(id);
  if (grant.coins > 0) await stats.addCoins(grant.coins);
  if (grant.leveledUp) await analytics?.log('critter_level_up', {'id': id, 'level': grant.levelAfter});
  // The full-album unlock is given once, so this logs once too.
  if (grant.albumFull && !progress.setRewarded('all')) await analytics?.log('album_full');
  return grant;
}
