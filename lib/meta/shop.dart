import '../services/analytics_service.dart';
import '../services/stats_store.dart';
import 'progress_store.dart';

/// What a shop item gives.
enum ShopCategory {
  /// One capsule (a collectible critter): the main coin sink.
  capsule,

  /// Repairs yesterday's missed day so the streak survives (same rule as the ad repair: once a week).
  streakRepair,

  /// A board look (Nests garden beds, Pairs stones). Owned forever, one equipped.
  theme,

  /// A hat the critters wear on the board and the home meadow. Owned forever, one equipped.
  hat,
}

class ShopItem {
  const ShopItem(this.id, this.category, this.price);

  /// Stable id, also the cosmetic id in [ProgressStore.cosmetics] for themes and hats.
  final String id;
  final ShopCategory category;

  /// Default price in coins (Remote Config can override it, see [ShopSettings]).
  final int price;

  bool get cosmetic => category == ShopCategory.theme || category == ShopCategory.hat;
}

/// The free look every player starts with.
const defaultTheme = 'theme.meadow';

/// Prices are set against the income: a regular player earns ~45 coins a day from dailies and ~170 a week from
/// the calendar, so a capsule is ~3 days of play and the dearest cosmetic a few weeks.
const shopCatalog = <ShopItem>[
  ShopItem('capsule', ShopCategory.capsule, 150),
  ShopItem('streak_repair', ShopCategory.streakRepair, 100),
  ShopItem('theme.snowy', ShopCategory.theme, 300),
  ShopItem('theme.sunset', ShopCategory.theme, 300),
  ShopItem('theme.autumn', ShopCategory.theme, 400),
  ShopItem('theme.starry', ShopCategory.theme, 600),
  ShopItem('hat.flowers', ShopCategory.hat, 200),
  ShopItem('hat.party', ShopCategory.hat, 200),
  ShopItem('hat.beanie', ShopCategory.hat, 250),
  ShopItem('hat.crown', ShopCategory.hat, 500),
];

final shopItemById = {for (final i in shopCatalog) i.id: i};

/// Shop tuning from Remote Config: per-item prices and the daily deal discount.
class ShopSettings {
  const ShopSettings({this.prices = const {}, this.dealPercent = 30});

  /// Price overrides by item id; items not listed keep their catalog price.
  final Map<String, int> prices;

  /// Discount of the daily deal, in percent (0 = no deal).
  final int dealPercent;

  int priceOf(ShopItem item) => prices[item.id] ?? item.price;

  /// Parses `shop_prices`: comma-separated `id=price` pairs (prices 10–5000); unknown ids and bad pairs are ignored.
  static Map<String, int> parsePrices(String raw) {
    final prices = <String, int>{};
    for (final pair in raw.split(',')) {
      final parts = pair.split('=');
      if (parts.length != 2) continue;
      final id = parts[0].trim();
      final price = int.tryParse(parts[1].trim());
      if (shopItemById.containsKey(id) && price != null && price >= 10 && price <= 5000) prices[id] = price;
    }
    return prices;
  }
}

/// One line of the shop as the player sees it today.
class ShopOffer {
  const ShopOffer({
    required this.item,
    required this.price,
    required this.deal,
    required this.owned,
    required this.equipped,
    required this.available,
  });

  final ShopItem item;

  /// Price today, the deal discount included.
  final int price;

  /// Today's daily deal.
  final bool deal;

  /// A cosmetic the player already has (it can then be equipped for free).
  final bool owned;
  final bool equipped;

  /// Buyable now (the streak repair only when yesterday can be repaired; owned cosmetics can't be bought again).
  final bool available;
}

enum PurchaseResult { bought, notEnoughCoins, alreadyOwned, unavailable }

/// The coin shop: capsules, streak repairs, board themes and critter hats, with one discounted item per day.
class Shop {
  Shop(this.stats, this.progress, {this.settings = const ShopSettings(), AnalyticsService? analytics})
      : analytics = analytics ?? NoAnalytics();

  final StatsStore stats;
  final ProgressStore progress;
  final ShopSettings settings;
  final AnalyticsService analytics;

  bool owns(ShopItem item) => item.id == defaultTheme || progress.cosmetics.contains(item.id);

  String get equippedTheme => progress.equipped('theme') ?? defaultTheme;
  String? get equippedHat => progress.equipped('hat');

  /// Today's deal: a cosmetic the player doesn't own yet, else the capsule; the same all day, changing at local
  /// midnight. Null when deals are off.
  ShopItem? dailyDeal(int today) {
    if (settings.dealPercent <= 0) return null;
    // Board themes aren't on sale (Worlds will replace them), so deals pick from the hats.
    final pool = [
      for (final i in shopCatalog)
        if (i.category == ShopCategory.hat && !owns(i)) i,
    ];
    if (pool.isEmpty) return shopItemById['capsule'];
    // A small integer hash, so the pick looks random but every device agrees on the day's deal.
    final h = ((today * 2654435761) & 0x7fffffff) % pool.length;
    return pool[h];
  }

  int priceToday(ShopItem item, int today) {
    final base = settings.priceOf(item);
    return dailyDeal(today)?.id == item.id ? (base * (100 - settings.dealPercent) / 100).round() : base;
  }

  List<ShopOffer> offers(int today) {
    final deal = dailyDeal(today);
    return [
      for (final item in shopCatalog)
        ShopOffer(
          item: item,
          price: priceToday(item, today),
          deal: deal?.id == item.id,
          owned: item.cosmetic && owns(item),
          equipped: item.id == equippedTheme || item.id == equippedHat,
          available: switch (item.category) {
            ShopCategory.capsule => true,
            ShopCategory.streakRepair => stats.canRepair(today),
            ShopCategory.theme || ShopCategory.hat => !owns(item),
          },
        ),
    ];
  }

  /// Buys [id] today: spends the coins and grants the item. Cosmetics are equipped right away.
  Future<PurchaseResult> buy(String id, int today) async {
    final item = shopItemById[id];
    if (item == null) return PurchaseResult.unavailable;
    if (item.cosmetic && owns(item)) return PurchaseResult.alreadyOwned;
    if (item.category == ShopCategory.streakRepair && !stats.canRepair(today)) return PurchaseResult.unavailable;
    final price = priceToday(item, today);
    if (!await stats.spendCoins(price)) return PurchaseResult.notEnoughCoins;
    switch (item.category) {
      case ShopCategory.capsule:
        await stats.addCapsule();
      case ShopCategory.streakRepair:
        await stats.repairYesterday(today);
      case ShopCategory.theme || ShopCategory.hat:
        await progress.addCosmetic(item.id);
        await equip(item.id);
    }
    await analytics.log('shop_purchase', {
      'item': item.id,
      'price': price,
      'deal': dailyDeal(today)?.id == item.id ? 1 : 0,
    });
    return PurchaseResult.bought;
  }

  /// Equips an owned theme or hat; equipping the equipped hat takes it off.
  Future<bool> equip(String id) async {
    if (id == defaultTheme) {
      await progress.setEquipped('theme', null);
      return true;
    }
    final item = shopItemById[id];
    if (item == null || !item.cosmetic || !owns(item)) return false;
    final slot = item.category == ShopCategory.theme ? 'theme' : 'hat';
    final off = slot == 'hat' && equippedHat == id;
    await progress.setEquipped(slot, off ? null : id);
    return true;
  }
}
