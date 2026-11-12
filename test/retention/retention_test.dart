import 'dart:math';

import 'package:critter_logic/meta/achievements.dart';
import 'package:critter_logic/meta/album.dart';
import 'package:critter_logic/meta/economy.dart';
import 'package:critter_logic/meta/game_flow.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/meta/retention.dart';
import 'package:critter_logic/meta/rewards.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/analytics_service.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StatsStore stats;
  late ProgressStore progress;
  late NoAnalytics analytics;
  late Retention retention;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
    progress = await ProgressStore.open();
    analytics = NoAnalytics();
    retention = Retention(stats: stats, progress: progress, analytics: analytics, random: Random(3));
  });

  List<(String, Map<String, Object>)> logged(String name) => analytics.events.where((e) => e.$1 == name).toList();

  test('progress keys are prefixed and do not touch StatsStore keys', () async {
    await progress.increment(Counter.shares);
    await progress.recordCalendarClaim(5);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), everyElement(startsWith(ProgressStore.prefix)));
  });

  test('the calendar popup comes once a day, while the reward is unclaimed', () async {
    final morning = DateTime(2026, 12, 2, 8);
    expect(await retention.shouldShowCalendar(morning), isTrue);
    expect(await retention.shouldShowCalendar(morning.add(const Duration(hours: 2))), isFalse);
    await retention.claimCalendar(morning);
    expect(await retention.shouldShowCalendar(DateTime(2026, 12, 3, 0, 1)), isTrue);
  });

  test('claimCalendar pays into StatsStore and logs', () async {
    final coins = stats.coins;
    final r1 = await retention.claimCalendar(DateTime(2027, 1, 1), doubled: true);
    expect(r1!.totalCoins, 40);
    expect(stats.coins, coins + 40);
    expect(await retention.claimCalendar(DateTime(2027, 1, 1)), isNull);
    await retention.claimCalendar(DateTime(2027, 1, 2));
    await retention.claimCalendar(DateTime(2027, 1, 3));
    expect(stats.capsules, 1);
    for (var d = 4; d <= 7; d++) {
      await retention.claimCalendar(DateTime(2027, 1, d));
    }
    expect(stats.goldenCapsules, 1);
    expect(stats.coins, coins + 40 + 60 + 30 + 60);
    final events = logged('calendar_claim');
    expect(events, hasLength(7));
    expect(events.first.$2, {'day': 1, 'reward': 'coins', 'coins': 40, 'doubled': 1});
    expect(events.last.$2['reward'], 'golden');
  });

  test('recordEvent counts a daily for counters, achievements and event tokens', () async {
    final now = DateTime(2026, 12, 2, 9);
    final day = todayNumber(now);
    final nests = DailyResult(kind: GameKind.nests, number: day, millis: 45000);
    expect(await stats.recordDaily(nests), isTrue);
    await grantDailyRewards(stats, day);
    var update = await retention.recordEvent(DailySolved(nests), now);
    expect(update.tokens, 3);
    expect(update.newAchievements.map((a) => a.def.id), containsAll(['first_daily', 'fast_nests']));
    expect(progress.count(Counter.noHintSolves), 1);
    expect(progress.count(Counter.perfectDailies), 1);
    expect(progress.count(Counter.fastNests), 1);
    expect(progress.count(Counter.bothDailiesDays), 0);

    final pairs = DailyResult(kind: GameKind.pairs, number: day, millis: 90000, mistakes: 1);
    await stats.recordDaily(pairs);
    update = await retention.recordEvent(DailySolved(pairs), now);
    expect(update.thresholdsReached, [5]);
    expect(progress.count(Counter.fastPairs), 0);
    expect(progress.count(Counter.perfectDailies), 1);
    expect(progress.count(Counter.bothDailiesDays), 1);
    expect(retention.event.current(now)!.tokens, 6);
    expect(logged('event_threshold').single.$2, {'theme': 'polar', 'week': '2026-11-30', 'threshold': 5});
  });

  test('levels, shares and capsules', () async {
    final now = DateTime(2026, 12, 2);
    var u = await retention.recordEvent(const LevelWon(GameKind.pairs, hints: 1), now);
    expect(u.tokens, 1);
    expect(progress.count(Counter.noHintSolves), 0);
    await retention.recordEvent(const LevelWon(GameKind.pairs, hints: 0), now);
    expect(progress.count(Counter.noHintSolves), 1);
    u = await retention.recordEvent(const Shared(), now);
    expect(u.tokens, 0);
    expect(u.newAchievements.single.def.id, 'shares');
    await retention.recordEvent(const CapsuleOpened(), now);
    expect(progress.count(Counter.capsulesOpened), 1);
    expect(retention.event.current(now)!.tokens, 2);
  });

  test('claimAchievement pays and logs', () async {
    await retention.recordEvent(const Shared(), DateTime(2026, 12, 2));
    final coins = stats.coins;
    expect(await retention.claimAchievement('shares', Tier.bronze), 20);
    expect(await retention.claimAchievement('shares', Tier.bronze), isNull);
    expect(stats.coins, coins + 20);
    expect(logged('achievement_claim').single.$2, {'id': 'shares', 'tier': 'bronze', 'coins': 20});
  });

  test('event prizes pay out, the top one counts as an event completed', () async {
    final now = DateTime(2026, 12, 3);
    // All but the narwhal and penguin: the critter prize gives the penguin and completes nothing.
    for (final id in ['moose', 'bear', 'walrus', 'whale']) {
      await stats.addCritter(id);
    }
    await retention.event.addTokens(now, 30);
    final coins = stats.coins;
    expect((await retention.claimEventPrize(now, 5))!.totalCoins, 40);
    expect(stats.coins, coins + 40);
    await retention.claimEventPrize(now, 15);
    expect(stats.capsules, 1);
    final top = await retention.claimEventPrize(now, 30);
    expect(top!.reward.critter, 'penguin');
    expect(top.completedSet, isNull);
    expect(stats.owned, contains('penguin'));
    expect(progress.cosmetics, {'frame.polar'});
    expect(progress.count(Counter.eventsCompleted), 1);
    expect(await retention.claimEventPrize(now, 30), isNull);
    expect(logged('event_prize_claim').map((e) => e.$2['reward']), ['coins', 'capsule', 'critter']);
  });

  test('a granted critter that completes a set pays the set bonus, a duplicate pays coins', () async {
    for (final c in album.where((c) => c.set == 'farm' && c.id != 'goat')) {
      await stats.addCritter(c.id);
    }
    final coins = stats.coins;
    final r = await grantReward(stats, progress, const Reward(critter: 'goat'));
    expect(r.completedSet, 'farm');
    expect(stats.coins, coins + Economy.setComplete);
    final d = await grantReward(stats, progress, const Reward(critter: 'goat'));
    expect(d.duplicate, isTrue);
    expect(stats.coins, coins + Economy.setComplete + Economy.duplicateCritter);
  });
}
