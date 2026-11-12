import 'dart:math';

import 'album.dart';

/// Coin prices and rewards. Kept in one place so they can move to Remote Config.
class Economy {
  static const levelWin = 10;
  static const levelWinNoHint = 15;
  static const dailyWin = 20;
  static const hintCost = 30;
  static const duplicateCritter = 25;
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

/// What a capsule gave: a [critter], [duplicate] if it was owned already (paid out as coins instead),
/// and [completedSet] when it finished a set.
class CapsuleResult {
  const CapsuleResult(this.critter, {required this.duplicate, this.completedSet});

  final Critter critter;
  final bool duplicate;
  final String? completedSet;
}

/// Opens a capsule: rolls the rarity, then prefers a critter of that rarity the player doesn't have yet.
CapsuleResult openCapsule(Set<String> owned, Random random,
    {CapsuleOdds odds = const CapsuleOdds(), bool forceGolden = false}) {
  final rarity = forceGolden ? Rarity.golden : odds.roll(random);
  final pool = album.where((c) => c.rarity == rarity).toList();
  final missing = pool.where((c) => !owned.contains(c.id)).toList();
  final critter = (missing.isNotEmpty ? missing : pool)[random.nextInt((missing.isNotEmpty ? missing : pool).length)];
  final duplicate = owned.contains(critter.id);
  String? completed;
  if (!duplicate) {
    final after = {...owned, critter.id};
    if (album.where((c) => c.set == critter.set).every((c) => after.contains(c.id))) completed = critter.set;
  }
  return CapsuleResult(critter, duplicate: duplicate, completedSet: completed);
}
