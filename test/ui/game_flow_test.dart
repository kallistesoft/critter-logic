import 'package:critter_logic/meta/economy.dart';
import 'package:critter_logic/meta/game_flow.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  late StatsStore stats;
  late TestApp app;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'flutter.tutorial.nests': true,
      'flutter.tutorial.pairs': true,
      'flutter.tutorial.trail': true,
    });
    stats = await StatsStore.open();
    app = TestApp(stats);
  });

  Future<void> openDaily(WidgetTester tester, GameKind kind) async {
    await tester.tap(find.byKey(Key('daily-${kind.name}')));
    await tester.pumpAndSettle();
  }

  testWidgets('home shows the three dailies, streak, coins and levels', (tester) async {
    await app.pump(tester);
    expect(find.text('Critter Logic'), findsOneWidget);
    expect(find.byKey(const Key('daily-nests')), findsOneWidget);
    expect(find.byKey(const Key('daily-pairs')), findsOneWidget);
    expect(find.byKey(const Key('daily-trail')), findsOneWidget);
    expect(find.text('Trail'), findsNWidgets(2), reason: 'daily card and level card');
    expect(find.byKey(const Key('level-trail')), findsOneWidget);
    expect(find.text('Daily #12'), findsOneWidget);
    expect(find.text('${Economy.starting}'), findsOneWidget);
    expect(find.text('Play'), findsNWidgets(3));
    expect(find.text('Level 1'), findsNWidgets(3));
    expect(find.byKey(const Key('capsuleBadge')), findsNothing);
  });

  testWidgets('solving the Nests daily by taps records it once and shows the result', (tester) async {
    await app.pump(tester);
    await openDaily(tester, GameKind.nests);
    expect(find.byKey(const Key('cell-0')), findsOneWidget);
    await solveNests(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resultTime')), findsOneWidget);
    expect(find.text('Solved!'), findsOneWidget);
    final result = stats.daily(GameKind.nests, today)!;
    expect(result.millis, 0, reason: 'fixed clock, no mistakes, no hints');
    expect(stats.dailiesSolved, 1);
    expect(app.leaderboard.submits, [(GameKind.nests, today, 0)]);
    expect(app.leaderboard.profiles, 1);
    expect(stats.coins, Economy.starting + Economy.dailyWin);
    expect(stats.savedGame('nests.daily'), isNull);
    expect(app.analytics.events.where((e) => e.$1 == 'level_complete'), hasLength(1));
    expect(find.byKey(const Key('rewards')), findsOneWidget);

    // Leaving shows the interstitial; reopening shows the result, read-only, without posting again.
    await tester.tap(find.byKey(const Key('resultHome')));
    await tester.pumpAndSettle();
    expect(app.ads.interstitials, 1);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await openDaily(tester, GameKind.nests);
    expect(find.text('Already solved'), findsOneWidget);
    expect(find.byKey(const Key('rewards')), findsNothing);
    expect(app.leaderboard.submits, hasLength(1));
    expect(app.leaderboard.standings, 1);
    expect(stats.dailiesSolved, 1);
    await tester.tap(find.byKey(const Key('resultHome')));
    await tester.pumpAndSettle();
    expect(app.ads.interstitials, 1, reason: 'no interstitial after a read-only view');
  });

  testWidgets('solving all three dailies gives the day\'s capsule', (tester) async {
    await app.pump(tester);
    await openDaily(tester, GameKind.pairs);
    await solvePairs(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resultTime')), findsOneWidget);
    expect(stats.daily(GameKind.pairs, today)!.mistakes, 0, reason: 'cycling past a sun to a moon is free');
    expect(stats.capsules, 0);

    // "Play Nests" from the result screen.
    await scrollTo(tester, find.byKey(const Key('playOther')));
    await tester.tap(find.byKey(const Key('playOther')));
    await tester.pumpAndSettle();
    await solveNests(tester);
    await tester.pumpAndSettle();
    expect(stats.capsules, 0, reason: 'Trail still to play');
    expect(stats.dailyCapsuleGiven(today), isFalse);

    // "Play Trail": the one daily left.
    await scrollTo(tester, find.byKey(const Key('playOther')));
    expect(find.text('Play Trail'), findsOneWidget);
    await tester.tap(find.byKey(const Key('playOther')));
    await tester.pumpAndSettle();
    await solveTrail(tester);
    await tester.pumpAndSettle();
    expect(stats.capsules, 1);
    expect(stats.dailyCapsuleGiven(today), isTrue);
    expect(find.text('All dailies done: +1 capsule'), findsOneWidget);
    expect(find.byKey(const Key('playOther')), findsNothing);
    expect(app.leaderboard.submits.map((s) => s.$1), [GameKind.pairs, GameKind.nests, GameKind.trail]);
    expect(app.ads.interstitials, 2, reason: 'leaving each result for the next daily');
  });

  testWidgets('daily mistakes add 10 s and hints 30 s to the ranked time', (tester) async {
    await app.pump(tester);
    await openDaily(tester, GameKind.nests);
    // A critter in cell 0, then one in cell 5 touching it: a conflict left behind is a mistake.
    await tapCell(tester, 0, times: 2);
    await tapCell(tester, 5, times: 2);
    expect(find.byKey(const Key('penalty')), findsNothing, reason: 'still pending: fixing it on the spot is free');
    await tapCell(tester, 15); // another cell: now it counts
    expect(find.text('+10s'), findsOneWidget);
    // Clear the wrong critters (taps on the same cells: no new conflicts) and the cross.
    await tapCell(tester, 5);
    await tapCell(tester, 0);
    await tapCell(tester, 15, times: 2);

    // A hint (coins) places a critter.
    await tester.tap(find.byKey(const Key('hint')));
    await tester.pumpAndSettle();
    expect(stats.coins, Economy.starting - Economy.hintCost);
    expect(find.text('+40s'), findsOneWidget);
    // The hint put the first row's critter (cell 1); finish the rest.
    for (final c in fakeNestsCells.skip(1)) {
      await tapCell(tester, c, times: 2);
    }
    await tester.pumpAndSettle();
    final result = stats.daily(GameKind.nests, today)!;
    expect(result.mistakes, 1);
    expect(result.hints, 1);
    expect(result.millis, mistakePenaltyMillis + hintPenaltyMillis);
    expect(tester.widget<Text>(find.byKey(const Key('resultTime'))).data, '0:40');
    expect(app.leaderboard.submits.single.$3, 40000);
  });

  testWidgets('without coins, a hint offers a rewarded video', (tester) async {
    await stats.spendCoins(stats.coins - 10);
    await app.pump(tester);
    await openDaily(tester, GameKind.nests);
    await tester.tap(find.byKey(const Key('hint')));
    await tester.pumpAndSettle();
    expect(find.text('Not enough coins'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hintWatchAd')));
    await tester.pumpAndSettle();
    expect(app.ads.rewarded, 1);
    expect(stats.coins, 10, reason: 'the video paid for the hint');
    expect(app.analytics.events.where((e) => e.$1 == 'hint_used').single.$2['paid_with'], 'ad');

    // Ad not available: no hint.
    app.ads.rewardGranted = false;
    await tester.tap(find.byKey(const Key('hint')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hintWatchAd')));
    await tester.pumpAndSettle();
    expect(find.text('No ad available right now. Try again in a moment.'), findsOneWidget);
    expect(app.analytics.events.where((e) => e.$1 == 'hint_used'), hasLength(1));
  });

  testWidgets('a game in progress is saved and restored with its time', (tester) async {
    await app.pump(tester);
    await openDaily(tester, GameKind.pairs);
    await tapCell(tester, 3, times: 2);
    app.now = app.now.add(const Duration(seconds: 42));
    await tester.tap(find.byKey(const Key('back')));
    await tester.pumpAndSettle();
    final saved = stats.savedGame('pairs.daily')!;
    expect(saved['n'], today);
    expect(saved['e'], 42000);
    await openDaily(tester, GameKind.pairs);
    expect(find.text('0:42'), findsOneWidget);
  });

  testWidgets('levels: win pays coins, next level, no penalty', (tester) async {
    await app.pump(tester);
    await playLevel(tester, GameKind.nests);
    expect(find.text('Level 1'), findsOneWidget);
    await solveNests(tester);
    await tester.pumpAndSettle();
    expect(find.text('Level 1 solved!'), findsOneWidget);
    expect(stats.coins, Economy.starting + Economy.levelWinNoHint);
    expect(stats.level(GameKind.nests), 2);
    expect(stats.levelsWon, 1);
    await tester.tap(find.byKey(const Key('nextLevel')));
    await tester.pumpAndSettle();
    expect(find.text('Level 2'), findsOneWidget);
    expect(app.ads.interstitials, 0, reason: 'none before 5 level wins');
    expect(stats.levelStars(GameKind.nests, 1), 3, reason: 'no hint, no mistake');

    // Back on the map: level 1 is done, level 2 is the one to play.
    await tester.tap(find.byKey(const Key('back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('playLevel')), findsOneWidget);
    expect(find.text('Tap to play!'), findsOneWidget);
  });

  testWidgets('a finished level can be replayed for a rewarded video; coins only for more stars', (tester) async {
    await stats.recordLevelStars(GameKind.nests, 1, 1);
    await stats.setLevel(GameKind.nests, 2);
    await app.pump(tester);
    await tester.tap(find.byKey(const Key('level-nests')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('doneLevel-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('replayLevel')));
    await tester.pumpAndSettle();
    expect(app.ads.rewarded, 1);
    expect(find.text('Level 1'), findsOneWidget);
    await solveNests(tester);
    await tester.pumpAndSettle();
    expect(stats.levelStars(GameKind.nests, 1), 3);
    expect(stats.coins, Economy.starting + Economy.levelWinNoHint, reason: 'beat 1 star with 3');
    expect(stats.level(GameKind.nests), 2, reason: 'the track does not move');
    expect(stats.levelsWon, 0);
    expect(find.byKey(const Key('nextLevel')), findsNothing);

    // Again with no better stars: no coins.
    await tester.tap(find.byKey(const Key('levelHome')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('doneLevel-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('replayLevel')));
    await tester.pumpAndSettle();
    await solveNests(tester);
    await tester.pumpAndSettle();
    expect(stats.coins, Economy.starting + Economy.levelWinNoHint);
    expect(find.text('Nice! Beat your best stars to earn coins.'), findsOneWidget);
  });

  testWidgets('streak repair for a rewarded video', (tester) async {
    await stats.recordDaily(const DailyResult(kind: GameKind.nests, number: today - 2, millis: 60000));
    await app.pump(tester);
    expect(find.byKey(const Key('repair')), findsOneWidget);
    await tester.tap(find.byKey(const Key('repair')));
    await tester.pumpAndSettle();
    expect(app.ads.rewarded, 1);
    expect(stats.streak(today), 2);
    expect(find.byKey(const Key('repair')), findsNothing);
  });
}
