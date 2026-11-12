import 'package:critter_logic/puzzles/difficulty.dart';
import 'package:critter_logic/puzzles/source.dart';
import 'package:critter_logic/puzzles/trail/generator.dart';
import 'package:critter_logic/puzzles/trail/solver.dart';
import 'package:critter_logic/puzzles/trail/trail.dart';
import 'package:flutter_test/flutter_test.dart';

/// Brute-force count of solutions (stops at [limit]): every path from stone 1, cell by cell, with only the
/// pruning needed to finish in time (stones in order, free cells connected). Independent of [TrailSolver].
int countSolutions(int n, List<int> stones, {List<(int, int)> walls = const [], int limit = 2}) {
  final cells = n * n;
  final wall = {for (final (a, b) in walls) a < b ? (a, b) : (b, a)};
  List<int> next(int c) => [
        if (c ~/ n > 0) c - n,
        if (c ~/ n < n - 1) c + n,
        if (c % n > 0) c - 1,
        if (c % n < n - 1) c + 1,
      ].where((d) => !wall.contains(c < d ? (c, d) : (d, c))).toList();
  final nb = [for (var c = 0; c < cells; c++) next(c)];
  final number = {for (var i = 0; i < stones.length; i++) stones[i]: i + 1};
  final seen = List.filled(cells, false);
  var found = 0;

  bool connected(int head, int left) {
    final mark = {head};
    final todo = [head];
    var count = 0;
    while (todo.isNotEmpty) {
      final c = todo.removeLast();
      for (final d in nb[c]) {
        if (!seen[d] && mark.add(d)) {
          count++;
          todo.add(d);
        }
      }
    }
    return count == left;
  }

  void go(int head, int count, int want) {
    if (found >= limit) return;
    if (count == cells) {
      if (head == stones.last) found++;
      return;
    }
    if (!connected(head, cells - count)) return;
    for (final d in nb[head]) {
      if (seen[d]) continue;
      final k = number[d];
      if (k != null && k != want) continue;
      seen[d] = true;
      go(d, count + 1, k != null ? want + 1 : want);
      seen[d] = false;
    }
  }

  seen[stones.first] = true;
  go(stones.first, 1, 2);
  return found;
}

