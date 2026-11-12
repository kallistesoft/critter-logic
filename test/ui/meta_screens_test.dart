import 'dart:math';

import 'package:critter_logic/meta/album.dart';
import 'package:critter_logic/meta/economy.dart';
import 'package:critter_logic/meta/level_ad_pacer.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:critter_logic/ui/capsule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  test('level interstitials: none before 5 wins, then every 3rd', () {
    const pacer = LevelAdPacer();
    final shown = [for (var w = 1; w <= 15; w++) if (pacer.shouldShow(w)) w];
    expect(shown, [5, 8, 11, 14]);
    const custom = LevelAdPacer(firstAfter: 2, every: 1);
    expect([for (var w = 1; w <= 4; w++) custom.shouldShow(w)], [false, true, true, true]);
  });

  group('screens', () {
    late StatsStore stats;
    late TestApp app;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      stats = await StatsStore.open();
      app = TestApp(stats);
    });

    testWidgets('the tutorial shows the first time only, and can be played through', (tester) async {
      await app.pump(tester);
      await tester.tap(find.byKey(const Key('daily-nests')));
      await tester.pumpAndSettle();
      expect(find.text('How to play Nests'), findsOneWidget);
      // Step 1: tap the free cell of the first row twice.
      await tapCell(tester, 1, times: 2);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tutorialNext')));
      await tester.pumpAndSettle();
      // Step 2: the wrong column first (red), then the right cell.
      await tapCell(tester, 9, times: 2);
      expect(find.text('Oops, that breaks a rule. Tap again to change it.'), findsOneWidget);
      await tapCell(tester, 9);
      await tapCell(tester, 8, times: 2);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tutorialNext')));
      await tester.pumpAndSettle();
      await tapCell(tester, 14, times: 2);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tutorialNext')));
      await tester.pumpAndSettle();
      await tapCell(tester, 7, times: 2);
      await tester.pumpAndSettle();
      expect(find.text("Let's play!"), findsOneWidget);
      await tester.tap(find.byKey(const Key('tutorialNext')));
      await tester.pumpAndSettle();
      expect(stats.tutorialDone(GameKind.nests), isTrue);
      expect(app.analytics.events.where((e) => e.$1 == 'tutorial_done'), hasLength(1));
      // Straight into the daily.
      expect(find.text('Daily #12'), findsOneWidget);
      expect(find.byKey(const Key('hint')), findsOneWidget);
      await tester.tap(find.byKey(const Key('back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('daily-nests')));
      await tester.pumpAndSettle();
      expect(find.text('How to play Nests'), findsNothing);
      expect(find.byKey(const Key('hint')), findsOneWidget);
    });

    testWidgets('the tutorial can be skipped', (tester) async {
      await app.pump(tester);
      await tester.tap(find.byKey(const Key('level-pairs')));
      await tester.pumpAndSettle();
      expect(find.text('How to play Pairs'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tutorialSkip')));
      await tester.pumpAndSettle();
      expect(stats.tutorialDone(GameKind.pairs), isTrue);
      expect(find.text('Level 1'), findsOneWidget);
    });

    testWidgets('opening a capsule adds a critter', (tester) async {
      await stats.addCapsule();
      await app.pump(tester);
      expect(find.byKey(const Key('capsuleBadge')), findsOneWidget);
      await tester.tap(find.byKey(const Key('capsules')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('capsule')));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
      expect(stats.owned, hasLength(1));
      expect(stats.capsules, 0);
      expect(find.byKey(const Key('revealName')), findsOneWidget);
      expect(find.text('New in your album! ✨'), findsOneWidget);
      expect(app.analytics.events.where((e) => e.$1 == 'capsule_open'), hasLength(1));
      // Out of capsules: one more for a video, once a day.
      await tester.tap(find.byKey(const Key('capsuleAd')));
      await tester.pumpAndSettle();
      expect(stats.capsules, 1);
      expect(stats.adCapsuleTaken(today), isTrue);
      expect(find.byKey(const Key('capsule')), findsOneWidget);
    });

    testWidgets('a duplicate pays coins and a golden capsule gives a golden critter', (tester) async {
      await stats.addCapsule(golden: true);
      for (final c in album.where((c) => c.rarity == Rarity.golden)) {
        await stats.addCritter(c.id);
      }
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await app.pump(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(MaterialPageRoute(builder: (_) => CapsuleScreen(random: Random(3))));
      await tester.pumpAndSettle();
      expect(find.text('Golden capsule!'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('capsule')));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
      expect(stats.goldenCapsules, 0);
      expect(stats.coins, Economy.starting + Economy.duplicateCritter);
      expect(find.text('Already in your album: +${Economy.duplicateCritter} coins'), findsOneWidget);
    });

    testWidgets('album shows owned critters and silhouettes', (tester) async {
      await stats.addCritter('chick');
      await stats.addCritter('cow');
      await app.pump(tester);
      await tester.tap(find.byKey(const Key('album')));
      // The golden shimmer loops: pump instead of settling.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Album'), findsOneWidget);
      expect(find.text('2/30'), findsOneWidget);
      expect(find.text('Chick'), findsOneWidget);
      expect(find.text('Cow'), findsOneWidget);
      expect(find.text('???'), findsWidgets);
    });

    testWidgets('French strings', (tester) async {
      await stats.addCapsule();
      await app.pump(tester, locale: const Locale('fr'));
      expect(find.text('Défis du jour'), findsOneWidget);
      expect(find.text('Défi #12'), findsOneWidget);
      expect(find.text('Jouer'), findsNWidgets(2));
      expect(find.text('Niveaux'), findsOneWidget);
      expect(find.text('Niveau 1'), findsNWidgets(2));
      expect(find.text('Nids'), findsWidgets);
      expect(find.text('Paires'), findsWidgets);
      expect(find.text('À ouvrir !'), findsOneWidget);
      expect(find.text('0 jour'), findsOneWidget);
      await tester.tap(find.byKey(const Key('daily-pairs')));
      await tester.pumpAndSettle();
      expect(find.text('Comment jouer : Paires'), findsOneWidget);
      expect(find.text('Passer'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tutorialSkip')));
      await tester.pumpAndSettle();
      expect(find.text('Indice'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Recommencer'), findsOneWidget);
    });

    testWidgets('settings persist the toggles', (tester) async {
      await app.pump(tester);
      await tester.tap(find.byKey(const Key('settings')));
      await tester.pumpAndSettle();
      expect(find.text('Art and sounds: Kenney (kenney.nl), CC0'), findsOneWidget);
      await tester.tap(find.byKey(const Key('soundToggle')));
      await tester.tap(find.byKey(const Key('musicToggle')));
      await tester.tap(find.byKey(const Key('autoCrossToggle')));
      await tester.tap(find.byKey(const Key('remindersToggle')));
      await tester.pumpAndSettle();
      expect(app.sound.muted, isTrue);
      expect(stats.autoCross, isFalse);
      // The test app has no notification permission: the reminder stays off and says why.
      expect(stats.remindersOn, isFalse);
      expect(find.text('Turn on notifications for Critter Logic in your phone settings.'), findsOneWidget);
    });

    for (final locale in const [Locale('en'), Locale('fr')]) {
      testWidgets('every screen fits a 360×640 phone ($locale)', (tester) async {
        await stats.addCapsule();
        await app.pump(tester, locale: locale, size: const Size(360, 640));
        Future<void> visit(Key key, {bool settle = true}) async {
          final list = find.byType(Scrollable).first;
          if (find.byKey(key).evaluate().isEmpty) {
            // Back to the top, then down to the target.
            await tester.drag(list, const Offset(0, 2000));
            await tester.pumpAndSettle();
          }
          if (find.byKey(key).evaluate().isEmpty) await tester.scrollUntilVisible(find.byKey(key), 100, scrollable: list);
          await tester.ensureVisible(find.byKey(key));
          await tester.pump();
          await tester.tap(find.byKey(key));
          settle ? await tester.pumpAndSettle() : await tester.pump(const Duration(seconds: 1));
        }

        Future<void> back() async {
          tester.state<NavigatorState>(find.byType(Navigator)).pop();
          await tester.pump(const Duration(seconds: 1));
        }

        await visit(const Key('daily-nests')); // tutorial
        await tester.tap(find.byKey(const Key('tutorialSkip')));
        await tester.pumpAndSettle();
        await solveNests(tester);
        await tester.pumpAndSettle(); // result
        await tester.tap(find.byKey(const Key('resultHome')));
        await tester.pumpAndSettle();
        await visit(const Key('daily-pairs'));
        await tester.tap(find.byKey(const Key('tutorialSkip')));
        await tester.pumpAndSettle();
        await tapCell(tester, 1);
        await back();
        await visit(const Key('settings'));
        await back();
        await visit(const Key('capsules'));
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const Key('capsule')));
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpAndSettle();
        await back();
        await visit(const Key('album'), settle: false);
        await back();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
