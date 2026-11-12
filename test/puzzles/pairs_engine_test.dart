import 'package:critter_logic/puzzles/difficulty.dart';
import 'package:critter_logic/puzzles/pairs/generator.dart';
import 'package:critter_logic/puzzles/pairs/pairs.dart';
import 'package:critter_logic/puzzles/pairs/solver.dart';
import 'package:critter_logic/puzzles/source.dart';
import 'package:flutter_test/flutter_test.dart';

List<int?> parse(String s) => [for (final c in s.split('')) c == '.' ? null : int.parse(c)];

/// Brute-force count of full grids that satisfy the rules (stops at [limit]), pruning columns row by row.
int countSolutions(int n, List<int?> givens, List<PairsLink> links, {int limit = 2}) {
  final rows = PairsBoard.validLines(n);
  final chosen = <int>[];
  var found = 0;
  int at(int cell) => chosen[cell ~/ n] >> cell % n & 1;
  bool fits(int p) {
    final r = chosen.length;
    for (var k = 0; k < n; k++) {
      final v = p >> k & 1;
      final g = givens[r * n + k];
      if (g != null && g != v) return false;
      var same = 1;
      for (final q in chosen) {
        if ((q >> k & 1) == v) same++;
      }
      if (same > n ~/ 2) return false;
      if (r >= 2 && (chosen[r - 1] >> k & 1) == v && (chosen[r - 2] >> k & 1) == v) return false;
    }
    chosen.add(p);
    final ok = links.every((l) => l.b ~/ n > r || (at(l.a) == at(l.b)) == l.same);
    chosen.removeLast();
    return ok;
  }

  void go() {
    if (found >= limit) return;
    if (chosen.length == n) {
      found++;
      return;
    }
    for (final p in rows) {
      if (!fits(p)) continue;
      chosen.add(p);
      go();
      chosen.removeLast();
    }
  }

  go();
  return found;
}

void main() {
  test('solves a known 6×6', () {
    // Solution:
    // 0 1 0 1 1 0
    // 1 0 1 0 0 1
    // 0 1 1 0 1 0
    // 1 0 0 1 0 1
    // 1 0 1 1 0 0
    // 0 1 0 0 1 1
    const solution = '010110101001011010100101101100010011';
    final givens = parse('0..1......0.....1.1......0....0.....');
    final links = const [
      PairsLink(1, 2, same: false),
      PairsLink(9, 15, same: true),
      PairsLink(14, 15, same: false),
      PairsLink(22, 23, same: false),
      PairsLink(25, 26, same: false),
      PairsLink(28, 29, same: true),
    ];
    final solver = PairsSolver(6, givens, links);
    final result = solver.solve();
    expect(countSolutions(6, givens, links), 1);
    expect(result.solved, isTrue, reason: '$result');
    expect(solver.solution!.join(), solution);
    // Full givens minus a few cells is always solvable with the simple rules.
    final easy = parse(solution)..[0] = null..[7] = null..[35] = null;
    final r2 = PairsSolver(6, easy, const []).solve();
    expect((r2.solved, r2.maxLevel), (true, 1));
  });

  test('refuses ambiguous puzzles', () {
    expect(PairsSolver(4, List.filled(16, null), const []).solve().solved, isFalse);
    expect(PairsSolver(6, parse('0.................................1.'), const []).solve().solved, isFalse);
    // Random sparse clue sets: whatever the solver solves is unique.
    final gen = PairsGenerator(5);
    for (var i = 0; i < 150; i++) {
      final solution = gen.randomGrid(6);
      final givens = [for (var c = 0; c < 36; c++) gen.rnd.nextInt(4) == 0 ? solution[c] : null];
      final solver = PairsSolver(6, givens, const []);
      final solved = solver.solve().solved;
      final count = countSolutions(6, givens, const []);
      if (solved) {
        expect(count, 1);
        expect(solver.solution, solution);
      }
      if (count > 1) expect(solved, isFalse);
    }
  });

  test('300+ generated puzzles: solved, valid, unique, at their tier', () {
    var total = 0, onTier = 0;
    for (final n in [4, 6, 8]) {
      for (final tier in Tier.values) {
        for (var i = 0; i < (n == 4 ? 10 : 50); i++) {
          final p = PairsGenerator(n * 1000 + tier.index * 100 + i).generate(n, tier);
          final solver = PairsSolver(n, p.givens, p.links);
          final result = solver.solve();
          expect(result.solved, isTrue);
          expect(solver.solution, p.solution);
          expect(PairsRules(p).isSolved(p.solution), isTrue);
          for (var c = 0; c < n * n; c++) {
            if (p.givens[c] != null) expect(p.givens[c], p.solution[c]);
          }
          if (n <= 6) expect(countSolutions(n, p.givens, p.links), 1);
          final back = PairsPuzzle.fromJson(p.toJson());
          expect(back.toJson(), p.toJson());
          if (pairsTierOf(result) == tier) onTier++;
          total++;
        }
      }
    }
    expect(total, greaterThanOrEqualTo(300));
    expect(onTier / total, greaterThan(0.85));
  });

  test('deterministic for a seed', () {
    for (final n in [6, 8]) {
      expect(PairsGenerator(9).generate(n, Tier.hard).toJson(), PairsGenerator(9).generate(n, Tier.hard).toJson());
    }
  });

  test('following hints from an empty board reaches the solution', () {
    for (var i = 0; i < 60; i++) {
      final n = i.isEven ? 6 : 8;
      final p = PairsGenerator(700 + i).generate(n, Tier.values[i % 3]);
      final cells = List<int?>.of(p.givens);
      for (var guard = 0; guard < n * n; guard++) {
        final h = pairsHint(p, cells);
        if (h == null) break;
        expect(h.wrong, isFalse);
        expect(pairsRuleLevels.keys, contains(h.rule));
        expect(cells[h.cell], isNull);
        expect(h.value, p.solution[h.cell]);
        cells[h.cell] = h.value;
      }
      expect(PairsRules(p).isSolved(cells), isTrue);
    }
  });

  test('wrong symbols get a fix-first hint', () {
    final p = PairsGenerator(3).generate(6, Tier.medium);
    final free = p.givens.indexOf(null);
    final cells = List<int?>.of(p.givens)..[free] = 1 - p.solution[free];
    final h = pairsHint(p, cells)!;
    expect((h.cell, h.value, h.wrong, h.rule), (free, p.solution[free], true, 'wrong'));
    expect(pairsHint(p, List<int?>.of(p.solution)), isNull);
  });

  test('generation is fast enough for a phone', () {
    final sw = Stopwatch()..start();
    const count = 30;
    for (var i = 0; i < count; i++) {
      PairsGenerator(4000 + i).generate(8, Tier.values[i % 3]);
    }
    expect(sw.elapsedMilliseconds / count, lessThan(100));
  });

  test('Hint keeps its simple constructor', () {
    const h = Hint<int?>(3, sun);
    expect((h.wrong, h.rule), (false, ''));
  });
}
