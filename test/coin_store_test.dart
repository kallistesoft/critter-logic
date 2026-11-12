import 'package:critter_logic/meta/lucky_nest.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/services/coin_store_service.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late StatsStore stats;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    stats = StatsStore(prefs);
  });

  test('packs get better per dollar as they grow', () {
    expect(coinPacks.map((p) => p.coins), [150, 350, 1000]);
    const prices = [0.99, 1.99, 4.99];
    final perDollar = [for (var i = 0; i < 3; i++) coinPacks[i].coins / prices[i]];
    expect(perDollar[1], greaterThan(perDollar[0]));
    expect(perDollar[2], greaterThan(perDollar[1]));
  });

  test('a purchase is credited once, even if the store delivers it again', () async {
    final store = StoreCoinService(stats, prefs);
    final start = stats.coins;
    expect(await store.credit('coins_350', 'GPA.1'), 350);
    expect(await store.credit('coins_350', 'GPA.1'), 0);
    expect(await store.credit('coins_150', 'GPA.2'), 150);
    expect(await store.credit('remove_ads', 'GPA.3'), 0);
    expect(stats.coins, start + 500);
  });

  test('paid eggs can be switched off by Remote Config; the free egg stays', () async {
    final progress = ProgressStore(prefs);
    await stats.addCoins(500);
    final s = LuckySettings.parse('paid=0');
    expect(s.paidEnabled, isFalse);
    final nest = LuckyNest(stats, progress, settings: s);
    expect((await nest.draw(3))!.free, isTrue);
    expect(nest.state(3).paidLeft, 0);
    expect(await nest.draw(3), isNull);
    expect(LuckySettings.parse('').paidEnabled, isTrue);
  });
}
