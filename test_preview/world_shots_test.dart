// Dev tool (not part of the suite): renders key screens of every World to PNGs with the real fonts.
//   flutter test test_preview/world_shots_test.dart --update-goldens [--plain-name lodge]
// Output: $WORLD_SHOTS (default /tmp/world_shots)/<world>_<screen>.png
import 'dart:io';

import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:critter_logic/ui/worlds/world.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/ui/helpers.dart';

final out = Platform.environment['WORLD_SHOTS'] ?? '/tmp/world_shots';

Future<void> loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
        .readAsBytes()
        .then((b) => ByteData.view(b.buffer)));
  await icons.load();
  final roboto = FontLoader('Roboto')
    ..addFont(File('$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf')
        .readAsBytes()
        .then((b) => ByteData.view(b.buffer)));
  await roboto.load();
  final families = {
    'Fredoka': ['Fredoka-Medium', 'Fredoka-SemiBold', 'Fredoka-Bold'],
    'ZillaSlab': ['ZillaSlab-Medium', 'ZillaSlab-SemiBold', 'ZillaSlab-Bold'],
    'Bevan': ['Bevan-Regular'],
    'Exo2': ['Exo2-Medium', 'Exo2-SemiBold', 'Exo2-Bold'],
    'Inter': ['Inter-Medium', 'Inter-SemiBold', 'Inter-Bold'],
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(rootBundle.load('assets/fonts/$f.ttf'));
    }
    await loader.load();
  }
}

Future<void> precache(WidgetTester tester) async {
  final ctx = tester.element(find.byType(Navigator).first);
  await tester.runAsync(() async {
    for (final dir in ['critters', 'silhouettes']) {
      for (final id in ['chick', 'chicken', 'duck', 'pig', 'goat', 'cow', 'dog', 'rabbit', 'frog', 'horse', 'owl',
        'panda', 'zebra', 'buffalo', 'hippo', 'rhino', 'giraffe', 'elephant', 'snake', 'crocodile', 'parrot',
        'gorilla', 'monkey', 'sloth', 'moose', 'bear', 'walrus', 'whale', 'penguin', 'narwhal']) {
        await precacheImage(AssetImage('assets/$dir/$id.png'), ctx);
      }
    }
  });
}

Future<void> shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 50));
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$out/$name.png')));
}

void main() {
  setUpAll(loadFonts);
  for (final w in worlds) {
    final short = w.id.split('.').last;
    testWidgets('shots $short', (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.tutorial.nests': true,
        'flutter.tutorial.pairs': true,
        'flutter.tutorial.trail': true,
        'flutter.progress.world.chosen': true,
        'flutter.progress.equipped.world': w.id,
        'flutter.progress.cosmetics': [w.id],
      });
      final stats = await StatsStore.open();
      await stats.addCoins(2400);
      for (final c in ['chick', 'dog', 'bear', 'owl', 'moose', 'panda', 'frog', 'penguin', 'zebra', 'pig']) {
        await stats.addCritter(c);
      }
      await stats.prefs.setInt('progress.cal.shownDay', localDay(DateTime(2026, 12, 12, 10)));
      final app = TestApp(stats);
      await app.pump(tester);
      await precache(tester);
      await tester.pumpAndSettle();
      await shot(tester, '${short}_home');

      await tester.tap(find.byKey(const Key('daily-nests')));
      await tester.pumpAndSettle();
      await tapCell(tester, 1, times: 2);
      await tapCell(tester, 7, times: 2);
      await tapCell(tester, 0);
      await tester.pumpAndSettle();
      await shot(tester, '${short}_nests');
      await tapCell(tester, 0, times: 2);
      await tapCell(tester, 8, times: 2);
      await tapCell(tester, 14, times: 2);
      await tester.pumpAndSettle();
      await shot(tester, '${short}_result');
      await tester.tap(find.byKey(const Key('resultHome')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('daily-trail')));
      await tester.pumpAndSettle();
      await dragPath(tester, fakeTrail.solution.take(9).toList());
      await tester.pumpAndSettle();
      await shot(tester, '${short}_trail');
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('daily-pairs')));
      await tester.pumpAndSettle();
      for (final c in [1, 3, 4, 5]) {
        await tapCell(tester, c);
      }
      await tester.pumpAndSettle();
      await shot(tester, '${short}_pairs');
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byKey(const Key('album')));
      await tester.tap(find.byKey(const Key('album')));
      await tester.pumpAndSettle();
      await shot(tester, '${short}_album');
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 8)); // toasts away
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const Key('shopStall')));
      await tester.tap(find.byKey(const Key('shopStall')));
      await tester.pumpAndSettle();
      if (find.byKey(const Key('tab-worlds')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('tab-worlds')));
        await tester.pumpAndSettle();
      }
      await shot(tester, '${short}_shop');
    });
  }
}
