import '../meta/achievements.dart';
import '../meta/login_calendar.dart';
import '../meta/lucky_nest.dart';
import '../meta/rewards.dart';
import '../meta/shop.dart';
import '../meta/weekly_event.dart';

/// Retention tuning from Firebase Remote Config (login calendar, achievements, weekly events), with the shipped
/// defaults. Bad values fall back to the defaults, like [GameSettings].
class RetentionSettings {
  const RetentionSettings({
    this.calendarRewards = defaultCalendarRewards,
    this.calendarAdDouble = true,
    this.achievementCoins = const AchievementCoins(),
    this.events = const EventSettings(),
    this.shop = const ShopSettings(),
    this.lucky = const LuckySettings(),
  });

  final List<Reward> calendarRewards;
  final bool calendarAdDouble;
  final AchievementCoins achievementCoins;
  final EventSettings events;
  final ShopSettings shop;
  final LuckySettings lucky;

  /// The default `calendar_rewards` string: 7 comma-separated days, each a coin amount, `capsule` or `golden`.
  static const defaultCalendarString = '20,60,capsule,30,capsule,60,capsule';

  /// Remote Config parameter names and default values.
  static Map<String, Object> get defaults => {
        'calendar_rewards': defaultCalendarString,
        'calendar_ad_double': true,
        'achievement_bronze_coins': 20,
        'achievement_silver_coins': 50,
        'achievement_gold_coins': 100,
        'weekly_event_json': '',
        'shop_prices': '',
        'shop_deal_percent': 30,
        'lucky_nest': '',
      };

  /// Parses `calendar_rewards`; null unless it has exactly 7 valid days (coins 1–500, `capsule`, `golden`).
  static List<Reward>? parseCalendar(String raw) {
    final parts = raw.split(',').map((p) => p.trim().toLowerCase()).toList();
    if (parts.length != LoginCalendar.length) return null;
    final rewards = <Reward>[];
    for (final p in parts) {
      if (p == 'capsule') {
        rewards.add(const Reward.capsule());
      } else if (p == 'golden') {
        rewards.add(const Reward.goldenCapsule());
      } else {
        final coins = int.tryParse(p);
        if (coins == null || coins < 1 || coins > 500) return null;
        rewards.add(Reward.coins(coins));
      }
    }
    return rewards;
  }

  /// Reads the values through the Remote Config getters.
  static RetentionSettings read(
      bool Function(String) getBool, int Function(String) getInt, String Function(String) getString) {
    const d = AchievementCoins();
    int clamp(String key, int fallback, int min, int max) {
      final v = getInt(key);
      return v < min || v > max ? fallback : v;
    }

    return RetentionSettings(
      calendarRewards: parseCalendar(getString('calendar_rewards')) ?? defaultCalendarRewards,
      calendarAdDouble: getBool('calendar_ad_double'),
      achievementCoins: AchievementCoins(
        bronze: clamp('achievement_bronze_coins', d.bronze, 0, 500),
        silver: clamp('achievement_silver_coins', d.silver, 0, 1000),
        gold: clamp('achievement_gold_coins', d.gold, 0, 2000),
      ),
      events: EventSettings.parse(getString('weekly_event_json')),
      shop: ShopSettings(
        prices: ShopSettings.parsePrices(getString('shop_prices')),
        dealPercent: clamp('shop_deal_percent', 30, 0, 90),
      ),
      lucky: LuckySettings.parse(getString('lucky_nest')),
    );
  }
}
