import 'dart:math';

import '../daily.dart';
import 'difficulty.dart';
import 'effort.dart';
import 'nests/generator.dart';
import 'nests/nests.dart';
import 'pairs/generator.dart';
import 'pairs/pairs.dart';
import 'puzzle.dart';
import 'trail/generator.dart';
import 'trail/trail.dart';

/// Size and tier of one puzzle.
class PuzzleSpec {
  const PuzzleSpec(this.size, this.tier, {this.givens = 0});

  final int size;
  final Tier tier;

  /// Pairs only: the least share of cells given at the start (more = fewer cells to work out).
  final double givens;

  @override
  bool operator ==(Object other) =>
      other is PuzzleSpec && other.size == size && other.tier == tier && other.givens == givens;

  @override
  int get hashCode => Object.hash(size, tier, givens);

  @override
  String toString() => '$size ${tier.name}${givens > 0 ? ' ${(givens * 100).round()}%' : ''}';
}

const _e = Tier.easy, _m = Tier.medium, _h = Tier.hard;

/// Every 7th level from 17 on (17, 24, 31…) is a breather: a clearly easier puzzle, never on a step-up level (11,
/// 21, 41).
bool isBreatherLevel(int level) => level >= 17 && (level - 3) % 7 == 0;

// Level ramps. Each spec's target effort (see the tables at the end) is noted after it; levels 1-10 are quick
// wins, the step-ups at 11, 21 and 41 are about a third harder than the levels before, and in between the specs
// alternate so the rolling average climbs smoothly. tools/difficulty_report.dart prints the resulting curves.

/// Nests track: 5×5 easy at first, 9×9 hard from level 60.
PuzzleSpec nestsLevelSpec(int level) {
  if (isBreatherLevel(level)) return PuzzleSpec(level < 30 ? 6 : (level < 60 ? 8 : 9), _e);
  return switch (level) {
    <= 5 => const PuzzleSpec(5, _e), // 6.7
    <= 10 => const PuzzleSpec(6, _e), // 9
    <= 15 => const PuzzleSpec(7, _e), // 11.7
    <= 20 => PuzzleSpec(level.isEven ? 8 : 5, level.isEven ? _e : _m), // 14.7, 14.2
    <= 27 => level.isEven ? const PuzzleSpec(8, _e) : const PuzzleSpec(6, _m), // 14.7, 18
    <= 34 => level.isEven ? const PuzzleSpec(7, _m) : const PuzzleSpec(6, _m), // 22.2, 18
    <= 40 => const [PuzzleSpec(7, _m), PuzzleSpec(6, _h), PuzzleSpec(8, _m)][level % 3], // 22.2, 28, 30.7
    <= 50 => level.isEven ? const PuzzleSpec(8, _m) : const PuzzleSpec(7, _h), // 30.7, 32.7
    < 60 => const [PuzzleSpec(9, _m), PuzzleSpec(7, _h), PuzzleSpec(8, _h)][level % 3], // 40.5, 32.7, 46.7
    _ => const [PuzzleSpec(9, _m), PuzzleSpec(8, _h), PuzzleSpec(9, _m), PuzzleSpec(9, _h)][level % 4], // 40.5…52
  };
}

/// Pairs track: 6×6 easy with many givens at first, 8×8 hard from level 60.
PuzzleSpec pairsLevelSpec(int level) {
  if (isBreatherLevel(level)) return PuzzleSpec(6, _e, givens: level < 40 ? 0.4 : 0);
  return switch (level) {
    <= 4 => const PuzzleSpec(6, _e, givens: 0.5), // 18
    <= 7 => const PuzzleSpec(6, _e, givens: 0.4), // 22
    <= 10 => const PuzzleSpec(6, _e, givens: 0.3), // 25
    <= 15 => level.isEven ? const PuzzleSpec(6, _m, givens: 0.3) : const PuzzleSpec(6, _e), // 29, 30
    <= 20 => level.isEven ? const PuzzleSpec(6, _m) : const PuzzleSpec(6, _e), // 35, 30
    <= 30 => level.isEven ? const PuzzleSpec(6, _m) : const PuzzleSpec(6, _h), // 35, 41
    <= 40 => const [PuzzleSpec(6, _h), PuzzleSpec(8, _e, givens: 0.5), PuzzleSpec(8, _e, givens: 0.4)][level % 3],
    <= 50 => level.isEven ? const PuzzleSpec(8, _e, givens: 0.3) : const PuzzleSpec(8, _m, givens: 0.4), // 60, 56
    < 60 => level.isEven ? const PuzzleSpec(8, _e) : const PuzzleSpec(8, _m, givens: 0.3), // 69, 65
    _ => const [PuzzleSpec(8, _m), PuzzleSpec(8, _h, givens: 0.3), PuzzleSpec(8, _m), PuzzleSpec(8, _h)][level % 4],
  };
}

