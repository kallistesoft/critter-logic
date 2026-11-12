import 'dart:math';

import '../difficulty.dart';
import 'pairs.dart';
import 'solver.dart';

/// Most 'line' deductions a medium puzzle may need; hard needs more.
const pairsMediumMaxLine = 3;

/// The tier a solve result counts as: easy needs no 'line', medium a few, hard more.
Tier pairsTierOf(SolveResult r) {
  final line = r.uses('line');
  if (line == 0) return Tier.easy;
  if (line <= pairsMediumMaxLine) return Tier.medium;
  return Tier.hard;
}

/// Seeded Pairs generator: fills a random valid grid, adds a few links, then takes givens away while the deduction
/// solver still solves it at the requested tier, keeping at least `minGivens` of them (more givens = fewer cells to
/// work out, for quick first puzzles).
class PairsGenerator {
  PairsGenerator(int seed) : rnd = SeededRandom(seed);

  final Random rnd;

  /// Grids tried by the last [generate] call.
  int attempts = 0;

  PairsPuzzle generate(int size, Tier tier, {int minGivens = 0}) {
    final n = size;
    PairsPuzzle? fallback;
    var fallbackGap = 99;
    for (attempts = 1;; attempts++) {
      final solution = randomGrid(n);
      final links = _randomLinks(n, solution, tier);
      final givens = List<int?>.of(solution);
      final maxLevel = tier == Tier.easy ? 1 : 2;
      bool ok(SolveResult r) => r.solved && (tier != Tier.medium || r.uses('line') <= pairsMediumMaxLine);

      final order = [for (var i = 0; i < n * n; i++) i];
      shuffleWith(order, rnd);
      var given = n * n;
      for (final i in order) {
        if (given <= minGivens) break;
        givens[i] = null;
        given--;
        if (!ok(PairsSolver(n, givens, links, maxLevel: maxLevel).solve())) {
          givens[i] = solution[i];
          given++;
        }
      }
      // Drop links that add nothing, keeping at least a few for the look of the puzzle.
      final linkOrder = [for (var i = 0; i < links.length; i++) i];
      shuffleWith(linkOrder, rnd);
      final keep = List.filled(links.length, true);
      var kept = links.length;
      for (final i in linkOrder) {
        if (kept <= n ~/ 2) break;
        keep[i] = false;
        final fewer = [for (var j = 0; j < links.length; j++) if (keep[j]) links[j]];
        if (ok(PairsSolver(n, givens, fewer, maxLevel: maxLevel).solve())) {
          kept--;
        } else {
          keep[i] = true;
        }
      }
      final finalLinks = [for (var j = 0; j < links.length; j++) if (keep[j]) links[j]];
      final result = PairsSolver(n, givens, finalLinks).solve();
      final puzzle = PairsPuzzle(size: n, givens: givens, links: finalLinks, solution: solution);
      final gap = (pairsTierOf(result).index - tier.index).abs();
      if (gap == 0) return puzzle;
      if (gap < fallbackGap) {
        fallback = puzzle;
        fallbackGap = gap;
      }
      if (fallback != null && attempts >= 30) return fallback;
    }
  }

  /// A random full grid: half of each symbol per row and column, never three in a row. Rows may repeat.
  List<int> randomGrid(int n) {
    final rows = List.of(PairsBoard.validLines(n));
    final chosen = <int>[];
    bool fill() {
      if (chosen.length == n) return true;
      final order = List.of(rows);
      shuffleWith(order, rnd);
      final r = chosen.length;
      for (final p in order) {
        if (!_columnsOk(n, chosen, p, r)) continue;
        chosen.add(p);
        if (fill()) return true;
        chosen.removeLast();
      }
      return false;
    }

    fill();
    return [for (final p in chosen) for (var k = 0; k < n; k++) p >> k & 1];
  }

  /// Adding row pattern [p] at row [r] keeps every column under half moons/suns and without three in a row.
  static bool _columnsOk(int n, List<int> chosen, int p, int r) {
    for (var k = 0; k < n; k++) {
      final v = p >> k & 1;
      var same = 1;
      for (final q in chosen) {
        if ((q >> k & 1) == v) same++;
      }
      if (same > n ~/ 2) return false;
      if (r >= 2 && (chosen[r - 1] >> k & 1) == v && (chosen[r - 2] >> k & 1) == v) return false;
    }
    return true;
  }

  List<PairsLink> _randomLinks(int n, List<int> solution, Tier tier) {
    final pairs = <(int, int)>[
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++) ...[
          if (c + 1 < n) (r * n + c, r * n + c + 1),
          if (r + 1 < n) (r * n + c, (r + 1) * n + c),
        ],
    ];
    shuffleWith(pairs, rnd);
    final count = n + rnd.nextInt(n ~/ 2 + 1);
    return [
      for (final (a, b) in pairs.take(count)) PairsLink(a, b, same: solution[a] == solution[b]),
    ]..sort((x, y) => x.a != y.a ? x.a - y.a : x.b - y.b);
  }
}
