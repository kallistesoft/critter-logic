import 'dart:math';

import 'album.dart';
import 'collection.dart';

/// Coin prices and rewards. Kept in one place so they can move to Remote Config.
class Economy {
  static const levelWin = 10;
  static const levelWinNoHint = 15;
  static const dailyWin = 20;
  static const hintCost = 30;
  /// A copy of a critter already at ⭐5.
  static const duplicateCritter = 25;

  /// Coins for an owned critter reaching ⭐2..⭐5 (see [CritterLevels]).
  static const levelUp = {2: 10, 3: 20, 4: 30, 5: 50};
  static int levelUpCoins(int level) => levelUp[level] ?? 0;
  static const setComplete = 200;

  /// Coins a new player starts with: enough for a few hints.
  static const starting = 90;
}

/// A streak milestone reward, claimed once per streak day reached.
class StreakChest {
  const StreakChest({required this.coins, this.capsule = false, this.golden = false});

  final int coins;
  final bool capsule;

  /// A capsule that always holds a golden critter (day 30).
  final bool golden;
}

/// Day 3, every 7th day and day 30 of a streak give a chest (Unarrow's streak rewards, in coins and capsules).
StreakChest? chestForStreak(int streak) {
  if (streak == 30) return const StreakChest(coins: 300, capsule: true, golden: true);
  if (streak > 0 && streak % 7 == 0) return const StreakChest(coins: 100, capsule: true);
  if (streak == 3) return const StreakChest(coins: 50);
  return null;
}

/// Rarity odds of a capsule, in percent (common gets the rest).
class CapsuleOdds {
  const CapsuleOdds({this.rare = 22, this.golden = 3});

  final int rare;
  final int golden;

  Rarity roll(Random random) {
    final r = random.nextInt(100);
    if (r < golden) return Rarity.golden;
    if (r < golden + rare) return Rarity.rare;
    return Rarity.common;
  }
}

/// What a capsule holds: a [critter], [duplicate] if it was owned already, and [completedSet] when it finishes a
/// set. Paying it is [grantCritter]'s job.
class CapsuleResult {
  const CapsuleResult(this.critter, {required this.duplicate, this.completedSet});

  final Critter critter;
  final bool duplicate;
  final String? completedSet;
}

/// Opens a capsule: rolls the rarity, then prefers a critter of that rarity the player doesn't have yet; once all
/// are owned, one not at ⭐5 yet; only then any. [copies] is the player's copies by critter id.
CapsuleResult openCapsule(Map<String, int> copies, Random random,
    {CapsuleOdds odds = const CapsuleOdds(),
    CritterLevels levels = const CritterLevels(),
    bool forceGolden = false}) {
  final rarity = forceGolden ? Rarity.golden : odds.roll(random);
  final pool = album.where((c) => c.rarity == rarity).toList();
  int have(Critter c) => copies[c.id] ?? 0;
  final missing = pool.where((c) => have(c) == 0).toList();
  final growing = pool.where((c) => levels.level(rarity, have(c)) < maxCritterLevel).toList();
  final from = missing.isNotEmpty ? missing : (growing.isNotEmpty ? growing : pool);
  final critter = from[random.nextInt(from.length)];
  final duplicate = have(critter) > 0;
  String? completed;
  if (!duplicate && album.where((c) => c.set == critter.set).every((c) => c.id == critter.id || have(c) > 0)) {
    completed = critter.set;
  }
  return CapsuleResult(critter, duplicate: duplicate, completedSet: completed);
}
