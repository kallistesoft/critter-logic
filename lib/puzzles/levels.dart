import '../daily.dart';
import 'difficulty.dart';
import 'nests/generator.dart';
import 'nests/nests.dart';
import 'pairs/generator.dart';
import 'pairs/pairs.dart';
import 'puzzle.dart';

/// Size and tier of one puzzle.
class PuzzleSpec {
  const PuzzleSpec(this.size, this.tier);

  final int size;
  final Tier tier;

  @override
  bool operator ==(Object other) => other is PuzzleSpec && other.size == size && other.tier == tier;

  @override
  int get hashCode => Object.hash(size, tier);

  @override
  String toString() => '$size ${tier.name}';
}

const _e = Tier.easy, _m = Tier.medium, _h = Tier.hard;

/// Every 7th level from 14 on is a breather: one size smaller and easy.
bool isBreatherLevel(int level) => level >= 14 && level % 7 == 0;

/// Nests track: 5×5 easy at first, 9×9 hard from level 60.
PuzzleSpec nestsLevelSpec(int level) {
  final spec = switch (level) {
    <= 3 => const PuzzleSpec(5, _e),
    <= 6 => const PuzzleSpec(6, _e),
    <= 10 => const PuzzleSpec(6, _m),
    <= 14 => const PuzzleSpec(7, _e),
    <= 20 => const PuzzleSpec(7, _m),
    <= 26 => PuzzleSpec(level.isEven ? 7 : 8, level.isEven ? _h : _e),
    <= 34 => const PuzzleSpec(8, _m),
    <= 42 => PuzzleSpec(8, level.isEven ? _h : _m),
    <= 50 => PuzzleSpec(level % 3 == 0 ? 9 : 8, level % 3 == 0 ? _m : _h),
    < 60 => PuzzleSpec(9, level.isEven ? _h : _m),
    _ => PuzzleSpec(level % 4 == 1 ? 8 : 9, level % 4 == 3 ? _m : _h),
  };
  return isBreatherLevel(level) ? PuzzleSpec((spec.size - 1).clamp(5, 9), _e) : spec;
}

/// Pairs track: 6×6 easy at first, 8×8 hard from level 60.
PuzzleSpec pairsLevelSpec(int level) {
  final spec = switch (level) {
    <= 6 => const PuzzleSpec(6, _e),
    <= 12 => const PuzzleSpec(6, _m),
    <= 20 => PuzzleSpec(6, level.isEven ? _h : _m),
    <= 26 => const PuzzleSpec(8, _e),
    <= 34 => const PuzzleSpec(8, _m),
    <= 46 => PuzzleSpec(level % 3 == 0 ? 6 : 8, level % 3 == 0 ? _h : _m),
    < 60 => PuzzleSpec(8, level.isEven ? _h : _m),
    _ => PuzzleSpec(8, level % 4 == 3 ? _m : _h),
  };
  return isBreatherLevel(level) ? const PuzzleSpec(6, _e) : spec;
}

/// Daily difficulty by weekday of the daily's date, Monday easiest to Sunday hardest.
PuzzleSpec nestsDailySpec(int number) => const [
      PuzzleSpec(6, _e), // Monday
      PuzzleSpec(6, _m),
      PuzzleSpec(7, _e),
      PuzzleSpec(7, _m),
      PuzzleSpec(7, _h),
      PuzzleSpec(8, _m),
      PuzzleSpec(8, _h), // Sunday
    ][dateOfDaily(number).weekday - 1];

PuzzleSpec pairsDailySpec(int number) => const [
      PuzzleSpec(6, _e), // Monday
      PuzzleSpec(6, _m),
      PuzzleSpec(6, _m),
      PuzzleSpec(6, _h),
      PuzzleSpec(8, _e),
      PuzzleSpec(8, _m),
      PuzzleSpec(8, _h), // Sunday
    ][dateOfDaily(number).weekday - 1];

/// Stable seed of a puzzle; never uses enum indices or String.hashCode, so it can't drift between app versions.
int puzzleSeed(GameKind game, {required bool daily, required int number}) =>
    mixSeed([game == GameKind.nests ? 1 : 2, daily ? 2 : 1, number]);

NestsPuzzle generateNestsLevel(int level) {
  final spec = nestsLevelSpec(level);
  return NestsGenerator(puzzleSeed(GameKind.nests, daily: false, number: level)).generate(spec.size, spec.tier);
}

PairsPuzzle generatePairsLevel(int level) {
  final spec = pairsLevelSpec(level);
  return PairsGenerator(puzzleSeed(GameKind.pairs, daily: false, number: level)).generate(spec.size, spec.tier);
}

NestsPuzzle generateNestsDaily(int number) {
  final spec = nestsDailySpec(number);
  return NestsGenerator(puzzleSeed(GameKind.nests, daily: true, number: number)).generate(spec.size, spec.tier);
}

PairsPuzzle generatePairsDaily(int number) {
  final spec = pairsDailySpec(number);
  return PairsGenerator(puzzleSeed(GameKind.pairs, daily: true, number: number)).generate(spec.size, spec.tier);
}
