import 'package:critter_logic/meta/achievements.dart';
import 'package:critter_logic/meta/album.dart';
import 'package:critter_logic/meta/economy.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StatsStore stats;
  late ProgressStore progress;
  late Achievements achievements;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
    progress = await ProgressStore.open();
    achievements = Achievements(stats, progress);
  });

  AchievementProgress of(String id) => achievements.evaluate().firstWhere((a) => a.def.id == id);

  test('ids are unique, targets increase, at most 3 tiers', () {
    expect(achievementDefs.map((d) => d.id).toSet(), hasLength(achievementDefs.length));
    expect(achievementDefs.length, greaterThanOrEqualTo(18));
    for (final d in achievementDefs) {
      expect(d.targets.length, inInclusiveRange(1, 3));
      for (var i = 1; i < d.targets.length; i++) {
        expect(d.targets[i], greaterThan(d.targets[i - 1]), reason: d.id);
      }
    }
  });

  test('a new player has nothing to claim', () {
    expect(achievements.badgeCount, 0);
    expect(of('dailies').nextTier, Tier.bronze);
    expect(of('dailies').target, 7);
    expect(of('dailies').fraction, 0);
  });

  test('tiers unlock in order with the metric', () {
    final list = Achievements.evaluateWith({Metric.dailiesSolved: 30}, {});
    final dailies = list.firstWhere((a) => a.def.id == 'dailies');
    expect(dailies.reached, [Tier.bronze, Tier.silver]);
    expect(dailies.claimable, [Tier.bronze, Tier.silver]);
    expect(dailies.nextTier, Tier.gold);
    expect(dailies.target, 100);
    expect(dailies.fraction, closeTo(0.3, 1e-9));
    expect(list.firstWhere((a) => a.def.id == 'first_daily').complete, isTrue);

    final all = Achievements.evaluateWith({Metric.dailiesSolved: 500}, {'dailies:0', 'dailies:2'});
    final d = all.firstWhere((a) => a.def.id == 'dailies');
    expect(d.claimable, [Tier.silver]);
    expect(d.complete, isTrue);
    expect(d.target, 100);
    expect(d.fraction, 1);
  });

  test('claiming pays coins once per tier and clears the badge', () async {
    for (var day = 1; day <= 7; day++) {
      await stats.recordDaily(DailyResult(kind: GameKind.nests, number: day, millis: 1000));
    }
    expect(of('first_daily').claimable, [Tier.bronze]);
    expect(of('dailies').claimable, [Tier.bronze]);
    expect(achievements.badgeCount, 2);

    final coins = stats.coins;
    expect(await achievements.claim('dailies', Tier.bronze), 20);
    expect(stats.coins, coins + 20);
    expect(await achievements.claim('dailies', Tier.bronze), isNull, reason: 'already claimed');
    expect(await achievements.claim('dailies', Tier.silver), isNull, reason: 'not reached');
    expect(await achievements.claim('nope', Tier.bronze), isNull);
    expect(await achievements.claim('first_daily', Tier.gold), isNull, reason: 'no such tier');
    expect(achievements.badgeCount, 1);
    expect(stats.coins, coins + 20);
  });

  test('metrics come from StatsStore and the counters', () async {
    for (final c in album.where((c) => c.set == 'farm')) {
      await stats.addCritter(c.id);
    }
    await stats.addCritter('panda');
    await stats.setLevel(GameKind.nests, 11);
    await progress.increment(Counter.shares, 3);
    final m = achievements.metrics();
    expect(m[Metric.crittersOwned], 7);
    expect(m[Metric.setsCompleted], 1);
    expect(m[Metric.goldenOwned], 2);
    expect(m[Metric.nestsLevels], 10);
    expect(m[Metric.pairsLevels], 0);
    expect(m[Metric.shares], 3);
    expect(of('sets').claimable, [Tier.bronze]);
    expect(of('nests_levels').claimable, [Tier.bronze]);
  });

  test('tier coins are configurable', () async {
    achievements = Achievements(stats, progress, coins: const AchievementCoins(bronze: 1, silver: 2, gold: 3));
    await progress.increment(Counter.shares, 50);
    expect(await achievements.claim('shares', Tier.gold), 3);
    expect(await achievements.claim('shares', Tier.bronze), 1);
  });

  test('lifetime achievement coins stay modest next to hint prices', () {
    const c = AchievementCoins();
    final total = achievementDefs.fold(0, (n, d) => n + d.tiers.fold(0, (m, t) => m + c.of(t)));
    // About 100 hints over months of play; most of it from long-tail gold tiers.
    expect(total, lessThan(Economy.hintCost * 110));
  });
}
