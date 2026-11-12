import 'package:critter_logic/meta/album.dart';
import 'package:critter_logic/meta/login_calendar.dart';
import 'package:critter_logic/meta/rewards.dart';
import 'package:critter_logic/meta/seasonal.dart';
import 'package:critter_logic/services/retention_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RetentionSettings readFrom(Map<String, Object> values) {
    final d = {...RetentionSettings.defaults, ...values};
    return RetentionSettings.read((k) => d[k] as bool, (k) => d[k] as int, (k) => d[k] as String);
  }

  test('defaults round-trip', () {
    final s = readFrom({});
    expect(s.calendarRewards, defaultCalendarRewards);
    expect(RetentionSettings.parseCalendar(RetentionSettings.defaultCalendarString), defaultCalendarRewards);
    expect(s.calendarAdDouble, isTrue);
    expect((s.achievementCoins.bronze, s.achievementCoins.silver, s.achievementCoins.gold), (20, 50, 100));
    expect(s.events.thresholds, [5, 15, 30]);
  });

  test('custom calendar', () {
    final s = readFrom({'calendar_rewards': ' 10, 20 ,Capsule,30,40,50,golden', 'calendar_ad_double': false});
    expect(s.calendarRewards, const [
      Reward.coins(10),
      Reward.coins(20),
      Reward.capsule(),
      Reward.coins(30),
      Reward.coins(40),
      Reward.coins(50),
      Reward.goldenCapsule(),
    ]);
    expect(s.calendarAdDouble, isFalse);
  });

  test('bad values fall back to defaults', () {
    for (final raw in ['', '1,2,3', '1,2,3,4,5,6,7,8', '0,1,1,1,1,1,1', '1,1,1,1,1,1,999', '1,1,1,1,1,1,gem']) {
      expect(readFrom({'calendar_rewards': raw}).calendarRewards, defaultCalendarRewards, reason: raw);
    }
    final s = readFrom({
      'achievement_bronze_coins': -5,
      'achievement_silver_coins': 100000,
      'achievement_gold_coins': 250,
      'weekly_event_json': '{oops',
    });
    expect((s.achievementCoins.bronze, s.achievementCoins.silver, s.achievementCoins.gold), (20, 50, 250));
    expect(s.events.thresholds, [5, 15, 30]);
  });

  group('seasonal sets', () {
    test('winter runs Dec 1 to Feb 28 across New Year', () {
      expect(winterSet.isActive(DateTime(2026, 11, 30, 23, 59)), isFalse);
      expect(winterSet.isActive(DateTime(2026, 12, 1)), isTrue);
      expect(winterSet.isActive(DateTime(2026, 12, 31, 23, 59)), isTrue);
      expect(winterSet.isActive(DateTime(2027, 1, 15)), isTrue);
      expect(winterSet.isActive(DateTime(2027, 2, 28, 23, 59)), isTrue);
      expect(winterSet.isActive(DateTime(2027, 3, 1)), isFalse);
      expect(winterSet.isActive(DateTime(2027, 7, 1)), isFalse);
      expect(activeSeasonalSets(DateTime(2027, 1, 1)), [winterSet]);
      expect(activeSeasonalSets(DateTime(2027, 6, 1)), isEmpty);
    });

    test('a window inside one year', () {
      const spring = SeasonalSet(id: 'spring', start: MonthDay(3, 20), end: MonthDay(6, 20), critters: []);
      expect(spring.isActive(DateTime(2027, 3, 19)), isFalse);
      expect(spring.isActive(DateTime(2027, 3, 20)), isTrue);
      expect(spring.isActive(DateTime(2027, 6, 20)), isTrue);
      expect(spring.isActive(DateTime(2027, 6, 21)), isFalse);
    });

    test('winter reuses the polar critters in a snowy frame', () {
      final polar = album.where((c) => c.set == 'polar').toList();
      expect(winterSet.critters.map((c) => c.base), polar.map((c) => c.id));
      for (final c in winterSet.critters) {
        expect(c.frame, 'snowy');
        expect(c.critter.rarity, c.rarity);
        expect(critterById.containsKey(winterSet.idOf(c)), isFalse, reason: 'own collectible id');
      }
      expect(winterSet.idOf(winterSet.critters.first), 'moose@winter');
    });
  });
}