/// Trail track (its own, not a [GameKind] yet): 5×5 easy at first, 8×8 hard from level 60.
PuzzleSpec trailLevelSpec(int level) {
  if (isBreatherLevel(level)) {
    return switch (level) {
      < 24 => const PuzzleSpec(5, _e),
      < 45 => const PuzzleSpec(6, _e),
      < 60 => const PuzzleSpec(7, _e),
      _ => const PuzzleSpec(7, _m), // Well below the 8×8 hard around it; an easy one would drop too far.
    };
  }
  return switch (level) {
    <= 5 => const PuzzleSpec(5, _e), // 6.9
    <= 10 => PuzzleSpec(level.isOdd ? 6 : 5, _e), // 9.7, 6.9
    <= 15 => level.isEven ? const PuzzleSpec(6, _e) : const PuzzleSpec(5, _m), // 9.7, 10.4
    <= 20 => level.isEven ? const PuzzleSpec(7, _e) : const PuzzleSpec(6, _m), // 13.6, 14
    <= 30 => const [PuzzleSpec(6, _m), PuzzleSpec(8, _e), PuzzleSpec(7, _m)][level % 3], // 14, 17.5, 20.5
    <= 40 => level.isEven ? const PuzzleSpec(7, _m) : const PuzzleSpec(6, _h), // 20.5, 21.9
    <= 50 => const [PuzzleSpec(6, _h), PuzzleSpec(8, _m), PuzzleSpec(7, _m)][level % 3], // 21.9, 25, 20.5
    < 60 => level.isEven ? const PuzzleSpec(8, _m) : const PuzzleSpec(7, _h), // 25, 30
    _ => const [PuzzleSpec(8, _m), PuzzleSpec(7, _h), PuzzleSpec(8, _h), PuzzleSpec(7, _h)][level % 4], // 25…38
  };
}

/// Daily difficulty by weekday of the daily's date, Monday easiest to Sunday hardest.
PuzzleSpec nestsDailySpec(int number) => const [
  PuzzleSpec(6, _e), // Monday 9
  PuzzleSpec(7, _e), // 11.7
  PuzzleSpec(8, _e), // 14.7
  PuzzleSpec(6, _m), // 18
  PuzzleSpec(7, _m), // 22.2
  PuzzleSpec(8, _m), // 30.7
  PuzzleSpec(8, _h), // Sunday 46.7
][dateOfDaily(number).weekday - 1];

PuzzleSpec pairsDailySpec(int number) => const [
  PuzzleSpec(6, _e), // Monday 30
  PuzzleSpec(6, _m), // 35
  PuzzleSpec(6, _h), // 41
  PuzzleSpec(8, _e, givens: 0.4), // 50.7
  PuzzleSpec(8, _m, givens: 0.3), // 65.3
  PuzzleSpec(8, _m), // 77.3
  PuzzleSpec(8, _h), // Sunday 94.7
][dateOfDaily(number).weekday - 1];

PuzzleSpec trailDailySpec(int number) => const [
  PuzzleSpec(6, _e), // Monday 9.7
  PuzzleSpec(7, _e), // 13.6
  PuzzleSpec(6, _m), // 14
  PuzzleSpec(7, _m), // 20.5
  PuzzleSpec(6, _h), // 21.9
  PuzzleSpec(8, _m), // 25
  PuzzleSpec(7, _h), // Sunday 30
][dateOfDaily(number).weekday - 1];

/// Stable seed of a puzzle; never uses enum indices or String.hashCode, so it can't drift between app versions.
int puzzleSeed(GameKind game, {required bool daily, required int number}) =>
    mixSeed([game == GameKind.nests ? 1 : 2, daily ? 2 : 1, number]);

/// Stable seed of a Trail puzzle (game id 3; Nests and Pairs are 1 and 2 in [puzzleSeed]).
int trailSeed({required bool daily, required int number}) => mixSeed([3, daily ? 2 : 1, number]);

NestsPuzzle generateNestsLevel(int level) =>
    _nests(nestsLevelSpec(level), puzzleSeed(GameKind.nests, daily: false, number: level));

