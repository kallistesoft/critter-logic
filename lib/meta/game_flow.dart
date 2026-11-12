import '../daily.dart';
import '../puzzles/puzzle.dart';
import '../services/stats_store.dart';
import 'economy.dart';

/// Ranked-time penalties in the daily (levels have none).
const mistakePenaltyMillis = 10000;
const hintPenaltyMillis = 30000;

/// Time the leaderboard ranks: the clock plus the penalties.
int rankedMillis(int elapsed, {required int mistakes, required int hints}) =>
    elapsed + mistakes * mistakePenaltyMillis + hints * hintPenaltyMillis;

/// Today's daily number. Before the first daily (pre-launch builds) everyone plays #1.
int todayNumber(DateTime now) {
  final n = dailyNumberFor(now);
  return n < 1 ? 1 : n;
}

enum PlayMode { daily, level }

/// Save slot of the puzzle in progress, e.g. 'nests.daily'.
String saveSlot(GameKind kind, PlayMode mode) => '${kind.name}.${mode.name}';

/// What solving a daily gave, for the result screen.
class DailyRewards {
  const DailyRewards({required this.coins, required this.capsule, required this.streak, this.chest});

  final int coins;

  /// The day's capsule for solving every daily.
  final bool capsule;
  final int streak;

  /// A streak milestone chest, already paid out.
  final StreakChest? chest;
}

/// Pays the rewards of a daily solved for the first time (call only when [StatsStore.recordDaily] returned true):
/// coins, the day's capsule once all dailies are done, the streak chest, and the best streak.
Future<DailyRewards> grantDailyRewards(StatsStore stats, int day) async {
  await stats.addCoins(Economy.dailyWin);
  var capsule = false;
  if (stats.allDailiesDone(day) && !stats.dailyCapsuleGiven(day)) {
    await stats.setDailyCapsuleGiven(day);
    await stats.addCapsule();
    capsule = true;
  }
  final streak = stats.streak(day);
  var chest = chestForStreak(streak);
  if (chest != null && !stats.chestClaimed(day)) {
    await stats.claimChest(day);
    await stats.addCoins(chest.coins);
    if (chest.capsule) await stats.addCapsule(golden: chest.golden);
  } else {
    chest = null;
  }
  await stats.updateBestStreak(day);
  return DailyRewards(coins: Economy.dailyWin, capsule: capsule, streak: streak, chest: chest);
}

/// Stars for a solve (1–3): 3 with no hint and no mistake, 2 with one of the two, 1 otherwise.
int starsFor({required int hints, required int mistakes}) => 1 + (hints == 0 ? 1 : 0) + (mistakes == 0 ? 1 : 0);

/// Coins for a level win.
int levelReward({required int hints}) => hints == 0 ? Economy.levelWinNoHint : Economy.levelWin;

/// UI settings that StatsStore doesn't have a field for yet (kept in a 'settings' save slot).
