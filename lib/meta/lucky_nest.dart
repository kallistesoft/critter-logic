import 'dart:math';

import '../services/analytics_service.dart';
import '../services/stats_store.dart';
import 'progress_store.dart';

/// What an egg from the Lucky Nest holds.
enum LuckyPrize { goldenCapsule, capsule, coins, hint, feather }

/// Lucky Nest odds in per mille (the feather, "nothing", gets the rest) and limits. Tuned so a paid draw returns
/// a little less than it costs on average (about 49 coins of value for 50): a coin sink that still feels generous.
class LuckySettings {
  const LuckySettings({
    this.golden = 15,
    this.capsule = 120,
    this.coins = 200,
    this.hint = 300,
    this.price = 50,
    this.paidPerDay = 0,
    this.paidEnabled = true,
    this.minCoins = 40,
    this.maxCoins = 120,
  });

  final int golden, capsule, coins, hint;
  final int price;
  /// Paid eggs allowed per day; 0 = no limit (the default). Remote Config can set a cap.
  final int paidPerDay;

  /// Paid eggs offered at all. Coins can be bought, so a paid egg is a random reward bought with real money
  /// (a "loot box"); Remote Config turns them off where that's not allowed (a country condition for Belgium sets
  /// `paid=0`). The free daily egg stays.
  final bool paidEnabled;
  final int minCoins, maxCoins;

  int get feather => 1000 - golden - capsule - coins - hint;

  /// Odds as shown to the player, in percent.
  Map<LuckyPrize, double> get odds => {
        LuckyPrize.goldenCapsule: golden / 10,
        LuckyPrize.capsule: capsule / 10,
        LuckyPrize.coins: coins / 10,
        LuckyPrize.hint: hint / 10,
        LuckyPrize.feather: feather / 10,
      };

  /// Parses `lucky_nest`: comma-separated `key=value` (golden, capsule, coins, hint in per mille; price; paid_per_day;
  /// min_coins; max_coins). Bad values keep their defaults; odds that add up past 1000 are all rejected.
  static LuckySettings parse(String raw) {
    const d = LuckySettings();
    final v = <String, int>{};
    for (final pair in raw.split(',')) {
      final parts = pair.split('=');
      final n = parts.length == 2 ? int.tryParse(parts[1].trim()) : null;
      if (n != null && n >= 0) v[parts[0].trim()] = n;
    }
    int pick(String key, int fallback, int max) => (v[key] ?? fallback) > max ? fallback : (v[key] ?? fallback);
    var golden = pick('golden', d.golden, 1000),
        capsule = pick('capsule', d.capsule, 1000),
        coins = pick('coins', d.coins, 1000),
        hint = pick('hint', d.hint, 1000);
    if (golden + capsule + coins + hint > 1000) (golden, capsule, coins, hint) = (d.golden, d.capsule, d.coins, d.hint);
    final minCoins = pick('min_coins', d.minCoins, 1000);
    final maxCoins = pick('max_coins', d.maxCoins, 2000);
    return LuckySettings(
      golden: golden,
      capsule: capsule,
      coins: coins,
      hint: hint,
      price: pick('price', d.price, 1000) < 10 ? d.price : pick('price', d.price, 1000),
      paidPerDay: pick('paid_per_day', d.paidPerDay, 100),
      paidEnabled: (v['paid'] ?? 1) != 0,
      minCoins: minCoins <= maxCoins ? minCoins : d.minCoins,
      maxCoins: minCoins <= maxCoins ? maxCoins : d.maxCoins,
    );
  }
}

class LuckyDraw {
  const LuckyDraw(this.prize, {this.coins = 0, required this.free});

  final LuckyPrize prize;

  /// Coins won (only for [LuckyPrize.coins]).
  final int coins;
  final bool free;
}

/// Where the player stands at the nest today.
class LuckyState {
  const LuckyState({required this.freeAvailable, required this.paidLeft, required this.price});

  final bool freeAvailable;
  /// Paid eggs still allowed today; null = no limit.
  final int? paidLeft;
  final int price;
}

/// The Lucky Nest: one free egg a day, then paid eggs (no daily limit unless Remote Config sets one), odds shown. Prizes are paid into [StatsStore]
/// (capsules, coins) and [ProgressStore] (free hints).
class LuckyNest {
  LuckyNest(this.stats, this.progress, {this.settings = const LuckySettings(), AnalyticsService? analytics, Random? random})
      : analytics = analytics ?? NoAnalytics(),
        _random = random ?? Random();

  final StatsStore stats;
  final ProgressStore progress;
  final LuckySettings settings;
  final AnalyticsService analytics;
  final Random _random;

  LuckyState state(int today) => LuckyState(
        freeAvailable: progress.luckyFreeDay != today,
        paidLeft: !settings.paidEnabled
            ? 0
            : settings.paidPerDay == 0
            ? null
            : (settings.paidPerDay - progress.luckyPaid(today)).clamp(0, settings.paidPerDay),
        price: settings.price,
      );

  /// Draws an egg: the free one if still available today, else a paid one. Null when today's draws are used up or
  /// the player can't pay.
  Future<LuckyDraw?> draw(int today) async {
    final s = state(today);
    final free = s.freeAvailable;
    if (!free) {
      if ((s.paidLeft != null && s.paidLeft! <= 0) || !await stats.spendCoins(settings.price)) return null;
      await progress.addLuckyPaid(today);
    } else {
      await progress.setLuckyFreeDay(today);
    }
    final draw = _roll(free);
    switch (draw.prize) {
      case LuckyPrize.goldenCapsule:
        await stats.addCapsule(golden: true);
      case LuckyPrize.capsule:
        await stats.addCapsule();
      case LuckyPrize.coins:
        await stats.addCoins(draw.coins);
      case LuckyPrize.hint:
        await progress.addFreeHints(1);
      case LuckyPrize.feather:
        break;
    }
    await analytics.log('lucky_draw', {'prize': draw.prize.name, 'coins': draw.coins, 'free': free ? 1 : 0});
    return draw;
  }

  LuckyDraw _roll(bool free) {
    var r = _random.nextInt(1000);
    final s = settings;
    for (final (prize, chance) in [
      (LuckyPrize.goldenCapsule, s.golden),
      (LuckyPrize.capsule, s.capsule),
      (LuckyPrize.coins, s.coins),
      (LuckyPrize.hint, s.hint),
    ]) {
      if (r < chance) {
        final coins = prize == LuckyPrize.coins ? s.minCoins + _random.nextInt(s.maxCoins - s.minCoins + 1) : 0;
        return LuckyDraw(prize, coins: coins, free: free);
      }
      r -= chance;
    }
    return LuckyDraw(LuckyPrize.feather, free: free);
  }
}
