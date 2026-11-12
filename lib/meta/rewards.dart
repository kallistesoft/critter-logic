import '../services/stats_store.dart';
import 'album.dart';
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

/// What [grantReward] actually paid: [reward] plus extra coins for a critter already owned
/// ([Economy.duplicateCritter]) or a set it completed ([Economy.setComplete]).
class GrantResult {
  const GrantResult(this.reward, {this.extraCoins = 0, this.duplicate = false, this.completedSet});

  final Reward reward;
  final int extraCoins;
  final bool duplicate;
  final String? completedSet;

  int get totalCoins => reward.coins + extraCoins;
}

/// Pays [reward] into the stores. A given critter follows the capsule rules: a duplicate pays
/// [Economy.duplicateCritter] coins instead, and finishing a set pays [Economy.setComplete].
Future<GrantResult> grantReward(StatsStore stats, ProgressStore progress, Reward reward) async {
  var extra = 0;
  var duplicate = false;
  String? completed;
  if (reward.coins > 0) await stats.addCoins(reward.coins);
  for (var i = 0; i < reward.capsules; i++) {
    await stats.addCapsule();
  }
  for (var i = 0; i < reward.goldenCapsules; i++) {
    await stats.addCapsule(golden: true);
  }
  final id = reward.critter;
  if (id != null) {
    final owned = stats.owned;
    if (owned.contains(id)) {
      duplicate = true;
      extra += Economy.duplicateCritter;
    } else {
      await stats.addCritter(id);
      final set = critterById[id]?.set;
      final after = {...owned, id};
      if (set != null && album.where((c) => c.set == set).every((c) => after.contains(c.id))) {
        completed = set;
        extra += Economy.setComplete;
      }
    }
    if (extra > 0) await stats.addCoins(extra);
  }
  if (reward.cosmetic != null) await progress.addCosmetic(reward.cosmetic!);
  return GrantResult(reward, extraCoins: extra, duplicate: duplicate, completedSet: completed);
}
