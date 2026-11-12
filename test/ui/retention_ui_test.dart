import 'dart:math';

import 'package:critter_logic/meta/album.dart';
import 'package:critter_logic/meta/economy.dart';
import 'package:critter_logic/meta/lucky_nest.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/meta/retention.dart';
import 'package:critter_logic/meta/set_rewards.dart';
import 'package:critter_logic/meta/shop.dart';
import 'package:critter_logic/services/coin_store_service.dart';
import 'package:critter_logic/services/retention_settings.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:critter_logic/ui/retention_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class FakeCoinStore extends CoinStoreService {
  FakeCoinStore(this._packs);

  final List<(CoinPack, String)> _packs;
  final bought = <String>[];

  @override
  List<(CoinPack, String)> get packs => _packs;

  @override
  Future<void> buy(CoinPack pack) async => bought.add(pack.productId);
}

void main() {
  late StatsStore stats;
  late ProgressStore progress;
  late TestApp app;
  late int start;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'flutter.tutorial.nests': true, 'flutter.tutorial.pairs': true});
    stats = await StatsStore.open();
    progress = ProgressStore(stats.prefs);
    app = TestApp(stats);
    start = stats.coins;
  });

  Retention retentionWith(RetentionSettings settings) =>
      Retention(stats: stats, progress: progress, settings: settings, analytics: app.analytics, random: Random(4));

  Future<void> open(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  group('login calendar', () {
    testWidgets('pops up once a day and pays the claim', (tester) async {
      await app.pump(tester, calendar: true);
      expect(find.byKey(const Key('calendar')), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('calendarClaim')));
      await tester.pumpAndSettle();
      expect(stats.coins, start + 20);
      expect(find.byKey(const Key('paw')), findsOneWidget);
      expect(find.text('Come back tomorrow for the next gift!'), findsOneWidget);
      await tester.tap(find.byKey(const Key('calendarClose')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendar')), findsNothing);

      // Resuming the same day: no popup.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendar')), findsNothing);

      // The next day it comes back, on day 2.
      app.now = app.now.add(const Duration(days: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calendar')), findsOneWidget);
      expect(find.byKey(const Key('calendarDouble')), findsOneWidget);
      // x2 with a rewarded ad doubles the 60 coins.
      await tester.tap(find.byKey(const Key('calendarDouble')));
      await tester.pumpAndSettle();
      expect(app.ads.rewarded, 1);
      expect(stats.coins, start + 20 + 120);
      expect(app.analytics.events.any((e) => e.$1 == 'ad_reward' && e.$2['reward'] == 'calendar_double'), isTrue);
    });

    testWidgets('capsule days have no x2, and the home button reopens it', (tester) async {
      await progress.recordCalendarClaim(localDay(app.now) - 1);
      await progress.recordCalendarClaim(localDay(app.now) - 1);
      await app.pump(tester);
      expect(find.byKey(const Key('calendar')), findsNothing);
      expect(find.byKey(const Key('calendarDot')), findsOneWidget);
      await open(tester, const Key('calendarButton'));
      expect(find.byKey(const Key('calendarDouble')), findsNothing);
      await tester.tap(find.byKey(const Key('calendarClaim')));
      await tester.pumpAndSettle();
      expect(stats.capsules, 1);
    });
  });

  testWidgets('a trophy claim adds its coins', (tester) async {
    await progress.increment(Counter.shares);
    await app.pump(tester);
    expect(find.byKey(const Key('trophyBadge')), findsOneWidget);
    await open(tester, const Key('trophies'));
    expect(find.text('Show-off'), findsOneWidget);
    await tester.tap(find.byKey(const Key('claim-shares')).hitTestable().first);
    await tester.pumpAndSettle();
    expect(stats.coins, start + 20);
    expect(find.byKey(const Key('claim-shares')), findsNothing);
  });

  group('shop', () {
    testWidgets('buys a capsule and a hat, equips and takes it off', (tester) async {
      await stats.addCoins(1000);
      await app.pump(tester);
      await open(tester, const Key('shopStall'));
      expect(find.byKey(const Key('tab-coins')), findsNothing, reason: 'no coin packs without a store');
      final today = 12;
      final shop = Shop(stats, progress);
      final capsulePrice = shop.priceToday(shopItemById['capsule']!, today);
      await tester.tap(find.byKey(const Key('buy-capsule')));
      await tester.pumpAndSettle();
      expect(stats.capsules, 1);
      expect(stats.coins, start + 1000 - capsulePrice);

      await open(tester, const Key('tab-hats'));
      final before = stats.coins;
      final hatPrice = shop.priceToday(shopItemById['hat.party']!, today);
      await tester.ensureVisible(find.byKey(const Key('buy-hat.party')));
      await tester.tap(find.byKey(const Key('buy-hat.party')));
      await tester.pumpAndSettle();
      expect(stats.coins, before - hatPrice);
      expect(shop.equippedHat, 'hat.party');
      expect(find.text('Equipped'), findsOneWidget);
      await tester.tap(find.byKey(const Key('equip-hat.party')));
      await tester.pumpAndSettle();
      expect(shop.equippedHat, isNull);
      await tester.tap(find.byKey(const Key('equip-hat.party')));
      await tester.pumpAndSettle();
      expect(shop.equippedHat, 'hat.party');
    });

    testWidgets('not enough coins says how many are missing', (tester) async {
      await app.pump(tester);
      await open(tester, const Key('shopStall'));
      await tester.tap(find.byKey(const Key('buy-capsule')));
      await tester.pumpAndSettle();
      expect(find.textContaining('more coins'), findsOneWidget);
      expect(stats.capsules, 0);
    });

    testWidgets('coin packs sit behind the grown-up check', (tester) async {
      final store = FakeCoinStore([for (final p in coinPacks) (p, '\$${p.coins / 100}')]);
      app.coinStore = store;
      await app.pump(tester);
      await open(tester, const Key('shopStall'));
      await open(tester, const Key('tab-coins'));
      expect(find.text('Best value'), findsOneWidget);
      expect(find.text('+15%'), findsWidgets);
      await tester.tap(find.byKey(const Key('buyPack-coins_1000')));
      await tester.pumpAndSettle();
      expect(find.text('Ask a grown-up'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('parentAnswer')), '1');
      await tester.tap(find.byKey(const Key('parentOk')));
      await tester.pumpAndSettle();
      expect(store.bought, isEmpty);
    });
  });

  group('Lucky Nest', () {
    testWidgets('a free egg, then eggs for 50 coins; odds listed', (tester) async {
      // Every egg holds a hint, so the outcome is known.
      app.retention = ValueNotifier(retentionWith(const RetentionSettings(lucky: LuckySettings(golden: 0, capsule: 0, coins: 0, hint: 1000))));
      await stats.spendCoins(start);
      await stats.addCoins(60);
      await app.pump(tester);
      expect(find.byKey(const Key('luckyFreeBadge')), findsOneWidget);
      await open(tester, const Key('luckyNest'));
      expect(find.text('Free egg'), findsOneWidget);
      await tester.tap(find.byKey(const Key('egg-0')));
      await tester.pumpAndSettle();
      expect(find.text('+1 free hint'), findsOneWidget);
      expect(progress.freeHints, 1);
      expect(stats.coins, 60);
      await tester.tap(find.byKey(const Key('luckyAgain')));
      await tester.pumpAndSettle();
      expect(find.text('50'), findsOneWidget);
      await tester.tap(find.byKey(const Key('luckyDraw')));
      await tester.pumpAndSettle();
      expect(stats.coins, 10);
      expect(progress.freeHints, 2);

      await tester.tap(find.byKey(const Key('luckyOdds')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('oddsSheet')), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('default odds on the sheet; only the free egg where paid eggs are off', (tester) async {
      app.retention = ValueNotifier(retentionWith(const RetentionSettings(lucky: LuckySettings(paidEnabled: false))));
      await app.pump(tester);
      await open(tester, const Key('luckyNest'));
      expect(find.byKey(const Key('egg-0')), findsOneWidget);
      expect(find.byKey(const Key('egg-1')), findsNothing);
      await tester.tap(find.byKey(const Key('luckyOdds')));
      await tester.pumpAndSettle();
      expect(find.text('1.5%'), findsOneWidget);
      expect(find.text('12%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('36.5%'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('luckyDraw')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('luckyAgain')), findsNothing);
      expect(find.text('Next free egg tomorrow'), findsOneWidget);
    });
  });

  testWidgets('the hint uses free hints first, then coins', (tester) async {
    await progress.addFreeHints(1);
    await stats.spendCoins(start);
    await stats.addCoins(100);
    await app.pump(tester);
    await open(tester, const Key('daily-nests'));
    expect(find.byKey(const Key('freeHints')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hint')));
    await tester.pumpAndSettle();
    expect(progress.freeHints, 0);
    expect(stats.coins, 100);
    expect(find.byKey(const Key('freeHints')), findsNothing);
    await tester.tap(find.byKey(const Key('hint')));
    await tester.pumpAndSettle();
    expect(stats.coins, 100 - Economy.hintCost);
  });

  testWidgets('solving a daily earns event tokens', (tester) async {
    await app.pump(tester);
    await open(tester, const Key('daily-nests'));
    await solveNests(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eventTokensRow')), findsOneWidget);
    expect(find.text('Trophy unlocked!'), findsOneWidget);
  });

  testWidgets('completing a set from a capsule celebrates the hat and equips it', (tester) async {
    for (final c in album.where((c) => c.set == 'farm' && c.id != 'cow')) {
      await stats.addCritter(c.id);
    }
    await stats.addCapsule(golden: true);
    // Every other golden critter is owned, so the golden capsule holds the cow.
    for (final c in album.where((c) => c.rarity == Rarity.golden && c.id != 'cow')) {
      await stats.addCritter(c.id);
    }
    await app.pump(tester);
    await open(tester, const Key('capsules'));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('capsule')));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setUnlock')), findsOneWidget);
    expect(find.text('Set complete!'), findsOneWidget);
    expect(find.text('Flower crown unlocked'), findsOneWidget);
    await tester.tap(find.byKey(const Key('equipUnlock')));
    await tester.pumpAndSettle();
    expect(Shop(stats, progress).equippedHat, 'hat.flowers');
  });

  testWidgets('a set that pays bonus coins celebrates them', (tester) async {
    await app.pump(tester);
    final context = tester.element(find.byKey(const Key('settings')));
    const update = RetentionUpdate(setUnlocks: [SetUnlock(set: 'polar', cosmetics: [], coins: 300)]);
    showRetentionUpdate(context, update);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('setUnlock')), findsOneWidget);
    expect(find.text('+300 coins'), findsOneWidget);
    expect(find.byKey(const Key('equipUnlock')), findsNothing);
  });

  testWidgets('French strings', (tester) async {
    await progress.increment(Counter.shares);
    await app.pump(tester, locale: const Locale('fr'), calendar: true);
    expect(find.text('Cadeaux du jour'), findsOneWidget);
    expect(find.text('Jour 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendarClaim')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendarClose')));
    await tester.pumpAndSettle();
    expect(find.text('Semaine des pandas'), findsOneWidget);
    await open(tester, const Key('trophies'));
    expect(find.text('Trophées'), findsOneWidget);
    expect(find.text('Fier de moi'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await open(tester, const Key('shopStall'));
    expect(find.text('Boutique'), findsOneWidget);
    await open(tester, const Key('tab-hats'));
    expect(find.text('Tuque'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await open(tester, const Key('luckyNest'));
    expect(find.text('Nid chanceux'), findsOneWidget);
    expect(find.text('Œuf gratuit'), findsOneWidget);
  });
}
