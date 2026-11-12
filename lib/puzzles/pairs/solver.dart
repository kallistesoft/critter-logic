import '../difficulty.dart';
import '../puzzle.dart';
import '../source.dart';
import 'pairs.dart';

/// Rule levels of the Pairs deduction solver, simplest first:
/// 1. 'three': two equal symbols side by side, or with one gap between them, rule that symbol out next to them.
///    'link': a cell linked to a filled one by = or ×.
///    'count': a row or column that already holds half of one symbol gets the other symbol everywhere else.
/// 2. 'line': in one row or column, every way to finish it (half of each, no three in a row, its own links)
///    puts the same symbol in this cell, e.g. a sun here would force three moons elsewhere.
///
/// The "no two identical rows" rule of some similar games is not a rule here, so the solver never uses it.
const pairsRuleLevels = {'three': 1, 'link': 1, 'count': 1, 'line': 2};

/// One deduction: put [value] in [cell].
class PairsStep {
  const PairsStep(this.rule, this.cell, this.value);

  final String rule;
  final int cell;
  final int value;

  int get level => pairsRuleLevels[rule]!;
}

/// A Pairs grid seen by the solver: the symbols known so far and the links.
class PairsBoard {
  PairsBoard(this.size, List<int?> start, this.links)
      : cells = List.of(start),
        lines = _lines(size),
        _lineLinks = _linksPerLine(size, links);

  final int size;
  final List<int?> cells;
  final List<PairsLink> links;

  /// Cell indices of the rows, then the columns.
  final List<List<int>> lines;

  /// For each line, its links as (position, position, same).
  final List<List<(int, int, bool)>> _lineLinks;

  static List<List<int>> _lines(int n) => [
        for (var r = 0; r < n; r++) [for (var k = 0; k < n; k++) cellIndex(n, r, k)],
        for (var c = 0; c < n; c++) [for (var k = 0; k < n; k++) cellIndex(n, k, c)],
      ];

  static List<List<(int, int, bool)>> _linksPerLine(int n, List<PairsLink> links) {
    final out = List.generate(2 * n, (_) => <(int, int, bool)>[]);
    for (final l in links) {
      final ra = l.a ~/ n, ca = l.a % n, rb = l.b ~/ n, cb = l.b % n;
      if (ra == rb) out[ra].add((ca, cb, l.same));
      if (ca == cb) out[n + ca].add((ra, rb, l.same));
    }
    return out;
  }

  bool get complete => !cells.contains(null);

  /// The simplest deduction available up to [maxLevel], or null when stuck.
  PairsStep? nextStep({int maxLevel = 2}) {
    final n = size;
    for (final line in lines) {
      for (var k = 0; k + 2 < n; k++) {
        final a = cells[line[k]], b = cells[line[k + 1]], c = cells[line[k + 2]];
        if (a != null && a == b && c == null) return PairsStep('three', line[k + 2], 1 - a);
        if (b != null && b == c && a == null) return PairsStep('three', line[k], 1 - b);
        if (a != null && a == c && b == null) return PairsStep('three', line[k + 1], 1 - a);
      }
    }
    for (final l in links) {
      final a = cells[l.a], b = cells[l.b];
      if (a != null && b == null) return PairsStep('link', l.b, l.same ? a : 1 - a);
      if (b != null && a == null) return PairsStep('link', l.a, l.same ? b : 1 - b);
    }
    for (final line in lines) {
      var suns = 0, moons = 0, empty = -1;
      for (final i in line) {
        final v = cells[i];
        if (v == sun) suns++;
        if (v == moon) moons++;
        if (v == null && empty < 0) empty = i;
      }
      if (empty < 0) continue;
      if (suns == n ~/ 2) return PairsStep('count', empty, moon);
      if (moons == n ~/ 2) return PairsStep('count', empty, sun);
    }
    if (maxLevel < 2) return null;
    for (var li = 0; li < lines.length; li++) {
      final line = lines[li];
      if (!line.any((i) => cells[i] == null)) continue;
      var all = -1, any = 0, count = 0;
      for (final p in validLines(n)) {
        if (!_fits(line, _lineLinks[li], p)) continue;
        all &= p;
        any |= p;
        count++;
      }
      if (count == 0) return null;
      for (var k = 0; k < n; k++) {
        if (cells[line[k]] != null) continue;
        if (all & 1 << k != 0) return PairsStep('line', line[k], moon);
        if (any & 1 << k == 0) return PairsStep('line', line[k], sun);
      }
    }
    return null;
  }

  bool _fits(List<int> line, List<(int, int, bool)> lineLinks, int pattern) {
    for (var k = 0; k < line.length; k++) {
      final v = cells[line[k]];
      if (v != null && (pattern >> k & 1) != v) return false;
    }
    for (final (a, b, same) in lineLinks) {
      if (((pattern >> a & 1) == (pattern >> b & 1)) != same) return false;
    }
    return true;
  }

  static final _valid = <int, List<int>>{};

  /// Every full line of [n] cells as a bit pattern (bit k = moon at k): half of each symbol, no three in a row.
  static List<int> validLines(int n) => _valid.putIfAbsent(n, () {
        return [
          for (var p = 0; p < 1 << n; p++)
            if (popCount(p) == n ~/ 2 && !_hasThree(p, n)) p,
        ];
      });

  static bool _hasThree(int p, int n) {
    for (var k = 0; k + 2 < n; k++) {
      final w = p >> k & 7;
      if (w == 0 || w == 7) return true;
    }
    return false;
  }
}

/// Solves a Pairs puzzle with human rules only (no guessing) up to rule [maxLevel].
class PairsSolver {
  PairsSolver(this.size, this.givens, this.links, {this.maxLevel = 2});

  final int size;
  final List<int?> givens;
  final List<PairsLink> links;
  final int maxLevel;

  /// The filled grid, set once [solve] succeeds.
  List<int>? solution;

  SolveResult solve() {
    final board = PairsBoard(size, givens, links);
    final rules = <String, int>{};
    var steps = 0, top = 0;
    while (!board.complete) {
      final step = board.nextStep(maxLevel: maxLevel);
      if (step == null) break;
      board.cells[step.cell] = step.value;
      steps++;
      rules[step.rule] = (rules[step.rule] ?? 0) + 1;
      if (step.level > top) top = step.level;
    }
    if (board.complete) solution = board.cells.cast<int>();
    return SolveResult(solved: board.complete, steps: steps, maxLevel: top, rules: rules);
  }
}

/// The next logical step for the player, with the rule behind it.
///
/// A wrong symbol comes first (the hint gives the right one). Otherwise the simplest deduction from the player's
/// symbols and the givens.
Hint<int?>? pairsDeductionHint(PairsPuzzle puzzle, List<int?> cells) {
  for (var i = 0; i < cells.length; i++) {
    if (cells[i] != null && cells[i] != puzzle.solution[i]) return Hint(i, puzzle.solution[i], wrong: true, rule: 'wrong');
  }
  final board = PairsBoard(puzzle.size, [for (var i = 0; i < cells.length; i++) cells[i] ?? puzzle.givens[i]], puzzle.links);
  if (board.complete) return null;
  final step = board.nextStep();
  if (step == null) {
    // Not reachable for a puzzle the solver solves; reveal rather than leave the player stuck.
    final i = board.cells.indexOf(null);
    return Hint(i, puzzle.solution[i], rule: 'reveal');
  }
  return Hint(step.cell, step.value, rule: step.rule);
}
