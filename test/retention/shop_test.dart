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

  test('the catalog sells Worlds, not the old board themes', () {
    expect(shopCatalog.where((i) => i.id.startsWith('theme.')), isEmpty);
    expect(
      {for (final i in shopCatalog.where((i) => i.category == ShopCategory.world)) i.id: i.price},
      {'world.meadow': 0, 'world.lodge': 0, 'world.neon': 1500, 'world.winter': 2000, 'world.pro': 1500},
    );
  });

  test('Worlds: Meadow and Lodge are free and owned, paid ones are bought once and equipped', () async {
    expect(shop.equippedWorld, defaultWorld);
    expect(shop.owns(shopItemById['world.lodge']!), isTrue);
    expect(shop.owns(shopItemById['world.neon']!), isFalse);
    expect(await shop.buy('world.lodge', 10), PurchaseResult.alreadyOwned);
    expect(await shop.equip('world.lodge'), isTrue);
    expect(shop.equippedWorld, 'world.lodge');
    expect(progress.equipped('world'), 'world.lodge');
    expect(analytics.events.last.$1, 'world_equip');
    expect(analytics.events.last.$2, {'world': 'world.lodge'});
    expect(await shop.equip('world.neon'), isFalse, reason: 'not owned');
    expect(await shop.buy('world.neon', 10), PurchaseResult.notEnoughCoins);
    await stats.addCoins(2000);
    final deal = shop.dailyDeal(10)?.id == 'world.neon';
    expect(await shop.buy('world.neon', 10), PurchaseResult.bought);
    expect(shop.equippedWorld, 'world.neon');
    expect(stats.coins, 2090 - (deal ? 1050 : 1500));
    expect(await shop.buy('world.neon', 10), PurchaseResult.alreadyOwned);
    expect(await shop.equip(defaultWorld), isTrue, reason: 'the Meadow is always owned');
    expect(shop.equippedWorld, defaultWorld);
    expect(shop.offers(10).firstWhere((o) => o.item.id == 'world.meadow').equipped, isTrue);
  });

  test('an unknown or old equipped world falls back to the Meadow', () async {
    await progress.setEquipped('world', 'theme.snowy');
    expect(shop.equippedWorld, defaultWorld);
  });

  test('the daily deal can be a World at -30%', () {
    final worldDays = [
      for (var d = 1; d < 200; d++)
        if (shop.dailyDeal(d)!.category == ShopCategory.world) d,
    ];
    expect(worldDays, isNotEmpty);
    final d = worldDays.first;
    final item = shop.dailyDeal(d)!;
    expect(freeWorlds, isNot(contains(item.id)), reason: 'free Worlds are owned, never on sale');
    expect(shop.priceToday(item, d), (item.price * 0.7).round());
  });

  test('cosmetics are bought once, equipped, and the hat can be taken off', () async {
    await stats.addCoins(2000);

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
    final p = ShopSettings.parsePrices(
      'capsule=200, hat.crown=9000, nope=50, world.neon=x, hat.party = 120, world.pro=1200',
    );
    expect(p, {'capsule': 200, 'hat.party': 120, 'world.pro': 1200});
    expect(ShopSettings(prices: p).priceOf(shopItemById['capsule']!), 200);
  });
}
