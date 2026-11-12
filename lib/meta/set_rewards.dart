import '../services/stats_store.dart';
import 'album.dart';
import 'progress_store.dart';

/// The cosmetic each completed album set unlocks (also sold in the shop, for players who don't want to wait).
const setUnlocks = <String, String>{
  'farm': 'hat.flowers',
  'friends': 'theme.sunset',
  'savanna': 'hat.party',
  'jungle': 'theme.autumn',
  'polar': 'theme.snowy',
};

/// Completing the whole album (all 30 critters) unlocks these, plus [fullAlbumCoins].
const fullAlbumUnlocks = ['hat.crown', 'theme.starry', 'frame.album_gold'];
const fullAlbumCoins = 500;

/// What [grantSetUnlocks] gave, for the "Set complete!" celebration.
class SetUnlock {
  const SetUnlock({required this.set, required this.cosmetics, this.coins = 0});

  /// The set, or 'all' for the full album.
  final String set;
  final List<String> cosmetics;

  /// Bonus coins (the full album only; the per-set 200 coins are paid where the critter is granted).
  final int coins;
}

/// Grants the unlocks of every completed set (and the full album) not rewarded before. Safe to call any time,
/// e.g. after a capsule opens or at app start: each unlock is given once.
Future<List<SetUnlock>> grantSetUnlocks(StatsStore stats, ProgressStore progress) async {
  final owned = stats.owned;
  final given = <SetUnlock>[];
  for (final set in albumSets) {
    if (progress.setRewarded(set)) continue;
    if (!album.where((c) => c.set == set).every((c) => owned.contains(c.id))) continue;
    final cosmetic = setUnlocks[set];
    if (cosmetic != null) await progress.addCosmetic(cosmetic);
    await progress.setSetRewarded(set);
    given.add(SetUnlock(set: set, cosmetics: [?cosmetic]));
  }
  if (!progress.setRewarded('all') && album.every((c) => owned.contains(c.id))) {
    for (final c in fullAlbumUnlocks) {
      await progress.addCosmetic(c);
    }
    await stats.addCoins(fullAlbumCoins);
    await progress.setSetRewarded('all');
    given.add(const SetUnlock(set: 'all', cosmetics: fullAlbumUnlocks, coins: fullAlbumCoins));
  }
  return given;
}
