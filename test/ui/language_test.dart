import 'package:critter_logic/main.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/services/reminder_service.dart';
import 'package:critter_logic/services/sound_service.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class RecordingReminders implements ReminderService {
  final texts = <ReminderText>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> plan({required bool enabled, required bool todayDone, required ReminderText text}) async =>
      texts.add(text);
}

void main() {
  late StatsStore stats;
  late TestApp app;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'flutter.progress.world.chosen': true});
    stats = await StatsStore.open();
    app = TestApp(stats);
  });

  Future<void> open(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('Spanish strings: home, a game, the shop and settings', (tester) async {
    await stats.addCapsule();
    await app.pump(tester, locale: const Locale('es'));
    expect(find.text('Retos de hoy'), findsOneWidget);
    expect(find.text('Reto #12'), findsOneWidget);
    expect(find.text('Jugar'), findsNWidgets(3));
    expect(find.text('Niveles'), findsOneWidget);
    expect(find.text('Nivel 1'), findsNWidgets(3));
    expect(find.text('Nidos'), findsWidgets);
    expect(find.text('Parejas'), findsWidgets);
    expect(find.text('Sendero'), findsWidgets);
    expect(find.text('0 días'), findsOneWidget);

    await tester.tap(find.byKey(const Key('daily-pairs')));
    await tester.pumpAndSettle();
    expect(find.text('Cómo jugar: Parejas'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorialSkip')));
    await tester.pumpAndSettle();
    expect(find.text('Pista'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);
    expect(find.text('Reiniciar'), findsOneWidget);
    await back(tester);

    await open(tester, const Key('shopStall'));
    expect(find.text('Tienda'), findsOneWidget);
    expect(find.text('Sombreros'), findsOneWidget);
    await back(tester);

    await open(tester, const Key('luckyNest'));
    expect(find.text('Nido de la suerte'), findsWidgets);
    await back(tester);

    await open(tester, const Key('settings'));
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Efectos de sonido'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Idioma del sistema'), findsOneWidget);
  });

  testWidgets('the language picker switches live and is remembered', (tester) async {
    await app.pump(tester);
    expect(find.text("Today's puzzles"), findsOneWidget);
    await open(tester, const Key('settings'));
    expect(find.text('System default'), findsOneWidget);

    await tester.tap(find.byKey(const Key('languageRow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lang-es')));
    await tester.pumpAndSettle();
    // Still on Settings, now in Spanish.
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(stats.language, 'es');
    expect((await SharedPreferences.getInstance()).getString('language'), 'es');
    await back(tester);
    expect(find.text('Retos de hoy'), findsOneWidget);

    // A fresh start reads it back.
    final reopened = await StatsStore.open();
    expect(reopened.language, 'es');

    await open(tester, const Key('settings'));
    await tester.tap(find.byKey(const Key('languageRow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lang-fr')));
    await tester.pumpAndSettle();
    expect(find.text('Réglages'), findsOneWidget);

    await tester.tap(find.byKey(const Key('languageRow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lang-system')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(stats.language, isNull);
    expect((await SharedPreferences.getInstance()).getString('language'), isNull);
  });

  testWidgets('a test locale wins over the saved language', (tester) async {
    await stats.setLanguage('es');
    await app.pump(tester, locale: const Locale('fr'));
    expect(find.text('Défis du jour'), findsOneWidget);
  });

  testWidgets('the saved language is used at start', (tester) async {
    await stats.setLanguage('es');
    await app.pump(tester);
    expect(find.text('Retos de hoy'), findsOneWidget);
  });

  testWidgets('reminders follow the picked language', (tester) async {
    await stats.setRemindersOn(true);
    await stats.prefs.setInt('progress.cal.shownDay', localDay(app.now));
    calmMotion(tester);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final reminders = RecordingReminders();
    await tester.pumpWidget(CritterLogicApp(
      stats: stats,
      ads: CountingAds(),
      sound: NoSound(),
      puzzles: FakePuzzleSource(),
      today: () => app.now,
      reminders: reminders,
    ));
    await tester.pumpAndSettle();
    await open(tester, const Key('settings'));
    await tester.tap(find.byKey(const Key('languageRow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lang-es')));
    await tester.pumpAndSettle();
    expect(reminders.texts.last.title, 'Tus animalitos te esperan 🐣');
    expect(reminders.texts.last.body, 'Los Nidos y las Parejas de hoy están listos.');
    expect(reminders.texts.last.channel, 'Reto del día');
  });
}
