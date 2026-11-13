import 'dart:math';

import 'package:critter_logic/l10n/app_localizations.dart';
import 'package:critter_logic/meta/achievements.dart';
import 'package:critter_logic/meta/album.dart';
import 'package:critter_logic/meta/collection.dart';
import 'package:critter_logic/meta/economy.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/meta/retention.dart';
import 'package:critter_logic/meta/set_rewards.dart';
import 'package:critter_logic/services/analytics_service.dart';
import 'package:critter_logic/services/retention_settings.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:critter_logic/ui/capsule_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const levels = CritterLevels();

  group('migration', () {
    test('the old album list becomes 1 copy each; owned is unchanged; running it again changes nothing', () async {
      SharedPreferences.setMockInitialValues({
        'album': ['owl', 'chick', 'cow'],
      });
      final stats = await StatsStore.open();
      expect(stats.critterCopies, {'owl': 1, 'chick': 1, 'cow': 1});
      expect(stats.owned, {'owl', 'chick', 'cow'});
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('critterCopies');
      expect(stored, isNotNull);
      await stats.addCritter('owl');
      await stats.migrateCritterCopies();
      await stats.migrateCritterCopies();
      expect(stats.critterCopies, {'owl': 2, 'chick': 1, 'cow': 1}, reason: 'migration never resets copies');
      final again = await StatsStore.open();
      expect(again.critterCopies, {'owl': 2, 'chick': 1, 'cow': 1});
      expect(again.owned, {'owl', 'chick', 'cow'});
    });

    test('a new player stores nothing, and the old list stays in step for older builds', () async {
      SharedPreferences.setMockInitialValues({});
      final stats = await StatsStore.open();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      expect(stats.owned, isEmpty);
      await stats.addCritter('pig');
      await stats.addCritter('pig');
      expect(stats.copies('pig'), 2);
      expect(prefs.getStringList('album'), ['pig']);
    });

    test('a critter added to the old list by an older build is picked up', () async {
      SharedPreferences.setMockInitialValues({
        'critterCopies': '{"owl":3}',
        'album': ['owl', 'duck'],
      });
      final stats = await StatsStore.open();
      expect(stats.critterCopies, {'owl': 3, 'duck': 1});
    });
  });

  group('levels', () {
    test('levels per rarity at each threshold', () {
      final expected = {
        Rarity.common: [0, 1, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5],
        Rarity.rare: [0, 1, 2, 3, 3, 4, 4, 5, 5],
        Rarity.golden: [0, 1, 2, 3, 4, 5, 5],
      };
      for (final MapEntry(key: rarity, value: byCopies) in expected.entries) {
        for (final (copies, level) in byCopies.indexed) {
          expect(levels.level(rarity, copies), level, reason: '$rarity with $copies copies');
        }
      }
      expect(levels.nextAt(Rarity.common, 2), 4);
      expect(levels.nextAt(Rarity.common, 5), isNull);
      expect(levels.at(Rarity.rare, 5), 7);
    });

    test('Remote Config: parsed with per-rarity fallback, defaults in RetentionSettings', () {
      expect(CritterLevels.parse(CritterLevels.defaultString), levels);
      expect(CritterLevels.parse(''), levels);
      final custom = CritterLevels.parse(' common = 1,3,5,8,12 ; GOLDEN=1,2,3,4,6');
      expect(custom.common, [1, 3, 5, 8, 12]);
      expect(custom.rare, levels.rare);
      expect(custom.golden, [1, 2, 3, 4, 6]);
      for (final bad in [
        'common=1,2,4,7', // 4 levels
        'common=2,3,4,5,6', // ⭐1 must be 1 copy
        'common=1,2,2,7,10', // not increasing
        'common=1,2,x,7,10',
        'common=1,2,4,7,500', // too many
        'common:1,2,4,7,10',
        'garbage',
      ]) {
        expect(CritterLevels.parse(bad), levels, reason: bad);
      }
      final d = {...RetentionSettings.defaults, 'critter_levels': 'rare=1,3,5,7,9'};
      final read = RetentionSettings.read((k) => d[k] as bool, (k) => d[k] as int, (k) => d[k] as String);
      expect(read.critterLevels.rare, [1, 3, 5, 7, 9]);
      expect(RetentionSettings.defaults['critter_levels'], CritterLevels.defaultString);
    });
  });

  group('grantCritter', () {
    late StatsStore stats;
    late ProgressStore progress;
    late NoAnalytics analytics;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      stats = await StatsStore.open();
      progress = await ProgressStore.open();
      analytics = NoAnalytics();
    });

    Future<CritterGrant> grant(String id) => grantCritter(stats, progress, id, analytics: analytics);

    test('a new critter pays nothing, finishing a set pays the set bonus (as before)', () async {
      final coins = stats.coins;
      final first = await grant('chick');
      expect((first.isNew, first.levelAfter, first.coins, first.completedSet), (true, 1, 0, null));
      for (final id in ['chicken', 'duck', 'pig', 'goat']) {
        await grant(id);
      }
      final last = await grant('cow');
      expect(last.completedSet, 'farm');
      expect(last.coins, Economy.setComplete);
      expect(stats.coins, coins + Economy.setComplete);
    });

    test('copies level up with coins, then pay 25 past ⭐5', () async {
      final paid = <(int, int, bool)>[];
      for (var i = 0; i < 12; i++) {
        final g = await grant('pig');
        paid.add((g.levelAfter, g.coins, g.leveledUp));
      }
      expect(paid, [
        (1, 0, false),
        (2, 10, true),
        (2, 0, false),
        (3, 20, true),
        (3, 0, false),
        (3, 0, false),
        (4, 30, true),
        (4, 0, false),
        (4, 0, false),
        (5, 50, true),
        (5, 25, false),
        (5, 25, false),
      ]);
      expect(stats.copies('pig'), 12);
      final ups = analytics.events.where((e) => e.$1 == 'critter_level_up').map((e) => e.$2).toList();
      expect(ups, [
        for (final l in [2, 3, 4, 5]) {'id': 'pig', 'level': l},
      ]);
      final over = critterGrantFor(stats.critterCopies, 'pig');
      expect(over.maxed, isTrue);
      expect(over.coins, Economy.duplicateCritter);
    });

    test('album_full is logged once, when the 30th critter is first owned', () async {
      for (final c in album.skip(1)) {
        await grant(c.id);
      }
      expect(analytics.events.where((e) => e.$1 == 'album_full'), isEmpty);
      final last = await grant(album.first.id);
      expect(last.albumFull, isTrue);
      await grantSetUnlocks(stats, progress);
      await grant(album.first.id);
      await grant(album[1].id);
      expect(analytics.events.where((e) => e.$1 == 'album_full'), hasLength(1));
    });
  });

  test('openCapsule prefers missing, then not yet ⭐5, then any', () {
    const commons = CapsuleOdds(rare: 0, golden: 0);
    final farmCommons = album.where((c) => c.set == 'farm' && c.rarity == Rarity.common).map((c) => c.id).toList();
    final allCommons = album.where((c) => c.rarity == Rarity.common).map((c) => c.id).toList();
    final rnd = Random(5);
    // Every common owned, all at ⭐5 except the farm ones: those come first.
    final copies = {for (final id in allCommons) id: farmCommons.contains(id) ? 2 : 10};
    copies.remove('pig');
    for (var i = 0; i < 40; i++) {
      expect(openCapsule(copies, rnd, odds: commons).critter.id, 'pig', reason: 'missing first');
    }
    copies['pig'] = 1;
    final growing = {for (var i = 0; i < 60; i++) openCapsule(copies, rnd, odds: commons).critter.id};
    expect(growing, farmCommons.toSet(), reason: 'then the ones below ⭐5');
    for (final id in farmCommons) {
      copies[id] = 10;
    }
    final any = {for (var i = 0; i < 200; i++) openCapsule(copies, rnd, odds: commons).critter.id};
    expect(any, allCommons.toSet(), reason: 'all maxed: any common');
    expect(openCapsule(copies, rnd, odds: commons).duplicate, isTrue);
  });

  test('economy simulation: 1,000 capsules, old rules vs levels', () {
    const odds = CapsuleOdds();
    const n = 1000;
    // Old rules: a missing critter of the rolled rarity if any, else any; +25 per duplicate, +200 per set.
    final oldCoins = List.filled(n, 0);
    {
      final rnd = Random(2026);
      final owned = <String>{};
      for (var i = 0; i < n; i++) {
        final rarity = odds.roll(rnd);
        final pool = album.where((c) => c.rarity == rarity).toList();
        final missing = pool.where((c) => !owned.contains(c.id)).toList();
        final from = missing.isNotEmpty ? missing : pool;
        final c = from[rnd.nextInt(from.length)];
        if (owned.contains(c.id)) {
          oldCoins[i] = Economy.duplicateCritter;
        } else {
          owned.add(c.id);
          if (album.where((x) => x.set == c.set).every((x) => owned.contains(x.id))) oldCoins[i] = Economy.setComplete;
        }
      }
    }
    // New rules: openCapsule + critterGrantFor.
    final newCoins = List.filled(n, 0);
    int? allCommonsMax, allGoldensMax;
    {
      final rnd = Random(2026);
      final copies = <String, int>{};
      bool maxed(Rarity r) => album.where((c) => c.rarity == r).every((c) => levels.level(r, copies[c.id] ?? 0) == 5);
      for (var i = 0; allCommonsMax == null || allGoldensMax == null || i < n; i++) {
        final c = openCapsule(copies, rnd, odds: odds).critter;
        final g = critterGrantFor(copies, c.id);
        copies[c.id] = g.copies;
        if (i < n) newCoins[i] = g.coins;
        if (allCommonsMax == null && maxed(Rarity.common)) allCommonsMax = i + 1;
        if (allGoldensMax == null && maxed(Rarity.golden)) allGoldensMax = i + 1;
        if (i > 100000) fail('never maxed');
      }
    }
    final oldTotal = oldCoins.reduce((a, b) => a + b), newTotal = newCoins.reduce((a, b) => a + b);
    String per100(List<int> coins) =>
        [for (var k = 0; k < n; k += 100) coins.sublist(k, k + 100).reduce((a, b) => a + b)].join(', ');
    // ignore: avoid_print
    print('economy simulation (seed 2026, $n capsules): old ${oldTotal * 100 ~/ n} coins/100 capsules, '
        'new ${newTotal * 100 ~/ n} (${((newTotal - oldTotal) * 100 / oldTotal).toStringAsFixed(1)}%)\n'
        '  old per 100: ${per100(oldCoins)}\n  new per 100: ${per100(newCoins)}\n'
        '  capsules to max all commons: $allCommonsMax, all goldens: $allGoldensMax');
    expect((newTotal - oldTotal).abs() / oldTotal, lessThanOrEqualTo(0.15));
  });

  test('achievements: first ⭐3, first ⭐5, ten at ⭐5', () async {
    SharedPreferences.setMockInitialValues({});
    final stats = await StatsStore.open();
    final progress = await ProgressStore.open();
    final retention = Retention(stats: stats, progress: progress);
    int value(String id) => retention.achievements.evaluate().firstWhere((a) => a.def.id == id).value;
    await stats.setCopies('chick', 4);
    expect(value('critter_level3'), 1);
    expect(value('critter_level5'), 0);
    for (final c in album.where((c) => c.rarity == Rarity.golden)) {
      await stats.setCopies(c.id, 5);
    }
    expect(value('critter_level3'), 6);
    expect(value('critter_level5'), 5);
    final a = retention.achievements.evaluate().firstWhere((a) => a.def.id == 'critter_level5');
    expect(a.reached, [Tier.bronze]);
    expect(a.target, 10);
  });

  test('reveal text in every language', () {
    final pig = critterById['pig']!;
    for (final (locale, texts) in [
      ('en', ['New in your album! ✨', 'Level up! ⭐3', 'Max level! +25 coins', 'One more! 5/7 to ⭐4']),
      ('fr', ['Nouveau dans ton album ! ✨', 'Niveau supérieur ! ⭐3', 'Niveau max ! +25 pièces', 'Un de plus ! 5/7 pour ⭐4']),
      ('es', ['¡Nuevo en tu álbum! ✨', '¡Sube de nivel! ⭐3', '¡Nivel máximo! +25 monedas', '¡Uno más! 5/7 para ⭐4']),
    ]) {
      final l10n = lookupAppLocalizations(Locale(locale));
      final grants = [
        critterGrantFor({}, pig.id),
        critterGrantFor({pig.id: 3}, pig.id),
        critterGrantFor({pig.id: 10}, pig.id),
        critterGrantFor({pig.id: 4}, pig.id),
      ];
      expect([for (final g in grants) critterGrantText(l10n, g, levels)], texts, reason: locale);
    }
  });
}
