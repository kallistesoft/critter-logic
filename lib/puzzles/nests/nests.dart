import '../puzzle.dart';

/// Nests: place one critter in every row, every column and every color zone; no two critters touch,
/// not even diagonally.
class NestsPuzzle {
  NestsPuzzle({required this.size, required this.regions, required this.solution})
      : assert(regions.length == size * size),
        assert(solution.length == size);

  final int size;

  /// Zone id (0 until size-1) of each cell, row-major.
  final List<int> regions;

  /// The column of the critter in each row.
  final List<int> solution;

  bool isCritterInSolution(int cell) => solution[cell ~/ size] == cell % size;

  Map<String, dynamic> toJson() => {'s': size, 'r': regions.join(), 'x': solution.join()};

  /// Compact form: zones and solution as digit strings (sizes up to 10).
  static NestsPuzzle fromJson(Map<String, dynamic> json) {
    final size = json['s'] as int;
    return NestsPuzzle(
      size: size,
      regions: [for (final c in (json['r'] as String).split('')) int.parse(c)],
      solution: [for (final c in (json['x'] as String).split('')) int.parse(c)],
    );
  }
}

/// What the player put in a cell. [cross] is the player's own "no critter here" note; it never counts as wrong.
enum NestMark { empty, cross, critter }

class NestsRules {
  const NestsRules(this.puzzle);

  final NestsPuzzle puzzle;

  /// Critters that break a rule (same row, column or zone, or touching another critter).
  Set<int> conflicts(List<NestMark> marks) {
    final n = puzzle.size;
    final critters = [for (var i = 0; i < marks.length; i++) if (marks[i] == NestMark.critter) i];
    final bad = <int>{};
    for (var a = 0; a < critters.length; a++) {
      for (var b = a + 1; b < critters.length; b++) {
        final i = critters[a], j = critters[b];
        final ri = i ~/ n, ci = i % n, rj = j ~/ n, cj = j % n;
        final clash = ri == rj ||
            ci == cj ||
            puzzle.regions[i] == puzzle.regions[j] ||
            ((ri - rj).abs() <= 1 && (ci - cj).abs() <= 1);
        if (clash) bad.addAll([i, j]);
      }
    }
    return bad;
  }

  /// Solved: one critter per row with no conflict (rows × no conflicts implies columns and zones too).
  bool isSolved(List<NestMark> marks) {
    final count = marks.where((m) => m == NestMark.critter).length;
    return count == puzzle.size && conflicts(marks).isEmpty;
  }

  /// Every cell that must be empty, for the "show crosses" assist and hints.
  List<int> solutionCells() => [for (var r = 0; r < puzzle.size; r++) cellIndex(puzzle.size, r, puzzle.solution[r])];
}
