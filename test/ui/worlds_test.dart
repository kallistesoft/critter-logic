import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/meta/shop.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:critter_logic/ui/critter_actor.dart';
import 'package:critter_logic/ui/home_screen.dart';
import 'package:critter_logic/ui/lucky_nest_screen.dart';
import 'package:critter_logic/ui/worlds/world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Asset names of the images on screen.
Iterable<String> imageAssets(WidgetTester tester) sync* {
  for (final image in tester.widgetList<Image>(find.byType(Image))) {
    var provider = image.image;
    if (provider is ResizeImage) provider = provider.imageProvider;
    if (provider is AssetImage) yield provider.assetName;
    if (provider is ExactAssetImage) yield provider.assetName;
  }
}

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

  tearDown(() => activeWorld = worlds.first);

  ProgressStore progress() => ProgressStore(stats.prefs);

  test('every World has a shop item, a unique id and 10 zone colors', () {
    expect(worlds.map((w) => w.id).toSet().length, worlds.length);
    for (final w in worlds) {
      expect(shopItemById[w.id]?.category, ShopCategory.world);
      expect(w.board.zones.length, greaterThanOrEqualTo(10));
    }
    expect(worlds.first.id, defaultWorld);
  });

  group('welcome picker', () {
    testWidgets('shows on first launch, picks the Lodge, then never again', (tester) async {
      app.welcome = true;
      await app.pump(tester);
      expect(find.byKey(const Key('welcomeGo')), findsOneWidget);
      expect(find.byKey(const Key('welcome-world.meadow')), findsOneWidget);
      expect(find.byKey(const Key('welcome-world.lodge')), findsOneWidget);
      expect(find.byKey(const Key('welcome-world.neon')), findsNothing, reason: 'only the free Worlds');
      await tester.tap(find.byKey(const Key('welcome-world.lodge')));
      await tester.pumpAndSettle();
      expect(find.text('Play in Wild Lodge'), findsOneWidget);
      await tester.tap(find.byKey(const Key('welcomeGo')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(activeWorld.id, 'world.lodge');
      expect(progress().worldChosen, isTrue);
      expect(progress().equipped('world'), 'world.lodge');

      app.welcome = false;
      await tester.pumpWidget(const SizedBox());
      await app.pump(tester);
      expect(find.byKey(const Key('welcomeGo')), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(activeWorld.id, 'world.lodge');
    });

    testWidgets('skipping keeps the Meadow', (tester) async {
      app.welcome = true;
      await app.pump(tester);
      await tester.tap(find.byKey(const Key('welcomeSkip')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(activeWorld.id, 'world.meadow');
      expect(progress().worldChosen, isTrue);
    });
  });

  group('shop Worlds tab', () {
    Future<void> openWorlds(WidgetTester tester) async {
      await scrollTo(tester, find.byKey(const Key('shopStall')));
      await tester.tap(find.byKey(const Key('shopStall')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-worlds')));
      await tester.pumpAndSettle();
    }

    testWidgets('buying a World equips it and redraws the app; owned ones equip for free', (tester) async {
      await stats.addCoins(3000);
      await app.pump(tester);
      await openWorlds(tester);
      expect(find.byKey(const Key('equipped-world.meadow')), findsOneWidget);
      await scrollTo(tester, find.byKey(const Key('buy-world.neon')));
      await tester.tap(find.byKey(const Key('buy-world.neon')));
      await tester.pumpAndSettle();
      expect(activeWorld.id, 'world.neon');
      expect(progress().equipped('world'), 'world.neon');
      expect(progress().cosmetics, contains('world.neon'));
      expect(app.analytics.events.map((e) => e.$1), containsAll(['shop_purchase', 'world_equip']));
      expect(find.byKey(const Key('equipped-world.neon')), findsOneWidget);
      // The free Lodge equips without paying.
      final coins = stats.coins;
      await scrollTo(tester, find.byKey(const Key('equip-world.lodge')));
      await tester.tap(find.byKey(const Key('equip-world.lodge')));
      await tester.pumpAndSettle();
      expect(activeWorld.id, 'world.lodge');
      expect(stats.coins, coins);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a World can be previewed full screen before buying', (tester) async {
      await app.pump(tester);
      await openWorlds(tester);
      await scrollTo(tester, find.byKey(const Key('preview-world.winter')));
      await tester.tap(find.byKey(const Key('preview-world.winter')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('worldPreview')), findsOneWidget);
      expect(activeWorld.id, 'world.meadow', reason: 'previewing changes nothing');
      await tester.tap(find.byKey(const Key('worldPreview')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('worldPreview')), findsNothing);
      expect(find.byKey(const Key('buy-world.winter')), findsOneWidget);
    });
  });

  testWidgets('the Lodge draws wildlife badges, never the cartoon sprites', (tester) async {
    await stats.addCritter('bear');
    app.world = 'world.lodge';
    await app.pump(tester);
    expect(imageAssets(tester).where((a) => a.startsWith('assets/critters/')), isEmpty);
    expect(imageAssets(tester).where((a) => a.startsWith('assets/silhouettes/')), isNotEmpty);
    await tester.tap(find.byKey(const Key('daily-nests')));
    await tester.pumpAndSettle();
    await tapCell(tester, 1, times: 2);
    await tester.pumpAndSettle();
    expect(imageAssets(tester).where((a) => a.startsWith('assets/critters/')), isEmpty);
    expect(imageAssets(tester).where((a) => a.startsWith('assets/silhouettes/')), isNotEmpty);
  });

  testWidgets('Clean Pro hides the decorations: no mascots, stall or nest, tokens on the board', (tester) async {
    app.world = 'world.pro';
    await app.pump(tester);
    expect(find.byType(CritterBuddy), findsNothing);
    expect(find.byType(ShopStall), findsNothing);
    expect(find.byType(LuckyNestProp), findsNothing);
    expect(find.byKey(const Key('shopStall')), findsOneWidget, reason: 'a plain shop button instead');
    expect(find.byKey(const Key('luckyNest')), findsOneWidget);
    await tester.tap(find.byKey(const Key('daily-nests')));
    await tester.pumpAndSettle();
    await tapCell(tester, 1, times: 2);
    await tester.pumpAndSettle();
    expect(
      imageAssets(tester).where((a) => a.startsWith('assets/critters/')),
      isEmpty,
      reason: 'gold tokens, not critters',
    );
  });
}
