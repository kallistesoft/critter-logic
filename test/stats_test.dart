import 'package:critter_logic/daily.dart';
import 'package:critter_logic/l10n/app_localizations.dart';
import 'package:critter_logic/meta/economy.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/share_text.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StatsStore stats;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
  });

  DailyResult r(GameKind kind, int day, [int millis = 60000]) => DailyResult(kind: kind, number: day, millis: millis);

  test('daily numbers follow the local calendar date', () {
    expect(dailyNumberFor(DateTime(2026, 12, 1, 0, 5)), 1);
    expect(dailyNumberFor(DateTime(2026, 12, 1, 23, 59)), 1);
    expect(dailyNumberFor(DateTime(2026, 12, 2)), 2);
    // Across a daylight saving change (Montréal, 2027-03-14).
    expect(dailyNumberFor(DateTime(2027, 3, 15, 0, 30)) - dailyNumberFor(DateTime(2027, 3, 13, 23, 30)), 2);
    expect(dateOfDaily(32), DateTime.utc(2027, 1, 1));
  });

  test('a daily keeps the first attempt', () async {
    expect(await stats.recordDaily(r(GameKind.nests, 10, 50000)), isTrue);
    expect(await stats.recordDaily(r(GameKind.nests, 10, 10000)), isFalse);
    expect(stats.daily(GameKind.nests, 10)!.millis, 50000);
    expect(stats.dailiesSolved, 1);
    expect(stats.allDailiesDone(10), isFalse);
    await stats.recordDaily(r(GameKind.pairs, 10));
    expect(stats.allDailiesDone(10), isTrue);
  });

  test('streak counts days with any daily and can be repaired once a week', () async {
    await stats.recordDaily(r(GameKind.nests, 8));
    await stats.recordDaily(r(GameKind.pairs, 9));
    await stats.recordDaily(r(GameKind.nests, 10));
    expect(stats.streak(10), 3);
    expect(stats.streak(11), 3, reason: 'today not played yet');
    expect(stats.streak(12), 0);

    expect(stats.canRepair(12), isTrue, reason: 'only day 11 is missing');
    await stats.repairYesterday(12);
    expect(stats.streak(12), 4);
    await stats.recordDaily(r(GameKind.nests, 12));
    await stats.updateBestStreak(12);
    expect(stats.bestStreak, 5);
    expect(stats.canRepair(14), isFalse, reason: 'last repair was 2 days ago');
  });

  test('coins and album', () async {
    expect(stats.coins, Economy.starting);
    expect(await stats.spendCoins(Economy.starting + 1), isFalse);
    expect(await stats.spendCoins(30), isTrue);
    await stats.addCoins(5);
    expect(stats.coins, Economy.starting - 25);
    await stats.addCapsule();
    await stats.addCapsule(golden: true);
    expect((stats.capsules, stats.goldenCapsules), (1, 1));
    await stats.takeCapsule(golden: true);
    expect(stats.goldenCapsules, 0);
    await stats.addCritter('owl');
    await stats.addCritter('owl');
    expect(stats.owned, {'owl'});
  });

  test('share text', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(formatTime(72345), '1:12');
    expect(formatTime(5000), '0:05');
    final text = dailyShareText(
      12,
      [
        const DailyResult(kind: GameKind.nests, number: 12, millis: 72000),
        const DailyResult(kind: GameKind.pairs, number: 12, millis: 48000, hints: 1),
      ],
      streak: 7,
      l10n: en,
    );
    expect(text, startsWith('Critter Logic #12\n🐣 1:12 ✨\n☀️ 0:48\n'));
    expect(text, contains('7-day streak'));
    expect(text, endsWith(playStoreUrl));
  });
}
