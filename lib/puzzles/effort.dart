import 'difficulty.dart';
import 'nests/generator.dart';
import 'nests/nests.dart';
import 'nests/solver.dart';
import 'pairs/generator.dart';
import 'pairs/pairs.dart';
import 'pairs/solver.dart';
import 'trail/generator.dart';
import 'trail/trail.dart';

/// Estimated human effort of a puzzle, for tuning the level ramps and the weekly daily curve (see
/// tools/difficulty_report.dart). Unitless, and only comparable within one game: Nests and Trail start around 7,
/// Pairs (one step per cell) around 18.
///
/// Nests and Pairs: every deduction step the solver takes, weighted by how hard its rule is to spot, times the grid
/// side over 6 (spotting a step takes longer on a bigger board). Trail: the cells to draw, stretched by long gaps
/// between stones and by the solver's guessing.
class Effort {
  const Effort({required this.size, required this.tier, required this.steps, required this.rules, required this.score});

  final int size;

  /// The tier the solver's run counts as (not the requested one).
  final Tier tier;
  final int steps;
  final Map<String, int> rules;
  final double score;

  @override
  String toString() => 'Effort($size, ${tier.name}, steps: $steps, rules: $rules, score: ${score.toStringAsFixed(1)})';
}

/// Weight of one step of each rule level: a level 2 step is worth 3 simple ones, and so on.
const _levelWeight = [0.0, 1.0, 3.0, 6.0, 10.0];

double _weighted(Map<String, int> rules, Map<String, int> levels) {
  var sum = 0.0;
  rules.forEach((rule, uses) => sum += uses * _levelWeight[levels[rule]!]);
  return sum;
}

Effort nestsEffort(NestsPuzzle p) {
  final r = NestsSolver(p.size, p.regions).solve();
  return Effort(
    size: p.size,
    tier: nestsTierOf(r),
    steps: r.steps,
    rules: r.rules,
    score: _weighted(r.rules, nestsRuleLevels) * p.size / 6,
  );
}

Effort pairsEffort(PairsPuzzle p) {
  final r = PairsSolver(p.size, p.givens, p.links).solve();
  return Effort(
    size: p.size,
    tier: pairsTierOf(r),
    steps: r.steps,
    rules: r.rules,
    score: _weighted(r.rules, pairsRuleLevels) * p.size / 6,
  );
}

Effort trailEffort(TrailPuzzle p) {
  final e = trailEffortOf(p);
  return Effort(
    size: p.size,
    tier: trailTierOf(e),
    steps: p.cellCount,
    rules: {...e.result.rules, 'guess': e.result.guesses},
    // A 6×6 easy (gap 4, no guess) scores about 10, like a first Pairs or Nests.
    score: p.cellCount * e.hardness / 14.4,
  );
}
