import 'dart:math';

import '../difficulty.dart';
import 'nests.dart';
import 'solver.dart';

/// The tier a solve result counts as: easy needs no 'block', medium one 'block', hard more or a 'group'.
Tier nestsTierOf(SolveResult r) {
  if (r.maxLevel <= 2) return Tier.easy;
  if (r.maxLevel == 3 && r.uses('block') == 1) return Tier.medium;
  return Tier.hard;
}

/// Seeded Nests generator: places the critters, grows the zones around them and keeps a layout only when the
/// deduction solver solves it at the requested tier.
class NestsGenerator {
  NestsGenerator(int seed) : rnd = SeededRandom(seed);

  final Random rnd;

  /// The hardest rule each tier may need; the solver always takes the simplest rule first, so capping it doesn't
  /// change the steps of a layout it solves.
  static const _maxLevel = {Tier.easy: 2, Tier.medium: 3, Tier.hard: 4};

  /// Layouts tried by the last [generate] call.
  int attempts = 0;

  NestsPuzzle generate(int size, Tier tier) {
    NestsPuzzle? fallback;
    var fallbackGap = 99;
    for (attempts = 1;; attempts++) {
      final (critters, regions) = randomLayout(size);
      final result = _reshape(size, critters, regions, _maxLevel[tier]!);
      if (result == null) continue;
      final puzzle = NestsPuzzle(size: size, regions: regions, solution: critters);
      final gap = (nestsTierOf(result).index - tier.index).abs();
      if (gap == 0) return puzzle;
      if (gap < fallbackGap) {
        fallback = puzzle;
        fallbackGap = gap;
      }
      // Some sizes rarely reach a tier (a 5×5 is seldom hard); settle for the closest after a while.
      if (fallback != null && attempts >= 60) return fallback;
    }
  }

  /// Hill climb: while the solver gets stuck, move a cell it could not rule out into a neighbouring zone, keeping
  /// the move when the solver gets at least as far. Edits [regions] in place; null when it never gets solved.
  SolveResult? _reshape(int n, List<int> critters, List<int> regions, int maxLevel) {
    final isCritter = List.filled(n * n, false);
    for (var r = 0; r < n; r++) {
      isCritter[r * n + critters[r]] = true;
    }
    var solver = NestsSolver(n, regions, maxLevel: maxLevel);
    var result = solver.solve();
    var progress = solver.board.candidates.where((c) => !c).length;
    for (var move = 0; move < 20 * n && !result.solved; move++) {
      final stuck = [
        for (var i = 0; i < n * n; i++)
          if (solver.board.candidates[i] && !isCritter[i]) i,
      ];
      final cell = stuck[rnd.nextInt(stuck.length)];
      final from = regions[cell];
      final r = cell ~/ n, c = cell % n;
      final targets = <int>{
        if (r > 0) regions[cell - n],
        if (r < n - 1) regions[cell + n],
        if (c > 0) regions[cell - 1],
        if (c < n - 1) regions[cell + 1],
      }..remove(from);
      if (targets.isEmpty) continue;
      final to = targets.elementAt(rnd.nextInt(targets.length));
      regions[cell] = to;
      if (!_connected(n, regions, from)) {
        regions[cell] = from;
        continue;
      }
      final next = NestsSolver(n, regions, maxLevel: maxLevel);
      final nextResult = next.solve();
      final nextProgress = next.board.candidates.where((c) => !c).length;
      if (nextResult.solved || nextProgress >= progress) {
        solver = next;
        result = nextResult;
        progress = nextProgress;
      } else {
        regions[cell] = from;
      }
    }
    return result.solved ? result : null;
  }

  static bool _connected(int n, List<int> regions, int zone) {
    final start = regions.indexOf(zone);
    if (start < 0) return false;
    final seen = {start};
    final todo = [start];
    while (todo.isNotEmpty) {
      final i = todo.removeLast();
      final r = i ~/ n, c = i % n;
      for (final j in [if (r > 0) i - n, if (r < n - 1) i + n, if (c > 0) i - 1, if (c < n - 1) i + 1]) {
        if (regions[j] == zone && seen.add(j)) todo.add(j);
      }
    }
    return seen.length == regions.where((z) => z == zone).length;
  }

  /// A random critter placement and zones grown around it (not checked for uniqueness).
  (List<int>, List<int>) randomLayout(int size) {
    final critters = _placeCritters(size);
    return (critters, _growZones(size, critters));
  }

  /// One critter per row and column, none touching: a random permutation with neighbouring rows 2+ columns apart.
  List<int> _placeCritters(int n) {
    final cols = List.filled(n, -1);
    final used = List.filled(n, false);
    bool fill(int row) {
      if (row == n) return true;
      final order = [for (var c = 0; c < n; c++) c];
      shuffleWith(order, rnd);
      for (final c in order) {
        if (used[c] || (row > 0 && (cols[row - 1] - c).abs() <= 1)) continue;
        used[c] = true;
        cols[row] = c;
        if (fill(row + 1)) return true;
        used[c] = false;
      }
      return false;
    }

    fill(0);
    return cols;
  }

  /// Grows one zone from each critter, each zone at its own random pace, then shuffles the zone ids.
  List<int> _growZones(int n, List<int> critters) {
    final regions = List.filled(n * n, -1);
    for (var r = 0; r < n; r++) {
      regions[r * n + critters[r]] = r;
    }
    final weights = [for (var z = 0; z < n; z++) 1 + rnd.nextInt(6)];
    var left = n * n - n;
    final open = List.filled(n, true);
    while (left > 0) {
      var total = 0;
      for (var z = 0; z < n; z++) {
        if (open[z]) total += weights[z];
      }
      var pick = rnd.nextInt(total);
      var zone = 0;
      for (var z = 0; z < n; z++) {
        if (!open[z]) continue;
        if (pick < weights[z]) {
          zone = z;
          break;
        }
        pick -= weights[z];
      }
      final frontier = <int>[];
      for (var i = 0; i < n * n; i++) {
        if (regions[i] != -1) continue;
        final r = i ~/ n, c = i % n;
        if ((r > 0 && regions[i - n] == zone) ||
            (r < n - 1 && regions[i + n] == zone) ||
            (c > 0 && regions[i - 1] == zone) ||
            (c < n - 1 && regions[i + 1] == zone)) {
          frontier.add(i);
        }
      }
      if (frontier.isEmpty) {
        open[zone] = false;
        continue;
      }
      regions[frontier[rnd.nextInt(frontier.length)]] = zone;
      left--;
    }
    final ids = [for (var z = 0; z < n; z++) z];
    shuffleWith(ids, rnd);
    return [for (final z in regions) ids[z]];
  }
}
