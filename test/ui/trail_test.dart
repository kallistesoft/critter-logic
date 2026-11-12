import 'package:critter_logic/meta/economy.dart';
import 'package:critter_logic/meta/game_flow.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/puzzles/trail/solver.dart';
import 'package:critter_logic/services/sound_service.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:critter_logic/ui/game/session.dart';
import 'package:critter_logic/ui/game/trail_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  late StatsStore stats;
  late TestApp app;

  Future<void> setUpApp({bool tutorialDone = true}) async {
    SharedPreferences.setMockInitialValues({
      'flutter.tutorial.nests': true,
      'flutter.tutorial.pairs': true,
      'flutter.tutorial.trail': tutorialDone,
    });
    stats = await StatsStore.open();
    app = TestApp(stats);
  }

  TrailSession session(WidgetTester tester) => tester.widget<TrailBoard>(find.byType(TrailBoard)).session;

  Future<void> openTrailDaily(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('daily-trail')));
    await tester.pumpAndSettle();
  }

  test('the fake Trail has a unique solution', () {
    expect(TrailSolver.of(fakeTrail).solve().unique, isTrue);
  });

  testWidgets('drag-solving the Trail daily records it once and shows the result', (tester) async {
    await setUpApp();
    await app.pump(tester);
    await openTrailDaily(tester);
    expect(find.text('Trail'), findsOneWidget);
    await solveTrail(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resultTime')), findsOneWidget);
    final result = stats.daily(GameKind.trail, today)!;
    expect(result.millis, 0);
    expect(result.mistakes, 0);
    expect(stats.dailiesSolved, 1);
    expect(app.leaderboard.submits, [(GameKind.trail, today, 0)]);
    expect(stats.coins, Economy.starting + Economy.dailyWin);
    expect(stats.savedGame('trail.daily'), isNull);
    final complete = app.analytics.events.where((e) => e.$1 == 'level_complete').single;
    expect(complete.$2['game'], 'trail');
    final drawing = app.sound.played.takeWhile((s) => s != Sfx.solve);
    expect(drawing.where((s) => s == Sfx.place), hasLength(16), reason: 'a tick per cell of the trail');

    await tester.tap(find.byKey(const Key('resultHome')));
    await tester.pumpAndSettle();
    await openTrailDaily(tester);
    expect(find.text('Already solved'), findsOneWidget);
    expect(app.leaderboard.submits, hasLength(1));
    expect(stats.dailiesSolved, 1);
  });

  testWidgets('a refused move is a mistake; dragging back retracts; tapping the trail cuts it', (tester) async {
    await setUpApp();
    await app.pump(tester);
    await openTrailDaily(tester);
    await dragPath(tester, [0, 1, 2, 3, 7]);
    expect(session(tester).path, [0, 1, 2, 3, 7]);

    // Stone 4 (cell 11) before stone 3: refused, a mistake (+10 s), the trail stays.
    await dragPath(tester, [7, 11]);
    expect(session(tester).path, [0, 1, 2, 3, 7]);
    expect(session(tester).mistakes, 1);
    expect(find.text('+10s'), findsOneWidget);
    expect(app.sound.played.last, Sfx.conflict);
    // The drag pauses after a refusal: moving on from the refused cell draws nothing.
    await dragPath(tester, [7, 11, 10]);
    expect(session(tester).path, [0, 1, 2, 3, 7]);
    expect(session(tester).mistakes, 2);

    // Back over the trail: two steps back.
    await dragPath(tester, [7, 3, 2]);
    expect(session(tester).path, [0, 1, 2]);
    expect(app.sound.played.last, Sfx.erase);

    // Revisit: going back onto the trail other than the step before is refused.
    await dragPath(tester, [2, 6, 5, 1]);
    expect(session(tester).path, [0, 1, 2, 6, 5]);
    expect(session(tester).mistakes, 3);

    // A tap on the trail cuts it there; undo brings the cut part back.
    await tapCell(tester, 1);
    expect(session(tester).path, [0, 1]);
    await tester.tap(find.byKey(const Key('undo')));
    await tester.pump();
    expect(session(tester).path, [0, 1, 2, 6, 5]);

    // A tap far from the trail's end is a jump: refused.
    await tapCell(tester, 15);
    expect(session(tester).mistakes, 4);
    expect(find.text('+40s'), findsOneWidget);

    // Restart clears the trail, and the game is saved and restored.
    await tester.tap(find.byKey(const Key('restart')));
    await tester.pump();
    expect(session(tester).path, isEmpty);
    await dragPath(tester, [0, 1, 2]);
    await tester.tap(find.byKey(const Key('back')));
    await tester.pumpAndSettle();
    expect(stats.savedGame('trail.daily')!['mi'], 4);
    await openTrailDaily(tester);
    expect(session(tester).path, [0, 1, 2]);
    expect(session(tester).mistakes, 4);
  });

  testWidgets('a hint draws the next cell, or takes the trail back to where it left the solution', (tester) async {
    await setUpApp();
    await app.pump(tester);
    await openTrailDaily(tester);
    await dragPath(tester, [0, 1, 2]);
    await tester.tap(find.byKey(const Key('hint')));
    await tester.pumpAndSettle();
    expect(session(tester).path, [0, 1, 2, 3]);
    expect(stats.coins, Economy.starting - Economy.hintCost);
    expect(find.text('+30s'), findsOneWidget);
    expect(find.byKey(const Key('trailHint')), findsOneWidget);

    // Off the solution: 1 → 5 → 6 → 2 → 3 is legal but can't be finished.
    await tapCell(tester, 1);
    await dragPath(tester, [1, 5, 6, 2, 3]);
    expect(session(tester).path, [0, 1, 5, 6, 2, 3]);
    await tester.tap(find.byKey(const Key('hint')));
    await tester.pumpAndSettle();
    expect(session(tester).path, [0, 1]);
    expect(session(tester).hintCell, 1);
    expect(session(tester).hints, 2);
    expect(app.analytics.events.where((e) => e.$1 == 'hint_used').map((e) => e.$2['game']), ['trail', 'trail']);

    // Finish from there: 2 hints, no mistake.
    await dragPath(tester, fakeTrail.solution.sublist(1));
    await tester.pumpAndSettle();
    final result = stats.daily(GameKind.trail, today)!;
    expect(result.hints, 2);
    expect(result.millis, 2 * hintPenaltyMillis);
  });

  testWidgets('the Trail tutorial shows once and teaches by dragging', (tester) async {
    await setUpApp(tutorialDone: false);
    await app.pump(tester);
    await openTrailDaily(tester);
    expect(find.text('How to play Trail'), findsOneWidget);
    expect(find.text('Put your finger on stone 1 and drag to stone 2. The trail goes up, down, left or right.'),
        findsOneWidget);

    Future<void> next() async {
      await tester.tap(find.byKey(const Key('tutorialNext')));
      await tester.pumpAndSettle();
    }

    await dragPath(tester, [0, 1, 2, 3]);
    await tester.pumpAndSettle();
    await next();
    expect(find.text('Visit the stones in order: 1, 2, 3… Drag back over the trail to undo a step.'), findsOneWidget);
    await dragPath(tester, [3, 7, 6, 5, 4]);
    await tester.pumpAndSettle();
    await next();
    expect(find.text('Hedges block the way. Go around them!'), findsOneWidget);
    // Straight through the hedge between 8 and 9: refused.
    await dragPath(tester, [4, 8, 9]);
    await tester.pumpAndSettle();
    expect(find.text('Oops, that way breaks a rule. Try another cell.'), findsOneWidget);
    expect(find.byKey(const Key('tutorialNext')), findsNothing);
    await dragPath(tester, [8, 12, 13]);
    await tester.pumpAndSettle();
    await next();
    expect(find.text('Cover every square, then end on the last stone 🚩.'), findsOneWidget);
    await dragPath(tester, [13, 9, 10, 14, 15, 11]);
    await tester.pumpAndSettle();
    expect(find.text("Let's play!"), findsOneWidget);
    await next();

    expect(stats.tutorialDone(GameKind.trail), isTrue);
    expect(find.byType(TrailBoard), findsOneWidget, reason: 'the daily opens after the tutorial');
    expect(app.analytics.events.where((e) => e.$1 == 'tutorial_done').single.$2['game'], 'trail');
    await tester.tap(find.byKey(const Key('back')));
    await tester.pumpAndSettle();
    await openTrailDaily(tester);
    expect(find.text('How to play Trail'), findsNothing);
    expect(find.byType(TrailBoard), findsOneWidget);
  });

  testWidgets('Trail levels: a win pays coins and moves on', (tester) async {
    await setUpApp();
    await app.pump(tester);
    await playLevel(tester, GameKind.trail);
    expect(find.text('Level 1'), findsOneWidget);
    await solveTrail(tester);
    await tester.pumpAndSettle();
    expect(find.text('Level 1 solved!'), findsOneWidget);
    expect(stats.level(GameKind.trail), 2);
    expect(stats.levelStars(GameKind.trail, 1), 3);
  });
}
