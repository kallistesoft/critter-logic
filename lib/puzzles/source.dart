import 'nests/nests.dart';
import 'nests/solver.dart';
import 'pairs/pairs.dart';
import 'pairs/solver.dart';
import 'trail/trail.dart';

/// Where puzzles come from: the bundled dailies (the same for everyone) and the endless level tracks.
abstract class PuzzleSource {
  Future<NestsPuzzle> dailyNests(int number);
  Future<PairsPuzzle> dailyPairs(int number);

  /// Level [level] (1-based) of each track; the same puzzle for a given level on every device.
  Future<NestsPuzzle> levelNests(int level);
  Future<PairsPuzzle> levelPairs(int level);
}

/// Where Trail puzzles come from. Separate from [PuzzleSource] until Trail joins [GameKind] (so fakes of
/// [PuzzleSource] keep compiling); [BundledPuzzleSource] implements both.
abstract class TrailSource {
  Future<TrailPuzzle> dailyTrail(int number);

  /// Level [level] (1-based) of the Trail track.
  Future<TrailPuzzle> levelTrail(int level);
}

/// One step the player can take: put [value] in [cell]. [wrong] means the cell currently holds something that
/// isn't in the solution and the step clears it.
class Hint<T> {
  const Hint(this.cell, this.value, {this.wrong = false, this.rule = ''});

  final int cell;
  final T value;
  final bool wrong;

  /// Why, for the UI to explain: 'wrong', a solver rule id (see nestsRuleLevels / pairsRuleLevels) or 'reveal'.
  final String rule;
}

/// The next logical step for the player: fix a wrong mark first, else the simplest deduction (see
/// [nestsDeductionHint]).
Hint<NestMark>? nestsHint(NestsPuzzle puzzle, List<NestMark> marks) => nestsDeductionHint(puzzle, marks);

/// The next logical step for the player: fix a wrong symbol first, else the simplest deduction (see
/// [pairsDeductionHint]).
Hint<int?>? pairsHint(PairsPuzzle puzzle, List<int?> cells) => pairsDeductionHint(puzzle, cells);