PairsPuzzle generatePairsLevel(int level) =>
    _pairs(pairsLevelSpec(level), puzzleSeed(GameKind.pairs, daily: false, number: level));

TrailPuzzle generateTrailLevel(int level) => _trail(trailLevelSpec(level), trailSeed(daily: false, number: level));

NestsPuzzle generateNestsDaily(int number) =>
    _nests(nestsDailySpec(number), puzzleSeed(GameKind.nests, daily: true, number: number));

PairsPuzzle generatePairsDaily(int number) =>
    _pairs(pairsDailySpec(number), puzzleSeed(GameKind.pairs, daily: true, number: number));

TrailPuzzle generateTrailDaily(int number) => _trail(trailDailySpec(number), trailSeed(daily: true, number: number));

NestsPuzzle _nests(PuzzleSpec spec, int seed) =>
    _closest(spec, targetNestsEffort, seed, (s) => NestsGenerator(s).generate(spec.size, spec.tier), nestsEffort);

PairsPuzzle _pairs(PuzzleSpec spec, int seed) => _closest(
  spec,
  targetPairsEffort,
  seed,
  (s) => PairsGenerator(s).generate(spec.size, spec.tier, minGivens: (spec.givens * spec.size * spec.size).round()),
  pairsEffort,
);

TrailPuzzle _trail(PuzzleSpec spec, int seed) =>
    _closest(spec, targetTrailEffort, seed, (s) => TrailGenerator(s).generate(spec.size, spec.tier), trailEffort);

/// How far a puzzle's effort may stray above and below its spec's target effort before the next seed is tried
/// (tighter above: spikes hurt more than breezes).
const effortAbove = 1.08, effortBelow = 1.15;

/// Generates with [seed], then with derived seeds, until the effort is within [effortAbove] / [effortBelow] of the
/// spec's target effort (so no puzzle is a lucky breeze or a sudden wall); keeps the closest after 10 tries.
P _closest<P>(
  PuzzleSpec spec,
  Map<String, double> targets,
  int seed,
  P Function(int seed) generate,
  Effort Function(P) effort,
) {
  final target = targets['$spec'];
  P? best;
  var bestDistance = double.infinity;
  for (var k = 0; k < 10; k++) {
    final p = generate(k == 0 ? seed : mixSeed([seed, k]));
    if (target == null) return p;
    final ratio = effort(p).score / target;
    if (ratio <= effortAbove && ratio >= 1 / effortBelow) return p;
    final distance = log(ratio).abs();
    if (distance < bestDistance) {
      best = p;
      bestDistance = distance;
    }
  }
  return best as P;
}

// Target effort of each spec: picked inside the spec's usual range (between its 10th and 90th percentile over 80
// seeds, which dart run tools/difficulty_report.dart --typical prints) so the ramps climb smoothly. A spec missing
// here is generated with no effort check.

const targetNestsEffort = {
  '5 easy': 6.7, '5 medium': 14.2, '5 hard': 24.2, //
  '6 easy': 9.0, '6 medium': 18.0, '6 hard': 28.0, //
  '7 easy': 11.7, '7 medium': 22.2, '7 hard': 32.7, //
  '8 easy': 14.7, '8 medium': 30.7, '8 hard': 46.7, //
  '9 easy': 22.5, '9 medium': 40.5, '9 hard': 52.0, //
};

const targetPairsEffort = {
  '6 easy': 30.0, '6 easy 30%': 25.0, '6 easy 40%': 22.0, '6 easy 50%': 18.0, //
  '6 medium': 35.0, '6 medium 30%': 27.0, '6 medium 40%': 24.0, //
  '6 hard': 41.0, '6 hard 30%': 33.0, //
  '8 easy': 69.3, '8 easy 30%': 60.0, '8 easy 40%': 50.7, '8 easy 50%': 42.7, //
  '8 medium': 77.3, '8 medium 30%': 65.3, '8 medium 40%': 56.0, //
  '8 hard': 94.7, '8 hard 30%': 76.0, '8 hard 40%': 61.3, //
};

const targetTrailEffort = {
  '5 easy': 6.9, '5 medium': 10.4, '5 hard': 13.9, //
  '6 easy': 9.7, '6 medium': 14.0, '6 hard': 21.9, //
  '7 easy': 13.6, '7 medium': 20.5, '7 hard': 30.0, //
  '8 easy': 17.5, '8 medium': 25.0, '8 hard': 38.0, //
};
