import 'dart:math';

import 'package:critter_logic/meta/lucky_nest.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StatsStore stats;
  late ProgressStore progress;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
    progress = await ProgressStore.open();
  });

  test('one free egg a day, then paid eggs with no daily limit', () async {
    await stats.addCoins(1000);
    final nest = LuckyNest(stats, progress, random: Random(1));
    expect((await nest.draw(5))!.free, isTrue);
    for (var i = 0; i < 10; i++) {
      expect((await nest.draw(5))!.free, isFalse);
    }
    expect(nest.state(5).paidLeft, isNull);
    expect(nest.state(6).freeAvailable, isTrue);
  });

  test('Remote Config can still cap paid eggs per day', () async {
    await stats.addCoins(1000);
    final nest = LuckyNest(stats, progress, settings: const LuckySettings(paidPerDay: 3), random: Random(1));
    await nest.draw(5); // free
    for (var i = 0; i < 3; i++) {
      expect((await nest.draw(5))!.free, isFalse);
    }
    expect(await nest.draw(5), isNull);
    expect(nest.state(5).paidLeft, 0);
    expect(nest.state(6).paidLeft, 3);
  });

  test('a paid egg needs the coins', () async {
    final nest = LuckyNest(stats, progress, random: Random(2));
    await nest.draw(1); // free
    await stats.spendCoins(stats.coins);
    expect(await nest.draw(1), isNull);
    expect(stats.coins, 0, reason: 'nothing was charged');
  });

  test('odds match the settings over many draws, and average value stays under the price', () async {
    const s = LuckySettings();
    expect(s.feather, 365);
    expect(s.odds.values.reduce((a, b) => a + b), closeTo(100, 1e-9));
    final counts = {for (final p in LuckyPrize.values) p: 0};
    var coins = 0;
    final nest = LuckyNest(stats, progress, random: Random(3));
    for (var day = 0; day < 20000; day++) {
      final d = (await nest.draw(day))!; // free egg each day
      counts[d.prize] = counts[d.prize]! + 1;
      coins += d.coins;
      expect(d.coins, d.prize == LuckyPrize.coins ? inInclusiveRange(40, 120) : 0);
    }
    expect(counts[LuckyPrize.goldenCapsule]! / 20000, closeTo(0.015, 0.004));
    expect(counts[LuckyPrize.feather]! / 20000, closeTo(0.365, 0.015));
    // Value per egg: capsule 150, golden 400, hint 30.
    final value = (counts[LuckyPrize.goldenCapsule]! * 400 +
            counts[LuckyPrize.capsule]! * 150 +
            counts[LuckyPrize.hint]! * 30 +
            coins) /
        20000;
    expect(value, lessThan(s.price));
    expect(progress.freeHints, counts[LuckyPrize.hint]);
  });

  test('Remote Config parsing keeps defaults for bad values', () {
    final s = LuckySettings.parse('golden=30, capsule=100, price=80, paid_per_day=5, max_coins=10');
    expect((s.golden, s.capsule, s.price, s.paidPerDay), (30, 100, 80, 5));
    expect((s.minCoins, s.maxCoins), (40, 120), reason: 'min above max is rejected');
    final over = LuckySettings.parse('golden=900, capsule=200');
    expect((over.golden, over.capsule), (15, 120), reason: 'odds over 100% are rejected');
  });

  test('free hints are used one at a time', () async {
    await progress.addFreeHints(2);
    expect(await progress.useFreeHint(), isTrue);
    expect(await progress.useFreeHint(), isTrue);
    expect(await progress.useFreeHint(), isFalse);
  });
}
