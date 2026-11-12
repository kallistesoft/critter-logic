import 'package:critter_logic/main.dart';
import 'package:critter_logic/puzzles/nests/nests.dart';
import 'package:critter_logic/puzzles/pairs/pairs.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/puzzles/source.dart';
import 'package:critter_logic/services/ad_service.dart';
import 'package:critter_logic/services/analytics_service.dart';
import 'package:critter_logic/services/leaderboard_service.dart';
import 'package:critter_logic/services/sound_service.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 4×4 Nests with a unique solution: columns 1, 3, 0, 2 → cells 1, 7, 8, 14.
final fakeNests = NestsPuzzle.fromJson(const {'s': 4, 'r': '0122022202330333', 'x': '1302'});
const fakeNestsCells = [1, 7, 8, 14];

/// 4×4 Pairs with a unique solution; givens at 0, 2 and 6.
final fakePairs = PairsPuzzle.fromJson(const {
  's': 4,
  'g': '0.0...0.........',
  'l': [
    [0, 4, 1]
  ],
  'x': '0101010110101010',
});

/// The same tiny puzzles for every daily and level.
class FakePuzzleSource implements PuzzleSource {
  @override
  Future<NestsPuzzle> dailyNests(int number) async => fakeNests;
  @override
  Future<PairsPuzzle> dailyPairs(int number) async => fakePairs;
  @override
  Future<NestsPuzzle> levelNests(int level) async => fakeNests;
  @override
  Future<PairsPuzzle> levelPairs(int level) async => fakePairs;
}

class CountingAds implements AdService {
  CountingAds({this.rewardGranted = true});

  bool rewardGranted;
  int interstitials = 0;
  int rewarded = 0;

  @override
  Future<void> showInterstitial() async => interstitials++;

  @override
  Future<bool> showRewarded() async {
    rewarded++;
    return rewardGranted;
  }
}

class FakeLeaderboard implements LeaderboardService {
  final submits = <(GameKind, int, int)>[];
  int standings = 0;
  int profiles = 0;

  @override
  Future<DailyStanding?> submitDaily(GameKind kind, int day, int millis) async {
    submits.add((kind, day, millis));
    return DailyStanding(top: [(4000, false), (millis, true)], total: 2, counts: const {}, myMillis: millis);
  }

  @override
  Future<DailyStanding?> standing(GameKind kind, int day, {int? myMillis}) async {
    standings++;
    return null;
  }

  @override
  Future<void> submitProfile({required int bestStreak, required int solved}) async => profiles++;

  @override
  Future<AllTimeBoards?> allTime() async => null;
}

/// A phone-sized app on a fixed day (daily #12) with fakes everywhere.
class TestApp {
  TestApp(this.stats);

  final StatsStore stats;
  final ads = CountingAds();
  final leaderboard = FakeLeaderboard();
  final analytics = NoAnalytics();
  final sound = NoSound();
  DateTime now = DateTime(2026, 12, 12, 10);

  Future<void> pump(WidgetTester tester, {Locale? locale, Size size = const Size(412, 915)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CritterLogicApp(
      stats: stats,
      ads: ads,
      sound: sound,
      analytics: analytics,
      leaderboard: leaderboard,
      puzzles: FakePuzzleSource(),
      today: () => now,
      locale: locale,
    ));
    await tester.pumpAndSettle();
  }
}

const today = 12;

/// Taps a board cell [times] times.
Future<void> tapCell(WidgetTester tester, int cell, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.byKey(Key('cell-$cell')));
    await tester.pump();
  }
}

/// Solves the fake Nests board by taps (cross, then critter).
Future<void> solveNests(WidgetTester tester) async {
  for (final c in fakeNestsCells) {
    await tapCell(tester, c, times: 2);
  }
}

/// Solves the fake Pairs board by taps: once for a sun, twice for a moon.
Future<void> solvePairs(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    if (fakePairs.givens[i] != null) continue;
    await tapCell(tester, i, times: fakePairs.solution[i] == sun ? 1 : 2);
  }
}

Future<void> scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 120, scrollable: find.byType(Scrollable).first);
