import 'package:critter_logic/meta/game_flow.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:critter_logic/ui/meadow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  test('stars: 3 without hint and mistake, 2 with one of them, 1 with both', () {
    expect(starsFor(hints: 0, mistakes: 0), 3);
    expect(starsFor(hints: 1, mistakes: 0), 2);
    expect(starsFor(hints: 0, mistakes: 4), 2);
    expect(starsFor(hints: 2, mistakes: 1), 1);
  });

  test('tablets scale the layout up, phones keep it as is', () {
    expect(UiScale.factorFor(const Size(360, 640)), 1);
    expect(UiScale.factorFor(const Size(412, 915)), 1);
    final tab = UiScale.factorFor(const Size(800, 1280));
    expect(tab, greaterThan(1.5));
    expect(800 / tab, lessThanOrEqualTo(520), reason: 'laid out at about phone width');
  });

  group('screens', () {
    late StatsStore stats;
    late TestApp app;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'flutter.tutorial.nests': true, 'flutter.tutorial.pairs': true});
      stats = await StatsStore.open();
      app = TestApp(stats);
    });

    testWidgets('the level path shows stars, the current level and locked ones', (tester) async {
      await stats.setLevel(GameKind.pairs, 4);
      await stats.recordLevelStars(GameKind.pairs, 1, 3);
      await stats.recordLevelStars(GameKind.pairs, 2, 1);
      await app.pump(tester);
      await tester.tap(find.byKey(const Key('level-pairs')));
      await tester.pumpAndSettle();
      expect(find.text('Pairs levels'), findsOneWidget);
      expect(find.byKey(const Key('playLevel')), findsOneWidget);
      // Tapping a locked level says what to do.
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();
      expect(find.text('Finish level 4 first'), findsOneWidget);
      await tester.tap(find.byKey(const Key('playLevel')));
      await tester.pumpAndSettle();
      expect(find.text('Level 4'), findsOneWidget);
    });

    testWidgets('home and game run with the ambient animations on', (tester) async {
      await app.pump(tester, motion: true);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.tap(find.byKey(const Key('mascot-1')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(app.sound.played, isNotEmpty);
      await tester.tap(find.byKey(const Key('daily-nests')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byKey(const Key('cell-0')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    });
  });
}
