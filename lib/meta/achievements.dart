import '../puzzles/puzzle.dart';
import '../services/stats_store.dart';
import 'album.dart';
import 'collection.dart';
import 'progress_store.dart';

enum Tier { bronze, silver, gold }

/// What an achievement measures.
enum Metric {
  dailiesSolved,
  bestStreak,
  nestsLevels,
  pairsLevels,
  levelsWon,
  crittersOwned,
  setsCompleted,
  goldenOwned,
  crittersLevel3,
  crittersLevel5,
  noHintSolves,
  fastNests,
  fastPairs,
  perfectDailies,
  bothDailiesDays,
  shares,
  capsulesOpened,
  calendarDays,
  eventsCompleted,
}

/// An achievement and its tier targets (1 to 3: bronze, then silver, then gold).
class AchievementDef {
  const AchievementDef(this.id, this.metric, this.targets);

  /// Stable id: analytics, saved claims and the l10n key (`achievement_<id>`).
  final String id;
  final Metric metric;
  final List<int> targets;

  List<Tier> get tiers => Tier.values.take(targets.length).toList();
}

/// 20 achievements, 55 tiers. Fast = a daily under a minute with penalties; perfect = no mistake and no hint.
const achievementDefs = <AchievementDef>[
  AchievementDef('first_daily', Metric.dailiesSolved, [1]),
  AchievementDef('dailies', Metric.dailiesSolved, [7, 30, 100]),
  AchievementDef('streak', Metric.bestStreak, [3, 7, 30]),
  AchievementDef('both_dailies', Metric.bothDailiesDays, [3, 15, 50]),
  AchievementDef('perfect_daily', Metric.perfectDailies, [5, 25, 100]),
  AchievementDef('fast_nests', Metric.fastNests, [1, 10, 50]),
  AchievementDef('fast_pairs', Metric.fastPairs, [1, 10, 50]),
  AchievementDef('nests_levels', Metric.nestsLevels, [10, 50, 200]),
  AchievementDef('pairs_levels', Metric.pairsLevels, [10, 50, 200]),
  AchievementDef('levels', Metric.levelsWon, [25, 100, 500]),
  AchievementDef('no_hint', Metric.noHintSolves, [10, 50, 200]),
  AchievementDef('critters', Metric.crittersOwned, [10, 20, 30]),
  AchievementDef('sets', Metric.setsCompleted, [1, 3, 5]),
  AchievementDef('golden', Metric.goldenOwned, [1, 3, 5]),
  AchievementDef('critter_level3', Metric.crittersLevel3, [1]),
  AchievementDef('critter_level5', Metric.crittersLevel5, [1, 10]),
  AchievementDef('capsules', Metric.capsulesOpened, [10, 50, 150]),
  AchievementDef('shares', Metric.shares, [1, 10, 50]),
  AchievementDef('calendar', Metric.calendarDays, [7, 30, 100]),
  AchievementDef('events', Metric.eventsCompleted, [1, 4, 12]),
];

/// Coins per tier, from Remote Config (`achievement_*_coins`).
class AchievementCoins {
  const AchievementCoins({this.bronze = 20, this.silver = 50, this.gold = 100});

  final int bronze;
  final int silver;
  final int gold;

  int of(Tier tier) => switch (tier) { Tier.bronze => bronze, Tier.silver => silver, Tier.gold => gold };
}

/// One achievement's state for the trophy screen.
class AchievementProgress {
  const AchievementProgress(this.def, {required this.value, required this.claimed});

  final AchievementDef def;

  /// Current metric value (not capped).
  final int value;
  final Set<Tier> claimed;

  /// Tiers whose target is met.
  List<Tier> get reached => [for (final t in def.tiers) if (value >= def.targets[t.index]) t];

  /// Reached but not claimed yet: these show the badge.
  List<Tier> get claimable => [for (final t in reached) if (!claimed.contains(t)) t];

  /// The next tier to reach, or null when all are reached.
  Tier? get nextTier => reached.length < def.targets.length ? def.tiers[reached.length] : null;

  /// Target of the next tier, or of the last one when all are reached (for the progress bar).
  int get target => def.targets[nextTier?.index ?? def.targets.length - 1];

  /// 0..1 towards [target].
  double get fraction => target == 0 ? 1 : (value / target).clamp(0, 1).toDouble();

  bool get complete => nextTier == null;
}

/// Achievements evaluated from [StatsStore] and the [ProgressStore] counters.
class Achievements {
  Achievements(this._stats, this._progress, {this.coins = const AchievementCoins(), this.levels = const CritterLevels()});

  final StatsStore _stats;
  final ProgressStore _progress;
  final AchievementCoins coins;
  final CritterLevels levels;

  /// Every metric's current value.
  Map<Metric, int> metrics() {
    final copies = _stats.critterCopies;
    final owned = copies.keys.toSet();
    int levels(GameKind kind) => _stats.level(kind) - 1;
    int atLevel(int level) => album.where((c) => this.levels.level(c.rarity, copies[c.id] ?? 0) >= level).length;
    return {
      Metric.dailiesSolved: _stats.dailiesSolved,
      Metric.bestStreak: _stats.bestStreak,
      Metric.nestsLevels: levels(GameKind.nests),
      Metric.pairsLevels: levels(GameKind.pairs),
      Metric.levelsWon: _stats.levelsWon,
      Metric.crittersOwned: album.where((c) => owned.contains(c.id)).length,
      Metric.setsCompleted:
          albumSets.where((s) => album.where((c) => c.set == s).every((c) => owned.contains(c.id))).length,
      Metric.goldenOwned: album.where((c) => c.rarity == Rarity.golden && owned.contains(c.id)).length,
      Metric.crittersLevel3: atLevel(3),
      Metric.crittersLevel5: atLevel(5),
      Metric.noHintSolves: _progress.count(Counter.noHintSolves),
      Metric.fastNests: _progress.count(Counter.fastNests),
      Metric.fastPairs: _progress.count(Counter.fastPairs),
      Metric.perfectDailies: _progress.count(Counter.perfectDailies),
      Metric.bothDailiesDays: _progress.count(Counter.bothDailiesDays),
      Metric.shares: _progress.count(Counter.shares),
      Metric.capsulesOpened: _progress.count(Counter.capsulesOpened),
      Metric.calendarDays: _progress.calendarClaims,
      Metric.eventsCompleted: _progress.count(Counter.eventsCompleted),
    };
  }

  /// All achievements with progress, in display order.
  List<AchievementProgress> evaluate() => evaluateWith(metrics(), _progress.achievementClaims);

  /// Pure evaluation, for tests: [claims] holds 'id:tierIndex'.
  static List<AchievementProgress> evaluateWith(Map<Metric, int> metrics, Set<String> claims) => [
        for (final def in achievementDefs)
          AchievementProgress(def,
              value: metrics[def.metric] ?? 0,
              claimed: {for (final t in def.tiers) if (claims.contains('${def.id}:${t.index}')) t}),
      ];

  /// Number of claimable tiers: the trophy button's badge.
  int get badgeCount => evaluate().fold(0, (n, a) => n + a.claimable.length);

  /// Claims [tier] of achievement [id] and pays its coins. Returns the coins, or null if the tier isn't reached,
  /// was already claimed, or doesn't exist.
  Future<int?> claim(String id, Tier tier) async {
    final progress = evaluate().where((a) => a.def.id == id).firstOrNull;
    if (progress == null || !progress.claimable.contains(tier)) return null;
    final amount = coins.of(tier);
    await _progress.addAchievementClaim(id, tier.index);
    await _stats.addCoins(amount);
    return amount;
  }
}
