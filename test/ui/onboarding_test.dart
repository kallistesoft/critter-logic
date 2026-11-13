import 'package:critter_logic/meta/onboarding.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:critter_logic/ui/event_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  late StatsStore stats;
  late TestApp app;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
    app = TestApp(stats);
  });

  Future<void> firstLaunchDaysAgo(int days) =>
      stats.prefs.setInt('firstLaunch', app.now.subtract(Duration(days: days)).millisecondsSinceEpoch);

  testWidgets('a new player sees the puzzles first: no shop, nest, calendar or event yet', (tester) async {
    await firstLaunchDaysAgo(0);
    await app.pump(tester, newPlayer: true, calendar: true);
    expect(find.byKey(const Key('daily-nests')), findsWidgets);
    expect(find.byKey(const Key('shopStall')), findsNothing);
    expect(find.byKey(const Key('luckyNest')), findsNothing);
    expect(find.byKey(const Key('calendarButton')), findsNothing);
    expect(find.byType(EventBanner), findsNothing);
    expect(find.byKey(const Key('calendar')), findsNothing, reason: 'no calendar popup on day one');
  });

  testWidgets('the first solved puzzle opens the shop and the Lucky Nest', (tester) async {
    await firstLaunchDaysAgo(0);
    await stats.addLevelWon();
    await app.pump(tester, newPlayer: true);
    expect(find.byKey(const Key('shopStall')), findsOneWidget);
    expect(find.byKey(const Key('luckyNest')), findsOneWidget);
    expect(find.byKey(const Key('calendarButton')), findsNothing);
  });

  testWidgets('the calendar arrives on the second day, the event after 3 dailies', (tester) async {
    await firstLaunchDaysAgo(1);
    await app.pump(tester, newPlayer: true);
    expect(find.byKey(const Key('calendarButton')), findsOneWidget);
    expect(find.byType(EventBanner), findsNothing);
    await stats.prefs.setInt('dailiesSolved', 3);
    expect(Onboarding(stats).eventOpen, isTrue);
  });
}
