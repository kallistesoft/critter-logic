import 'nests/nests.dart';
import 'pairs/pairs.dart';

/// Where puzzles come from: the bundled dailies (the same for everyone) and the endless level tracks.
abstract class PuzzleSource {
  Future<NestsPuzzle> dailyNests(int number);
  Future<PairsPuzzle> dailyPairs(int number);

  /// Level [level] (1-based) of each track; the same puzzle for a given level on every device.
  Future<NestsPuzzle> levelNests(int level);
  Future<PairsPuzzle> levelPairs(int level);
}

/// One step the player can take: put [value] in [cell]. [wrong] means the cell currently holds something that
/// isn't in the solution and the step clears it.
class Hint<T> {
  const Hint(this.cell, this.value, {this.wrong = false});

  final int cell;
  final T value;
  final bool wrong;
}

/// The simplest useful hint: first remove a misplaced critter, else reveal the critter of the first row without one.
Hint<NestMark>? nestsHint(NestsPuzzle puzzle, List<NestMark> marks) {
  for (var i = 0; i < marks.length; i++) {
    if (marks[i] == NestMark.critter && !puzzle.isCritterInSolution(i)) return Hint(i, NestMark.empty, wrong: true);
  }
  for (var r = 0; r < puzzle.size; r++) {
    final cell = r * puzzle.size + puzzle.solution[r];
    if (marks[cell] != NestMark.critter) return Hint(cell, NestMark.critter);
  }
  return null;
}

/// First fix a wrong symbol, else fill the first empty cell.
Hint<int?>? pairsHint(PairsPuzzle puzzle, List<int?> cells) {
  for (var i = 0; i < cells.length; i++) {
    if (cells[i] != null && cells[i] != puzzle.solution[i]) return Hint(i, puzzle.solution[i], wrong: true);
  }
  for (var i = 0; i < cells.length; i++) {
    if (cells[i] == null) return Hint(i, puzzle.solution[i]);
  }
  return null;
}
