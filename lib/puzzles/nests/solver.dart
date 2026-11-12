import '../difficulty.dart';
import '../source.dart';
import 'nests.dart';

/// Rule levels of the Nests deduction solver, simplest first:
/// 1. 'zone' / 'row' / 'col': the only cell left for a critter in that zone, row or column.
/// 2. 'confine': a zone whose cells left sit in one row or column rules out the rest of that line, and a line whose
///    cells left sit in one zone rules out the rest of that zone.
/// 3. 'block': a critter here would leave some zone, row or column with no cell at all.
/// 4. 'group': k zones (or lines) whose cells left sit in k lines (or zones) rule out the rest of those.
///
/// Cells in a row, column or zone that already holds a critter, or touching one, are ruled out as soon as the critter
/// is placed ('row', 'col', 'zone', 'touch'); that is not counted as a step.
const nestsRuleLevels = {'zone': 1, 'row': 1, 'col': 1, 'confine': 2, 'block': 3, 'group': 4};

/// One deduction: put a critter in [cells].first when [place], else rule out every cell of [cells].
class NestsStep {
  const NestsStep(this.rule, this.cells, {this.place = false});

  final String rule;
  final List<int> cells;
  final bool place;

  int get level => nestsRuleLevels[rule]!;
}

/// A board seen by the solver: which cells may still hold a critter, and the critters placed so far.
///
/// Units are numbered rows 0..n-1, columns n..2n-1, zones 2n..3n-1.
class NestsBoard {
  NestsBoard(this.size, this.regions)
      : candidates = List.filled(size * size, true),
        done = List.filled(3 * size, false),
        critters = [],
        unitCells = _units(size, regions);

  final int size;
  final List<int> regions;
  final List<bool> candidates;

  /// Units that already hold their critter.
  final List<bool> done;
  final List<int> critters;
  final List<List<int>> unitCells;

  static List<List<int>> _units(int n, List<int> regions) {
    final units = List.generate(3 * n, (_) => <int>[]);
    for (var i = 0; i < n * n; i++) {
      units[i ~/ n].add(i);
      units[n + i % n].add(i);
      units[2 * n + regions[i]].add(i);
    }
    return units;
  }

  bool get complete => critters.length == size;

  int rowOf(int cell) => cell ~/ size;
  int colOf(int cell) => cell % size;

  /// Row, column and zone unit of [cell].
  List<int> unitsOf(int cell) => [cell ~/ size, size + cell % size, 2 * size + regions[cell]];

  /// True when a critter in [a] rules out [b]: same row, column or zone, or touching.
  bool hits(int a, int b) {
    final ra = a ~/ size, ca = a % size, rb = b ~/ size, cb = b % size;
    return ra == rb || ca == cb || regions[a] == regions[b] || ((ra - rb).abs() <= 1 && (ca - cb).abs() <= 1);
  }

  /// Places a critter and rules out every cell it sees.
  void place(int cell) {
    critters.add(cell);
    for (final u in unitsOf(cell)) {
      done[u] = true;
    }
    for (var i = 0; i < candidates.length; i++) {
      if (candidates[i] && i != cell && hits(cell, i)) candidates[i] = false;
    }
    candidates[cell] = false;
  }

  void apply(NestsStep step) {
    if (step.place) {
      place(step.cells.first);
    } else {
      for (final c in step.cells) {
        candidates[c] = false;
      }
    }
  }

  List<List<int>> _unitCandidates() => [
        for (final cells in unitCells) [for (final c in cells) if (candidates[c]) c],
      ];

