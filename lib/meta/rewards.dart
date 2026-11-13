import '../services/analytics_service.dart';
import '../services/stats_store.dart';
import 'album.dart';
import 'collection.dart';
import 'economy.dart';
import 'progress_store.dart';

/// Something the retention systems give: coins, capsules, a specific critter, a cosmetic, or a mix.
class Reward {
  const Reward({this.coins = 0, this.capsules = 0, this.goldenCapsules = 0, this.critter, this.cosmetic});

  const Reward.coins(int amount) : this(coins: amount);
  const Reward.capsule() : this(capsules: 1);
  const Reward.goldenCapsule() : this(goldenCapsules: 1);

  final int coins;
  final int capsules;

  /// Capsules that always hold a golden critter.
  final int goldenCapsules;

  /// A critter id from the [album], given directly.
  final String? critter;

  /// A cosmetic id, e.g. 'frame.polar'.
  final String? cosmetic;

  /// The same reward with its coins doubled (rewarded ad).
  Reward doubled() =>
      Reward(coins: coins * 2, capsules: capsules, goldenCapsules: goldenCapsules, critter: critter, cosmetic: cosmetic);

  /// Short kind for analytics: 'golden', 'capsule', 'critter', 'cosmetic' or 'coins'.
  String get kind => goldenCapsules > 0
      ? 'golden'
      : capsules > 0
          ? 'capsule'
          : critter != null
              ? 'critter'
              : cosmetic != null
                  ? 'cosmetic'
                  : 'coins';

  @override
  bool operator ==(Object other) =>
      other is Reward &&
      other.coins == coins &&
      other.capsules == capsules &&
      other.goldenCapsules == goldenCapsules &&
      other.critter == critter &&
      other.cosmetic == cosmetic;

  @override
  int get hashCode => Object.hash(coins, capsules, goldenCapsules, critter, cosmetic);

  @override
  String toString() => 'Reward(coins: $coins, capsules: $capsules, golden: $goldenCapsules, '
      'critter: $critter, cosmetic: $cosmetic)';
}

/// What [grantReward] actually paid: [reward] plus the coins its critter gave ([critterGrant]: a level-up bonus,
/// [Economy.duplicateCritter] past ⭐5, or [Economy.setComplete] for a finished set).
class GrantResult {
  const GrantResult(this.reward, {this.critterGrant});

  final Reward reward;
  final CritterGrant? critterGrant;

  int get extraCoins => critterGrant?.coins ?? 0;
  bool get duplicate => critterGrant?.duplicate ?? false;
  String? get completedSet => critterGrant?.completedSet;

  int get totalCoins => reward.coins + extraCoins;
}

/// Pays [reward] into the stores. A given critter goes through [grantCritter], like a capsule's.
Future<GrantResult> grantReward(StatsStore stats, ProgressStore progress, Reward reward,
    {CritterLevels levels = const CritterLevels(), AnalyticsService? analytics}) async {
  if (reward.coins > 0) await stats.addCoins(reward.coins);
  for (var i = 0; i < reward.capsules; i++) {
    await stats.addCapsule();
  }
  for (var i = 0; i < reward.goldenCapsules; i++) {
    await stats.addCapsule(golden: true);
  }
  final id = reward.critter;
  final grant = id == null || critterById[id] == null
      ? null
      : await grantCritter(stats, progress, id, levels: levels, analytics: analytics);
  if (reward.cosmetic != null) await progress.addCosmetic(reward.cosmetic!);
  return GrantResult(reward, critterGrant: grant);
}
