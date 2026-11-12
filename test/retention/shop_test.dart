import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/meta/shop.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/analytics_service.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StatsStore stats;
  late ProgressStore progress;
  late NoAnalytics analytics;
  late Shop shop;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
    progress = await ProgressStore.open();
    analytics = NoAnalytics();
    shop = Shop(stats, progress, analytics: analytics);
  });

  test('buying a capsule spends coins and adds a capsule', () async {
    await stats.addCoins(500);
    final before = stats.coins;
    final deal = shop.dailyDeal(10);
    expect(deal?.id, isNot('capsule'), reason: 'cosmetics are the deal while some are unowned');
    expect(await shop.buy('capsule', 10), PurchaseResult.bought);
    expect(stats.capsules, 1);
    expect(stats.coins, before - 150);
    expect(analytics.events.last.$1, 'shop_purchase');
  });

  test('not enough coins changes nothing', () async {
    final before = stats.coins; // 90 to start
    expect(await shop.buy('capsule', 10), PurchaseResult.notEnoughCoins);
    expect(stats.coins, before);
    expect(stats.capsules, 0);
  });

  test('cosmetics are bought once, equipped, and the hat can be taken off', () async {
    await stats.addCoins(2000);
    expect(shop.equippedTheme, defaultTheme);
    expect(await shop.buy('theme.snowy', 10), PurchaseResult.bought);
    expect(shop.equippedTheme, 'theme.snowy');
    expect(await shop.buy('theme.snowy', 10), PurchaseResult.alreadyOwned);
    expect(await shop.equip(defaultTheme), isTrue, reason: 'the default theme is always owned');
    expect(shop.equippedTheme, defaultTheme);

    expect(await shop.buy('hat.party', 10), PurchaseResult.bought);
    expect(shop.equippedHat, 'hat.party');
    await shop.equip('hat.party');
    expect(shop.equippedHat, isNull);
    expect(await shop.equip('hat.crown'), isFalse, reason: 'not owned');
  });

  test('streak repair only when yesterday can be repaired', () async {
    await stats.addCoins(500);
    expect(await shop.buy('streak_repair', 12), PurchaseResult.unavailable);
    await stats.recordDaily(const DailyResult(kind: GameKind.nests, number: 10, millis: 60000));
    // Day 11 missed, today is 12.
    expect(shop.offers(12).firstWhere((o) => o.item.id == 'streak_repair').available, isTrue);
    expect(await shop.buy('streak_repair', 12), PurchaseResult.bought);
    expect(stats.streak(12), 2);
  });

  test('daily deal: same all day, discounted, falls back to the capsule when every cosmetic is owned', () async {
    final a = shop.dailyDeal(20)!;
    expect(shop.dailyDeal(20)!.id, a.id);
    expect(shop.priceToday(a, 20), (shop.settings.priceOf(a) * 0.7).round());
    final days = {for (var d = 1; d < 60; d++) shop.dailyDeal(d)!.id};
    expect(days.length, greaterThan(3), reason: 'the deal rotates');
    for (final i in shopCatalog.where((i) => i.cosmetic)) {
      await progress.addCosmetic(i.id);
    }
    expect(shop.dailyDeal(20)!.id, 'capsule');
    expect(Shop(stats, progress, settings: const ShopSettings(dealPercent: 0)).dailyDeal(20), isNull);
  });

  test('Remote Config prices: valid overrides only', () {
    final p = ShopSettings.parsePrices('capsule=200, hat.crown=9000, nope=50, theme.snowy=x, hat.party = 120');
    expect(p, {'capsule': 200, 'hat.party': 120});
    expect(ShopSettings(prices: p).priceOf(shopItemById['capsule']!), 200);
  });
}