void main() {
  // A 4×4 snake: 0 1 2 3 / 7 6 5 4 / 8 9 10 11 / 15 14 13 12, stones 1 at 0, 2 at 6, 3 at 12.
  final snake = [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11, 15, 14, 13, 12];

  group('rules', () {
    final p = TrailPuzzle(size: 4, stones: const [0, 6, 12], walls: const [(1, 5)], solution: snake);

    test('a legal partial path, then each kind of mistake', () {
      final rules = TrailRules(p);
      expect(rules.firstError(const []), isNull);
      expect(rules.firstError(const [0, 1, 2]), isNull);
      expect(rules.firstError(const [1, 2]), (0, TrailError.start));
      expect(rules.firstError(const [0, 1, 3]), (2, TrailError.jump));
      expect(rules.firstError(const [0, 4, 8, 9, 10, 6]), isNull, reason: '6 is stone 2, reached in order');
      expect(rules.firstError(const [0, 1, 5]), (2, TrailError.wall));
      expect(rules.firstError(const [0, 1, 2, 1]), (3, TrailError.revisit));
      expect(rules.firstError(const [0, 4, 5, 9, 8, 4]), (5, TrailError.revisit));
      expect(rules.firstError(const [0, 4, 8, 12]), (3, TrailError.order), reason: 'stone 3 before stone 2');
      expect(rules.firstError(const [0, 4, 5, 6, 10, 14, 13, 12]), isNull);
      expect(rules.firstError(const [0, 4, 5, 6, 10, 14, 13, 12, 8]), (8, TrailError.end), reason: 'past the last stone');
      final q = TrailPuzzle(size: 4, stones: const [0, 6, 9, 12], solution: snake);
      expect(TrailRules(q).firstError(const [0, 4, 5, 9]), (3, TrailError.order));
      expect(rules.conflicts(const [0, 1, 5, 6]), {5, 6});
      expect(rules.conflicts(const [0, 1, 2]), isEmpty);
      expect(rules.canExtend(const [], 0), isTrue);
      expect(rules.canExtend(const [], 1), isFalse);
      expect(rules.canExtend(const [0, 1], 2), isTrue);
      expect(rules.canExtend(const [0, 1], 5), isFalse);
    });

    test('solved only when every cell is on the path, ending on the last stone', () {
      final rules = TrailRules(p);
      expect(rules.isSolved(snake), isTrue);
      expect(rules.isSolved(snake.sublist(0, 15)), isFalse);
      expect(rules.isSolved([...snake.sublist(0, 15), 12]), isTrue);
      // Same cells, wrong order: through stone 3 before stone 2.
      expect(rules.isSolved(const [0, 4, 8, 12, 13, 9, 5, 1, 2, 6, 10, 14, 15, 11, 7, 3]), isFalse);
    });

    test('compact JSON round trip', () {
      final json = p.toJson();
      expect(json, {
        's': 4,
        'n': [0, 6, 12],
        'w': [
          [1, 5],
        ],
        'x': 'RRRDLLLDRRRDLLL',
      });
      final back = TrailPuzzle.fromJson(json);
      expect(back.solution, snake);
      expect(back.stones, p.stones);
      expect(back.walls, p.walls);
      expect(back.hasWall(5, 1), isTrue);
      expect(back.canStep(1, 5), isFalse);
      expect(back.canStep(0, 1), isTrue);
      expect(TrailPuzzle.fromJson(TrailPuzzle(size: 4, stones: const [0, 12], solution: snake).toJson()).walls,
          isEmpty);
    });
  });

  group('solver', () {
    test('solves a known 4×4 and finds its path', () {
      // Stones at both ends of each row of the snake; with only [0, 6, 12] there are 8 ways.
      expect(countSolutions(4, const [0, 6, 12], limit: 10), 8);
      expect(TrailSolver(4, const [0, 6, 12], limit: 10).solve().solutions, 8);
      final r = TrailSolver(4, const [0, 3, 4, 11, 12]).solve();
      expect(countSolutions(4, const [0, 3, 4, 11, 12]), 1);
      expect(r.guesses, 0, reason: 'pure deduction');
      expect(r.solutions, 1);
      expect(r.path, snake);
    });

    test('counts more than one solution when the stones allow it', () {
      // Corner to corner on 4×4 with no other stone: many paths.
      expect(countSolutions(4, const [0, 15]), 0, reason: 'same color corners on an even grid');
      expect(TrailSolver(4, const [0, 15]).solve().solutions, 0);
      expect(countSolutions(4, const [0, 3]), 2);
      expect(TrailSolver(4, const [0, 3]).solve().solutions, 2);
      expect(TrailSolver(4, const [0, 3], limit: 10).solve().solutions, countSolutions(4, const [0, 3], limit: 10));
    });

    test('agrees with brute force on random stones and walls', () {
      final gen = TrailGenerator(5);
      final rnd = SeededRandom(17);
      var unique = 0, ambiguous = 0;
      for (var i = 0; i < 250; i++) {
        final n = 4 + i % 2;
        final path = gen.randomPath(n);
        final cells = n * n;
        final stones = [
          for (var k = 0; k < cells; k++)
            if (k == 0 || k == cells - 1 || rnd.nextInt(5) == 0) path[k],
        ];
        final walls = <(int, int)>[
          for (var c = 0; c < cells; c++)
            if (c % n < n - 1 && rnd.nextInt(6) == 0) (c, c + 1),
        ];
        // Some walls cut the path: then the stored path is no solution, but counts must still agree.
        final expected = countSolutions(n, stones, walls: walls, limit: 3);
        final r = TrailSolver(n, stones, walls: walls, limit: 3).solve();
        expect(r.solutions, expected, reason: 'n $n stones $stones walls $walls');
        if (expected == 1) {
          unique++;
          expect(TrailRules(TrailPuzzle(size: n, stones: stones, walls: walls, solution: r.path!)).isSolved(r.path!),
              isTrue);
        }
        if (expected > 1) ambiguous++;
      }
      expect(unique, greaterThan(20));
      expect(ambiguous, greaterThan(30));
    });
  });

  test('300+ generated puzzles: unique, valid, at their tier', () {
    var total = 0, onTier = 0;
    for (final n in [4, 5, 6, 7, 8]) {
      for (final tier in Tier.values) {
        for (var i = 0; i < (n == 4 ? 10 : 25); i++) {
          final p = TrailGenerator(n * 1000 + tier.index * 100 + i).generate(n, tier);
          expect(p.solution.toSet().length, n * n);
          expect(TrailRules(p).isSolved(p.solution), isTrue);
          final r = TrailSolver.of(p).solve();
          expect(r.solutions, 1);
          expect(r.path, p.solution);
          if (n <= 5) expect(countSolutions(n, p.stones, walls: p.walls), 1);
          for (final (a, b) in p.walls) {
            expect(p.adjacent(a, b), isTrue);
            expect((p.solution.indexOf(a) - p.solution.indexOf(b)).abs(), isNot(1), reason: 'walls never cut it');
          }
          expect(TrailPuzzle.fromJson(p.toJson()).toJson(), p.toJson());
          final e = trailEffortOf(p, r);
          if (tier == Tier.easy) expect(r.guesses, 0, reason: 'easy is deduction alone');
          if (trailTierOf(e) == tier) onTier++;
          total++;
        }
      }
    }
    expect(total, greaterThanOrEqualTo(300));
    expect(onTier / total, greaterThan(0.85));
  });

  test('brute force confirms uniqueness on generated 6×6', () {
    for (var i = 0; i < 24; i++) {
      final p = TrailGenerator(600 + i).generate(6, Tier.values[i % 3]);
      expect(countSolutions(6, p.stones, walls: p.walls), 1);
    }
  });

  test('deterministic for a seed', () {
    for (final n in [5, 7, 8]) {
      expect(TrailGenerator(9).generate(n, Tier.hard).toJson(), TrailGenerator(9).generate(n, Tier.hard).toJson());
    }
    expect(TrailGenerator(1).randomPath(6), TrailGenerator(1).randomPath(6));
    expect(TrailGenerator(1).randomPath(6), isNot(TrailGenerator(2).randomPath(6)));
  });

  test('following hints from an empty path reaches the solution', () {
    for (var i = 0; i < 30; i++) {
      final n = 5 + i % 4;
      final p = TrailGenerator(700 + i).generate(n, Tier.values[i % 3]);
      final path = <int>[];
      for (var guard = 0; guard <= n * n; guard++) {
        final h = trailHint(p, path);
        if (h == null) break;
        expect((h.wrong, h.rule, h.value), (false, 'next', path.length));
        expect(TrailRules(p).canExtend(path, h.cell), isTrue);
        path.add(h.cell);
      }
      expect(TrailRules(p).isSolved(path), isTrue);
    }
  });

  test('a path that leaves the solution gets an undo hint', () {
    final p = TrailGenerator(3).generate(6, Tier.medium);
    final sol = p.solution;
    // Right for 5 cells, then a wrong turn.
    final wrong = sol.sublist(0, 5);
    final turn = [sol[4] - 1, sol[4] + 1, sol[4] - 6, sol[4] + 6]
        .firstWhere((c) => c >= 0 && c < 36 && p.adjacent(sol[4], c) && c != sol[5] && !wrong.contains(c));
    final h = trailHint(p, [...wrong, turn])!;
    expect((h.cell, h.value, h.wrong, h.rule), (sol[4], 5, true, 'undo'));
    final h2 = trailHint(p, [sol[1]])!;
    expect((h2.cell, h2.value, h2.wrong), (sol[0], 0, true), reason: 'not starting on stone 1: undo everything');
    expect(trailHint(p, sol), isNull);
  });

  test('generation is fast enough for a phone', () {
    // Host is ~5-10× faster than a low-end phone; aim at < 50 ms on host for 7×7.
    for (final n in [5, 6, 7, 8]) {
      final sw = Stopwatch()..start();
      const count = 30;
      for (var i = 0; i < count; i++) {
        TrailGenerator(9000 + i).generate(n, Tier.values[i % 3]);
      }
      final avg = sw.elapsedMilliseconds / count;
      expect(avg, lessThan(n <= 7 ? 50 : 100), reason: '$n×$n average $avg ms');
    }
  });

  test('Hint keeps its simple constructor', () {
    const h = Hint<int>(3, 0);
    expect((h.wrong, h.rule), (false, ''));
  });
}
