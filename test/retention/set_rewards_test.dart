import 'package:critter_logic/meta/album.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/meta/retention.dart';
import 'package:critter_logic/meta/set_rewards.dart';
import 'package:critter_logic/meta/shop.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StatsStore stats;
  late ProgressStore progress;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
    progress = await ProgressStore.open();
  });

  Future<void> own(String set) async {
    for (final c in album.where((c) => c.set == set)) {
      await stats.addCritter(c.id);
    }
  }

  test('every set unlocks a shop hat or bonus coins', () {
    expect({...setUnlocks.keys, ...setBonusCoins.keys}, albumSets.toSet());
    expect(setUnlocks.keys.toSet().intersection(setBonusCoins.keys.toSet()), isEmpty);
    expect(setBonusCoins, {'friends': 300, 'jungle': 300, 'polar': 300});
    for (final id in [...setUnlocks.values, ...fullAlbumUnlocks.where((c) => !c.startsWith('frame.'))]) {
      expect(shopItemById, contains(id));
      expect(id, startsWith('hat.'));
    }
  });

  test('a completed set gives its unlock once', () async {
    await own('farm');
    final first = await grantSetUnlocks(stats, progress);
    expect(first.map((u) => u.set), ['farm']);
    expect(progress.cosmetics, contains('hat.flowers'));
    expect(await grantSetUnlocks(stats, progress), isEmpty);
    // The unlocked hat is owned in the shop, so it isn't for sale any more.
    expect(Shop(stats, progress).owns(shopItemById['hat.flowers']!), isTrue);
  });

  test('sets that used to give a board theme pay 300 coins instead, once', () async {
    await own('polar');
    final coins = stats.coins;
    final first = await grantSetUnlocks(stats, progress);
    expect(first.single.set, 'polar');
    expect(first.single.cosmetics, isEmpty);
    expect(first.single.coins, 300);
    expect(stats.coins, coins + 300);
    expect(await grantSetUnlocks(stats, progress), isEmpty);
    expect(stats.coins, coins + 300);
  });

  test('the full album gives the crown, the gold frame and 1000 coins', () async {
    for (final set in albumSets) {
      await own(set);
    }
    final coins = stats.coins;
    final given = await grantSetUnlocks(stats, progress);
    expect(given.length, albumSets.length + 1);
    expect(given.last.set, 'all');
    expect(progress.cosmetics, containsAll(fullAlbumUnlocks));
    expect(fullAlbumUnlocks, ['hat.crown', 'frame.album_gold']);
    expect(fullAlbumCoins, 1000);
    expect(stats.coins, coins + fullAlbumCoins + 3 * 300);
  });

  test('opening a capsule reports a set just completed', () async {
    await own('farm');
    final r = Retention(stats: stats, progress: progress);
    final update = await r.recordEvent(const CapsuleOpened(), DateTime(2027, 1, 4));
    expect(update.setUnlocks.single.cosmetics, ['hat.flowers']);
  });
}