  /// The simplest deduction available up to [maxLevel], or null when stuck (or the board is contradictory).
  NestsStep? nextStep({int maxLevel = 4}) {
    final n = size;
    final uc = _unitCandidates();
    for (var u = 0; u < 3 * n; u++) {
      if (!done[u] && uc[u].isEmpty) return null;
    }
    // Zones first: that is how players read the board.
    for (final u in [for (var z = 0; z < n; z++) 2 * n + z, for (var u = 0; u < 2 * n; u++) u]) {
      if (!done[u] && uc[u].length == 1) {
        return NestsStep(u < n ? 'row' : (u < 2 * n ? 'col' : 'zone'), [uc[u].single], place: true);
      }
    }
    if (maxLevel < 2) return null;
    final confine = _confine(uc, 1, 1);
    if (confine != null) return confine;
    if (maxLevel < 3) return null;
    final block = _block(uc);
    if (block != null) return block;
    if (maxLevel < 4) return null;
    return _confine(uc, 2, n);
  }

  /// k units of one kind whose candidates lie within k units of another kind (k in [kMin]..[kMax]).
  NestsStep? _confine(List<List<int>> uc, int kMin, int kMax) {
    final n = size;
    int kindIndex(int kind, int c) => kind == 0 ? c ~/ n : (kind == 1 ? c % n : regions[c]);
    // (A kind, B kind) offsets: zones→rows, zones→cols, rows→zones, cols→zones, rows→cols, cols→rows.
    const pairs = [(2, 0), (2, 1), (0, 2), (1, 2), (0, 1), (1, 0)];
    for (final (a, b) in pairs) {
      if (kMax == 1 && a != 2 && b != 2) continue; // A row confined to one column is just a single.
      final active = [for (var i = 0; i < n; i++) if (!done[a * n + i]) i];
      final m = active.length;
      final masks = [
        for (final i in active) uc[a * n + i].fold<int>(0, (mask, c) => mask | 1 << kindIndex(b, c)),
      ];
      // Bit of each A unit inside the subsets below (0 when already done).
      final bitOf = List.filled(n, 0);
      for (var j = 0; j < m; j++) {
        bitOf[active[j]] = 1 << j;
      }
      final unions = List.filled(1 << m, 0);
      var best = 0, bestK = kMax + 1;
      for (var subset = 1; subset < 1 << m; subset++) {
        final low = subset & -subset;
        final union = unions[subset] = unions[subset ^ low] | masks[_bitIndex(low)];
        final k = _popCounts[subset];
        if (k < kMin || k >= bestK || k >= m || _popCounts[union] != k) continue;
        if (_eliminations(uc, a, b, subset, union, bitOf, kindIndex).isNotEmpty) {
          best = subset;
          bestK = k;
        }
      }
      if (best != 0) {
        final elim = _eliminations(uc, a, b, best, unions[best], bitOf, kindIndex)..sort();
        return NestsStep(bestK == 1 ? 'confine' : 'group', elim);
      }
    }
    return null;
  }

  /// Candidates of the B units in [union] that lie outside the A units in [subset].
  List<int> _eliminations(List<List<int>> uc, int a, int b, int subset, int union, List<int> bitOf,
      int Function(int kind, int cell) kindIndex) {
    final out = <int>[];
    for (var t = 0; t < size; t++) {
      if (union & 1 << t == 0) continue;
      for (final c in uc[b * size + t]) {
        if (subset & bitOf[kindIndex(a, c)] == 0) out.add(c);
      }
    }
    return out;
  }

  static int _bitIndex(int bit) {
    var i = 0;
    while (bit > 1) {
      bit >>= 1;
      i++;
    }
    return i;
  }

  static final _popCounts = [for (var i = 0; i < 1 << 10; i++) popCount(i)];

  /// Candidates that would leave another unit with no candidate at all.
  NestsStep? _block(List<List<int>> uc) {
    final n = size;
    final geometry = _geometry(n);
    final zoneRows = List.generate(n, (_) => List.filled(n, 0));
    for (var i = 0; i < n * n; i++) {
      zoneRows[regions[i]][i ~/ n] |= 1 << i % n;
    }
    final out = <int>{};
    final kill = List.filled(n, 0);
    for (var u = 0; u < 3 * n; u++) {
      if (done[u]) continue;
      // Cells that see every candidate of u.
      kill.fillRange(0, n, (1 << n) - 1);
      for (final d in uc[u]) {
        final geo = geometry[d], zone = zoneRows[regions[d]];
        for (var r = 0; r < n; r++) {
          kill[r] &= geo[r] | zone[r];
        }
      }
      for (var r = 0; r < n; r++) {
        for (var c = 0; kill[r] >> c != 0; c++) {
          final cell = r * n + c;
          if (kill[r] & 1 << c == 0 || !candidates[cell]) continue;
          final inside = u < n ? r == u : (u < 2 * n ? c == u - n : regions[cell] == u - 2 * n);
          if (!inside) out.add(cell);
        }
      }
    }
    return out.isEmpty ? null : NestsStep('block', out.toList()..sort());
  }

