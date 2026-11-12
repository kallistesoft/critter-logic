import 'package:critter_logic/main.dart';
import 'package:critter_logic/puzzles/nests/nests.dart';
import 'package:critter_logic/puzzles/pairs/pairs.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/puzzles/source.dart';
import 'package:critter_logic/puzzles/trail/trail.dart';
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

/// 4×4 Trail with a unique solution: a snake row by row, stones 1–5 at cells 0, 3, 4, 11 and 12.
final fakeTrail = TrailPuzzle(
  size: 4,
  stones: const [0, 3, 4, 11, 12],
  solution: const [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11, 15, 14, 13, 12],
);

/// The same tiny puzzles for every daily and level.
class FakePuzzleSource implements PuzzleSource {
  @override
  Future<NestsPuzzle> dailyNests(int number) async => fakeNests;
  @override
  Future<PairsPuzzle> dailyPairs(int number) async => fakePairs;
  @override
  Future<TrailPuzzle> dailyTrail(int number) async => fakeTrail;
  @override
  Future<TrailPuzzle> levelTrail(int level) async => fakeTrail;
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

  Future<void> pump(WidgetTester tester, {Locale? locale, Size size = const Size(412, 915), bool motion = false}) async {
    if (!motion) calmMotion(tester);
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
    if (motion) {
      // Clouds drift and critters idle forever: pump frames instead of settling.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    } else {
      await tester.pumpAndSettle();
    }
  }
}

const today = 12;

/// Turns on the system "reduce motion" setting: the meadow's looping animations (clouds, idle critters) stay still,
/// so `pumpAndSettle` can settle.
void calmMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Opens a game's level path and plays the current level.
Future<void> playLevel(WidgetTester tester, GameKind kind) async {
  await tester.tap(find.byKey(Key('level-${kind.name}')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('playLevel')));
  await tester.pumpAndSettle();
}

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

/// Drags one finger along [cells] on the board, center to center, in one gesture.
Future<void> dragPath(WidgetTester tester, List<int> cells) async {
  final gesture = await tester.startGesture(tester.getCenter(find.byKey(Key('cell-${cells.first}'))));
  for (final c in cells.skip(1)) {
    await gesture.moveTo(tester.getCenter(find.byKey(Key('cell-$c'))));
    await tester.pump();
  }
  await gesture.up();
  await tester.pump();
}

/// Solves the fake Trail board with one drag from stone 1.
Future<void> solveTrail(WidgetTester tester) => dragPath(tester, fakeTrail.solution);

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 120, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
