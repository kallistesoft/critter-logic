import 'package:critter_logic/puzzles/difficulty.dart';
import 'package:critter_logic/puzzles/nests/generator.dart';
import 'package:critter_logic/puzzles/nests/nests.dart';
import 'package:critter_logic/puzzles/nests/solver.dart';
import 'package:critter_logic/puzzles/source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Brute-force count of solutions (stops at [limit]).
int countSolutions(int n, List<int> regions, {int limit = 2}) {
  final cols = <int>[];
  var found = 0;
  void go(int r) {
    if (found >= limit) return;
    if (r == n) {
      found++;
      return;
    }
    for (var c = 0; c < n; c++) {
      final cell = r * n + c;
      var ok = true;
      for (var pr = 0; pr < r && ok; pr++) {
        final pc = cols[pr];
        ok = pc != c && regions[pr * n + pc] != regions[cell] && !(r - pr == 1 && (pc - c).abs() <= 1);
      }
      if (!ok) continue;
      cols.add(c);
      go(r + 1);
      cols.removeLast();
    }
  }

  go(0);
  return found;
}

List<int> parse(String s) => [for (final c in s.split('')) int.parse(c)];

void main() {
  test('solves a known 5×5 and finds its critters', () {
    // Zones, critters in columns 0,2,4,1,3:
    // 0 0 0 2 2
    // 0 1 1 2 2
    // 0 3 3 3 2
    // 3 3 4 4 2
    // 3 4 4 4 4
    final regions = parse('0002201122033323344234444');
    expect(countSolutions(5, regions), 1);
    final solver = NestsSolver(5, regions);
    final result = solver.solve();
    expect(result.solved, isTrue, reason: '$result');
    expect(solver.solution, [0, 2, 4, 1, 3]);
    final puzzle = NestsPuzzle(size: 5, regions: regions, solution: solver.solution!);
    expect(NestsRules(puzzle).isSolved([
      for (var i = 0; i < 25; i++) puzzle.isCritterInSolution(i) ? NestMark.critter : NestMark.empty,
    ]), isTrue);
  });

  test('refuses layouts with two solutions', () {
    // Zones by row: both 1,3,0,2 and 2,0,3,1 fit.
    final rows = parse('0000111122223333');
    expect(countSolutions(4, rows), 2);
    expect(NestsSolver(4, rows).solve().solved, isFalse);
    // Random layouts: the solver never claims an ambiguous one, and every one it solves is unique.
    final gen = NestsGenerator(42);
    var ambiguous = 0;
    for (var i = 0; i < 400; i++) {
      final n = 5 + i % 3;
      final (_, regions) = gen.randomLayout(n);
      final count = countSolutions(n, regions);
      final solved = NestsSolver(n, regions).solve().solved;
      if (count > 1) {
        ambiguous++;
        expect(solved, isFalse);
      }
      if (solved) expect(count, 1);
    }
    expect(ambiguous, greaterThan(50));
  });

  test('300+ generated puzzles: solved, valid, unique, at their tier', () {
    var total = 0, onTier = 0;
    for (final n in [4, 5, 6, 7, 8, 9]) {
      for (final tier in Tier.values) {
        for (var i = 0; i < (n == 4 ? 4 : 20); i++) {
          final p = NestsGenerator(n * 1000 + tier.index * 100 + i).generate(n, tier);
          final solver = NestsSolver(n, p.regions);
          final result = solver.solve();
          expect(result.solved, isTrue);
          expect(solver.solution, p.solution);
          expect(p.regions.toSet(), {for (var z = 0; z < n; z++) z});
          final marks = [for (var c = 0; c < n * n; c++) p.isCritterInSolution(c) ? NestMark.critter : NestMark.empty];
          expect(NestsRules(p).isSolved(marks), isTrue);
          if (n <= 7) expect(countSolutions(n, p.regions), 1);
          expect(NestsPuzzle.fromJson(p.toJson()).regions, p.regions);
          if (nestsTierOf(result) == tier) onTier++;
          total++;
        }
      }
    }
    expect(total, greaterThanOrEqualTo(300));
    expect(onTier / total, greaterThan(0.85));
  });

  test('zones are connected', () {
    for (var i = 0; i < 30; i++) {
      const n = 8;
      final p = NestsGenerator(i).generate(n, Tier.values[i % 3]);
      for (var z = 0; z < n; z++) {
        final cells = [for (var c = 0; c < n * n; c++) if (p.regions[c] == z) c];
        final seen = {cells.first};
        final todo = [cells.first];
        while (todo.isNotEmpty) {
          final c = todo.removeLast();
          for (final d in [c - n, c + n, if (c % n > 0) c - 1, if (c % n < n - 1) c + 1]) {
            if (d >= 0 && d < n * n && p.regions[d] == z && seen.add(d)) todo.add(d);
          }
        }
        expect(seen.length, cells.length);
      }
    }
  });

  test('deterministic for a seed', () {
    for (final n in [6, 8, 9]) {
      final a = NestsGenerator(7).generate(n, Tier.hard).toJson();
      final b = NestsGenerator(7).generate(n, Tier.hard).toJson();
      expect(a, b);
    }
  });

  test('following hints from an empty board reaches the solution', () {
    for (var i = 0; i < 60; i++) {
      final n = 5 + i % 5;
      final p = NestsGenerator(500 + i).generate(n, Tier.values[i % 3]);
      final marks = List.filled(n * n, NestMark.empty);
      for (var guard = 0; guard < 2 * n * n; guard++) {
        final h = nestsHint(p, marks);
        if (h == null) break;
        expect(h.wrong, isFalse);
        expect(h.rule, isNot('reveal'));
        expect(nestsRuleLevels.keys, contains(h.rule));
        if (h.value == NestMark.critter) expect(p.isCritterInSolution(h.cell), isTrue);
        if (h.value == NestMark.cross) expect(p.isCritterInSolution(h.cell), isFalse);
        expect(marks[h.cell], NestMark.empty, reason: 'a hint always changes the board');
        marks[h.cell] = h.value;
      }
      expect(NestsRules(p).isSolved(marks), isTrue);
    }
  });

  test('wrong marks get a fix-first hint', () {
    final p = NestsGenerator(3).generate(6, Tier.medium);
    final wrongCritter = [for (var c = 0; c < 36; c++) c].firstWhere((c) => !p.isCritterInSolution(c));
    final marks = List.filled(36, NestMark.empty)..[wrongCritter] = NestMark.critter;
    final h = nestsHint(p, marks)!;
    expect((h.cell, h.value, h.wrong, h.rule), (wrongCritter, NestMark.empty, true, 'wrong'));

    final right = NestsRules(p).solutionCells().first;
    final crossed = List.filled(36, NestMark.empty)..[right] = NestMark.cross;
    final h2 = nestsHint(p, crossed)!;
    expect((h2.cell, h2.wrong), (right, true));

    final done = [for (var c = 0; c < 36; c++) p.isCritterInSolution(c) ? NestMark.critter : NestMark.empty];
    expect(nestsHint(p, done), isNull);
  });

  test('hints on a partly filled board pick up from the player', () {
    final p = NestsGenerator(11).generate(8, Tier.hard);
    final marks = List.filled(64, NestMark.empty);
    marks[NestsRules(p).solutionCells()[3]] = NestMark.critter;
    final h = nestsDeductionHint(p, marks)!;
    expect(h.wrong, isFalse);
    expect(h.cell, isNot(NestsRules(p).solutionCells()[3]));
  });

  test('generation is fast enough for a phone', () {
    // Host is ~5-10× faster than a low-end phone; the target there is < 300 ms per puzzle.
    for (final n in [7, 8, 9]) {
      final sw = Stopwatch()..start();
      const count = 12;
      for (var i = 0; i < count; i++) {
        NestsGenerator(9000 + i).generate(n, Tier.values[i % 3]);
      }
      final avg = sw.elapsedMilliseconds / count;
      expect(avg, lessThan(250), reason: '$n×$n average $avg ms');
    }
  });

  test('Hint keeps its simple constructor', () {
    const h = Hint(3, NestMark.critter);
    expect((h.wrong, h.rule), (false, ''));
  });
}
