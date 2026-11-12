import 'dart:math';

import '../difficulty.dart';
import 'solver.dart';
import 'trail.dart';

/// How hard a Trail puzzle is, from its stones and the exact solver's run.
class TrailEffort {
  const TrailEffort({required this.cells, required this.stones, required this.walls, required this.result});

  final int cells;
  final int stones;
  final int walls;
  final TrailSolveResult result;

  /// Cells per stone gap: the stretch a player draws with no stone to aim at (higher = harder).
  double get gap => (cells - 1) / (stones - 1);

  /// Guesses the solver needed per 10 cells: the trial and error left once deduction is stuck (0 = none).
  double get search => result.guesses * 10 / cells;

  /// Size-independent hardness: stone gaps plus guessing. Below 5 is easy, below 7.5 medium (see [trailTierOf]);
  /// effort.dart scales it by the cell count to rank puzzles of any size.
  double get hardness => gap + 2 * search;

  @override
  String toString() =>
      'TrailEffort(stones: $stones, walls: $walls, gap: ${gap.toStringAsFixed(1)}, '
      'guesses: ${result.guesses}, hardness: ${hardness.toStringAsFixed(1)})';
}

TrailEffort trailEffortOf(TrailPuzzle p, [TrailSolveResult? result]) => TrailEffort(
  cells: p.cellCount,
  stones: p.stones.length,
  walls: p.walls.length,
  result: result ?? TrailSolver.of(p).solve(),
);

/// The tier a Trail puzzle counts as: easy is deduction alone with stones close together, hard has long stretches
/// between stones or needs trial and error.
Tier trailTierOf(TrailEffort e) {
  if (e.hardness < 5) return Tier.easy;
  if (e.hardness < 7.5) return Tier.medium;
  return Tier.hard;
}

/// Seeded Trail generator: draws a random path through every cell, puts stones along it, adds a few walls the path
/// doesn't cross, then takes stones away while the solver still finds a single solution within the tier's
/// guessing budget.
class TrailGenerator {
  TrailGenerator(int seed) : rnd = SeededRandom(seed);

  final Random rnd;

  /// Paths tried by the last [generate] call.
  int attempts = 0;

  /// Stones kept per tier, as a share of the cells: easy keeps many, hard as few as uniqueness allows.
  static const _keepShare = {Tier.easy: 0.26, Tier.medium: 0.15, Tier.hard: 0.0};

  /// Walls added per tier, as a share of the grid side (plus 0 or 1 at random).
  static const _wallShare = {Tier.easy: 0.0, Tier.medium: 0.35, Tier.hard: 0.7};

  /// Guesses per cell the solver may need for each tier: none for easy (deduction alone), a few for medium, more
  /// for hard (beyond that a puzzle is more luck than logic).
  static const _guessShare = {Tier.easy: 0.0, Tier.medium: 0.1, Tier.hard: 0.6};

  TrailPuzzle generate(int size, Tier tier) {
    final cells = size * size;
    TrailPuzzle? fallback;
    var fallbackGap = 99;
    for (attempts = 1; ; attempts++) {
      final path = randomPath(size);
      final walls = _randomWalls(size, path, (_wallShare[tier]! * size).round() + rnd.nextInt(2));
      final minStones = max(2, (_keepShare[tier]! * cells).round());
      final puzzle = _carve(size, path, walls, minStones, (_guessShare[tier]! * cells).floor());
      final gap = (trailTierOf(trailEffortOf(puzzle)).index - tier.index).abs();
      if (gap == 0) return puzzle;
      if (gap < fallbackGap) {
        fallback = puzzle;
        fallbackGap = gap;
      }
      if (attempts >= 8) return fallback!;
    }
  }