  static final _geometryCache = <int, List<List<int>>>{};

  /// For each cell, per row, the columns it sees by row, column or touching.
  static List<List<int>> _geometry(int n) => _geometryCache.putIfAbsent(n, () {
        return [
          for (var d = 0; d < n * n; d++)
            [
              for (var r = 0; r < n; r++)
                r == d ~/ n
                    ? (1 << n) - 1
                    : (1 << d % n) | ((r - d ~/ n).abs() == 1 ? (7 << d % n >> 1) & ((1 << n) - 1) : 0),
            ],
        ];
      });
}

/// Solves a Nests layout with human rules only (no guessing) up to rule [maxLevel].
class NestsSolver {
  NestsSolver(this.size, this.regions, {this.maxLevel = 4});

  final int size;
  final List<int> regions;
  final int maxLevel;

  /// The critter column of each row, set once [solve] succeeds.
  List<int>? solution;

  /// Where the last [solve] ended (stuck or complete).
  late NestsBoard board;

  SolveResult solve() {
    board = NestsBoard(size, regions);
    final rules = <String, int>{};
    var steps = 0, top = 0;
    while (!board.complete) {
      final step = board.nextStep(maxLevel: maxLevel);
      if (step == null) break;
      board.apply(step);
      steps++;
      rules[step.rule] = (rules[step.rule] ?? 0) + 1;
      if (step.level > top) top = step.level;
    }
    if (board.complete) {
      final cols = List.filled(size, 0);
      for (final c in board.critters) {
        cols[c ~/ size] = c % size;
      }
      solution = cols;
    }
    return SolveResult(solved: board.complete, steps: steps, maxLevel: top, rules: rules);
  }
}

/// The next logical step for the player, with the rule behind it.
///
/// Wrong marks come first: a misplaced critter, then a cross on a critter's cell (the player's own note, but the
/// deduction can't build on it). Otherwise the simplest deduction from the player's critters and crosses: a critter
/// to place or a cell to cross. Cells already ruled out by a placed critter don't need a cross.
Hint<NestMark>? nestsDeductionHint(NestsPuzzle puzzle, List<NestMark> marks) {
  for (var i = 0; i < marks.length; i++) {
    if (marks[i] == NestMark.critter && !puzzle.isCritterInSolution(i)) {
      return Hint(i, NestMark.empty, wrong: true, rule: 'wrong');
    }
  }
  for (var i = 0; i < marks.length; i++) {
    if (marks[i] == NestMark.cross && puzzle.isCritterInSolution(i)) {
      return Hint(i, NestMark.empty, wrong: true, rule: 'wrong');
    }
  }
  final board = NestsBoard(puzzle.size, puzzle.regions);
  for (var i = 0; i < marks.length; i++) {
    if (marks[i] == NestMark.critter) board.place(i);
  }
  if (board.complete) return null;
  for (var i = 0; i < marks.length; i++) {
    if (marks[i] == NestMark.cross) board.candidates[i] = false;
  }
  final step = board.nextStep();
  if (step == null) {
    // Not reachable for a puzzle the solver solves; reveal rather than leave the player stuck.
    final r = [for (var r = 0; r < puzzle.size; r++) r].firstWhere((r) => !board.done[r]);
    return Hint(r * puzzle.size + puzzle.solution[r], NestMark.critter, rule: 'reveal');
  }
  return Hint(step.cells.first, step.place ? NestMark.critter : NestMark.cross, rule: step.rule);
}