  /// Stones on [path], taken away in random order down to [minStones] while the puzzle stays unique within
  /// [maxGuesses] guesses.
  TrailPuzzle _carve(int size, List<int> path, List<(int, int)> walls, int minStones, int maxGuesses) {
    final cells = size * size;
    // Path positions holding a stone: the ends, plus every other cell to start with.
    final keep = List.filled(cells, false);
    keep[0] = keep[cells - 1] = true;
    for (var i = 2; i < cells - 1; i += 2) {
      keep[i] = true;
    }
    List<int> stonesOf() => [
      for (var i = 0; i < cells; i++)
        if (keep[i]) path[i],
    ];
    bool ok() {
      final r = TrailSolver(size, stonesOf(), walls: walls, maxGuesses: maxGuesses + 1).solve();
      return r.unique && r.guesses <= maxGuesses;
    }

    if (!ok()) {
      keep.fillRange(0, cells, true); // Every cell a stone: always unique, with no guess.
    }
    var count = keep.where((k) => k).length;
    final order = [
      for (var i = 1; i < cells - 1; i++)
        if (keep[i]) i,
    ];
    shuffleWith(order, rnd);
    for (final i in order) {
      if (count <= minStones) break;
      keep[i] = false;
      if (ok()) {
        count--;
      } else {
        keep[i] = true;
      }
    }
    return TrailPuzzle(size: size, stones: stonesOf(), walls: walls, solution: path);
  }

  /// Up to [count] walls between side-by-side cells that are not consecutive on [path], never leaving a cell
  /// with a single way in.
  List<(int, int)> _randomWalls(int size, List<int> path, int count) {
    if (count == 0) return const [];
    final n = size, cells = n * n;
    final pos = List.filled(cells, 0);
    for (var i = 0; i < cells; i++) {
      pos[path[i]] = i;
    }
    final degree = [
      for (var c = 0; c < cells; c++)
        (c ~/ n > 0 ? 1 : 0) + (c ~/ n < n - 1 ? 1 : 0) + (c % n > 0 ? 1 : 0) + (c % n < n - 1 ? 1 : 0),
    ];
    final edges = <(int, int)>[
      for (var c = 0; c < cells; c++) ...[
        if (c % n < n - 1 && (pos[c] - pos[c + 1]).abs() != 1) (c, c + 1),
        if (c ~/ n < n - 1 && (pos[c] - pos[c + n]).abs() != 1) (c, c + n),
      ],
    ];
    shuffleWith(edges, rnd);
    final out = <(int, int)>[];
    for (final (a, b) in edges) {
      if (out.length >= count) break;
      if (degree[a] <= 2 || degree[b] <= 2) continue;
      degree[a]--;
      degree[b]--;
      out.add((a, b));
    }
    return out..sort((x, y) => x.$1 != y.$1 ? x.$1 - y.$1 : x.$2 - y.$2);
  }

  /// A random path through every cell of a [size]×[size] grid: a snake, scrambled by backbite moves (an end of the
  /// path links to a neighbouring cell of the path and the piece in between turns around).
  List<int> randomPath(int size) {
    final n = size, cells = n * n;
    final path = [
      for (var r = 0; r < n; r++)
        for (var k = 0; k < n; k++) r * n + (r.isEven ? k : n - 1 - k),
    ];
    if (rnd.nextBool()) {
      for (var i = 0; i < cells; i++) {
        path[i] = (path[i] % n) * n + path[i] ~/ n; // Columns instead of rows.
      }
    }
    final pos = List.filled(cells, 0);
    for (var i = 0; i < cells; i++) {
      pos[path[i]] = i;
    }
    void reverse(int from, int to) {
      for (var a = from, b = to; a < b; a++, b--) {
        final t = path[a];
        path[a] = path[b];
        path[b] = t;
        pos[path[a]] = a;
        pos[path[b]] = b;
      }
    }

    final moves = 12 * cells * n;
    for (var m = 0; m < moves; m++) {
      final atHead = rnd.nextBool();
      final end = atHead ? path[0] : path[cells - 1];
      final r = end ~/ n, c = end % n;
      final x = switch (rnd.nextInt(4)) {
        0 => r > 0 ? end - n : -1,
        1 => r < n - 1 ? end + n : -1,
        2 => c > 0 ? end - 1 : -1,
        _ => c < n - 1 ? end + 1 : -1,
      };
      if (x < 0) continue;
      final i = pos[x];
      if (atHead) {
        if (i > 1) reverse(0, i - 1);
      } else {
        if (i < cells - 2) reverse(i + 1, cells - 1);
      }
    }
    return path;
  }
}
