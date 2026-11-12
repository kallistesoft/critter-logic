import 'dart:convert';
import 'dart:io';

import 'package:critter_logic/daily.dart';
import 'package:critter_logic/puzzles/bundled_source.dart';
import 'package:critter_logic/puzzles/difficulty.dart';
import 'package:critter_logic/puzzles/effort.dart';
import 'package:critter_logic/puzzles/levels.dart';
import 'package:critter_logic/puzzles/nests/generator.dart';
import 'package:critter_logic/puzzles/nests/nests.dart';
import 'package:critter_logic/puzzles/nests/solver.dart';
import 'package:critter_logic/puzzles/pairs/generator.dart';
import 'package:critter_logic/puzzles/pairs/pairs.dart';
import 'package:critter_logic/puzzles/pairs/solver.dart';
import 'package:critter_logic/puzzles/trail/generator.dart';
import 'package:critter_logic/puzzles/trail/solver.dart';
import 'package:critter_logic/puzzles/trail/trail.dart';
import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> bundled(String game) {
  final json = jsonDecode(File('assets/dailies/$game.json').readAsStringSync()) as Map<String, dynamic>;
  expect(json['first'], 1);
  return (json['puzzles'] as List).cast<Map<String, dynamic>>();
}

/// Mean effort of the bundled dailies per weekday, Monday first.
List<double> weekdayMeans(String game, Effort Function(Map<String, dynamic>) effort) {
  final sums = List.filled(7, 0.0), counts = List.filled(7, 0);
  final dailies = bundled(game);
  for (var i = 0; i < dailies.length; i++) {
    final day = dateOfDaily(i + 1).weekday - 1;
    sums[day] += effort(dailies[i]).score;
    counts[day]++;
  }
  return [for (var d = 0; d < 7; d++) sums[d] / counts[d]];
}

void main() {
  test('bundled Nests dailies: 730, solved by deduction, matching their stored solution and weekday', () {
    final dailies = bundled('nests');
    expect(dailies.length, 730);
    final seen = <String>{};
    for (var i = 0; i < dailies.length; i++) {
      final p = NestsPuzzle.fromJson(dailies[i]);
      final solver = NestsSolver(p.size, p.regions);
      final result = solver.solve();
      expect(result.solved, isTrue, reason: 'daily ${i + 1}');
      expect(solver.solution, p.solution);
      final marks = [for (var c = 0; c < p.size * p.size; c++) p.isCritterInSolution(c) ? NestMark.critter : NestMark.empty];
      expect(NestsRules(p).isSolved(marks), isTrue);
      final spec = nestsDailySpec(i + 1);
      expect(p.size, spec.size);
      expect((nestsTierOf(result).index - spec.tier.index).abs(), lessThanOrEqualTo(1));
      seen.add(dailies[i]['r'] as String);
    }
    expect(seen.length, 730, reason: 'no repeated daily');
  });

  test('bundled Pairs dailies: 730, solved by deduction, matching their stored solution and weekday', () {
    final dailies = bundled('pairs');
    expect(dailies.length, 730);
    for (var i = 0; i < dailies.length; i++) {
      final p = PairsPuzzle.fromJson(dailies[i]);
      final solver = PairsSolver(p.size, p.givens, p.links);
      final result = solver.solve();
      expect(result.solved, isTrue, reason: 'daily ${i + 1}');
      expect(solver.solution, p.solution);
      expect(PairsRules(p).isSolved(p.solution), isTrue);
      final spec = pairsDailySpec(i + 1);
      expect(p.size, spec.size);
      expect((pairsTierOf(result).index - spec.tier.index).abs(), lessThanOrEqualTo(1));
    }
  });

  test('bundled Trail dailies: 730, unique, matching their stored solution and weekday', () {
    final dailies = bundled('trail');
    expect(dailies.length, 730);
    final seen = <String>{};
    for (var i = 0; i < dailies.length; i++) {
      final p = TrailPuzzle.fromJson(dailies[i]);
      final result = TrailSolver.of(p).solve();
      expect(result.solutions, 1, reason: 'daily ${i + 1}');
      expect(result.path, p.solution);
      expect(TrailRules(p).isSolved(p.solution), isTrue);
      final spec = trailDailySpec(i + 1);
      expect(p.size, spec.size);
      expect((trailTierOf(trailEffortOf(p, result)).index - spec.tier.index).abs(), lessThanOrEqualTo(1));
      seen.add(jsonEncode(dailies[i]));
    }
    expect(seen.length, 730, reason: 'no repeated daily');
  });

  test('regenerating dailies gives the bundled puzzles', () {
    // Fails on purpose when a generator or a daily spec changes: rerun dart run tools/gen_dailies.dart.
    final nests = bundled('nests'), pairs = bundled('pairs'), trail = bundled('trail');
    for (final n in [1, 2, 7, 100, 365, 730]) {
      expect(jsonEncode(generateNestsDaily(n).toJson()), jsonEncode(nests[n - 1]), reason: 'Nests daily $n');
      expect(jsonEncode(generatePairsDaily(n).toJson()), jsonEncode(pairs[n - 1]), reason: 'Pairs daily $n');
      expect(jsonEncode(generateTrailDaily(n).toJson()), jsonEncode(trail[n - 1]), reason: 'Trail daily $n');
    }
  });

  test('daily difficulty follows the weekday', () {
    // Daily 1 is Tuesday 2026-12-01; daily 7 is Monday 2026-12-07.
    expect(nestsDailySpec(7), const PuzzleSpec(6, Tier.easy));
    expect(nestsDailySpec(6), const PuzzleSpec(8, Tier.hard));
    expect(pairsDailySpec(7), const PuzzleSpec(6, Tier.easy));
    expect(pairsDailySpec(6), const PuzzleSpec(8, Tier.hard));
    expect(trailDailySpec(7), const PuzzleSpec(6, Tier.easy));
    expect(trailDailySpec(6).tier, Tier.hard);
    for (var n = 1; n <= 7; n++) {
      expect(trailDailySpec(n).size, inInclusiveRange(6, 8));
    }
  });

  test('bundled dailies get harder every weekday, Monday to Sunday', () {
    for (final (game, effort) in <(String, Effort Function(Map<String, dynamic>))>[
      ('nests', (j) => nestsEffort(NestsPuzzle.fromJson(j))),
      ('pairs', (j) => pairsEffort(PairsPuzzle.fromJson(j))),
      ('trail', (j) => trailEffort(TrailPuzzle.fromJson(j))),
    ]) {
      final means = weekdayMeans(game, effort);
      for (var d = 1; d < 7; d++) {
        expect(means[d], greaterThan(means[d - 1]), reason: '$game weekday means $means');
      }
      expect(means[6], greaterThan(2.5 * means[0]), reason: '$game: Sunday is a real step up from Monday');
    }
  });

  test('level ramps: small and easy first, max size and hard late, breathers', () {
    for (final (spec, step, maxSize) in [(nestsLevelSpec, 1, 9), (pairsLevelSpec, 2, 8), (trailLevelSpec, 1, 8)]) {
      for (var l = 1; l <= 10; l++) {
        expect(spec(l).tier, Tier.easy, reason: 'level $l');
        expect(spec(l).size, lessThanOrEqualTo(6), reason: 'level $l');
      }
      for (var l = 1; l <= 300; l++) {
        expect(spec(l).size, inInclusiveRange(5, maxSize));
      }
      // Never more than one size step (Pairs sizes are even) above any earlier non-breather level.
      for (var l = 2; l <= 300; l++) {
        final before = [
          for (var k = 1; k < l; k++)
            if (!isBreatherLevel(k)) spec(k).size,
        ];
        expect(spec(l).size, lessThanOrEqualTo(before.reduce((a, b) => a > b ? a : b) + step));
      }
      final late = [for (var l = 60; l < 120; l++) spec(l)];
      expect([for (var l = 60; l < 120; l++) if (!isBreatherLevel(l) && spec(l).tier == Tier.easy) l], isEmpty);
      expect(late.where((s) => s.tier == Tier.hard).length, greaterThanOrEqualTo(25));
      expect(late.where((s) => s.size == maxSize).length, greaterThanOrEqualTo(25));
    }
    for (final l in [11, 21, 41]) {
      expect(isBreatherLevel(l), isFalse, reason: 'a step-up is never a breather');
    }
    expect([for (var l = 1; l <= 60; l++) if (isBreatherLevel(l)) l], [17, 24, 31, 38, 45, 52, 59]);
    expect(nestsLevelSpec(60).size, 9);
    expect(pairsLevelSpec(61).size, 8);
    expect(pairsLevelSpec(1).givens, greaterThanOrEqualTo(0.4), reason: 'first Pairs: many givens');
    expect([for (var l = 1; l <= 300; l++) pairsLevelSpec(l).size].every((s) => s == 6 || s == 8), isTrue);
  });

  test('level efforts: quick wins first, step-ups at 11, 21 and 41, no spike', () {
    for (final (game, effort) in <(String, double Function(int))>[
      ('nests', (l) => nestsEffort(generateNestsLevel(l)).score),
      ('pairs', (l) => pairsEffort(generatePairsLevel(l)).score),
      ('trail', (l) => trailEffort(generateTrailLevel(l)).score),
    ]) {
      final e = [for (var l = 1; l <= 100; l++) effort(l)];
      double mean(int from, int to) => e.sublist(from - 1, to).reduce((a, b) => a + b) / (to - from + 1);
      for (var l = 2; l <= 100; l++) {
        final prev = e.sublist(l - 1 - (l - 1).clamp(0, 5), l - 1);
        final avg = prev.reduce((a, b) => a + b) / prev.length;
        expect(e[l - 1], lessThanOrEqualTo(1.5 * avg), reason: '$game level $l: ${e[l - 1]} after a mean of $avg');
      }
      expect(mean(11, 20), greaterThan(1.2 * mean(1, 10)), reason: game);
      expect(mean(21, 40), greaterThan(1.2 * mean(11, 20)), reason: game);
      expect(mean(41, 60), greaterThan(1.2 * mean(21, 40)), reason: game);
      expect(mean(61, 100), greaterThan(mean(41, 60)), reason: game);
      expect(e[16], lessThan(0.8 * mean(12, 16)), reason: '$game: level 17 is a breather');
    }
  });

  test('levels are deterministic and stable across app versions', () {
    // Pinned so an accidental change to a generator (which would reshuffle every level) fails here.
    expect(generateNestsLevel(1).toJson(), golden['nests1']);
    expect(generatePairsLevel(1).toJson(), golden['pairs1']);
    expect(generateTrailLevel(1).toJson(), golden['trail1']);
    for (final l in [5, 33, 60]) {
      expect(generateNestsLevel(l).toJson(), generateNestsLevel(l).toJson());
      expect(generatePairsLevel(l).toJson(), generatePairsLevel(l).toJson());
      expect(generateTrailLevel(l).toJson(), generateTrailLevel(l).toJson());
    }
  });

  test('BundledPuzzleSource: bundle first, generation past it', () async {
    final source = BundledPuzzleSource(load: (key) async => File(key).readAsStringSync(), useIsolate: false);
    final nests = bundled('nests'), pairs = bundled('pairs'), trail = bundled('trail');
    expect((await source.dailyNests(1)).toJson(), nests[0]);
    expect((await source.dailyPairs(730)).toJson(), pairs[729]);
    expect((await source.dailyTrail(365)).toJson(), trail[364]);
    expect((await source.dailyNests(731)).toJson(), generateNestsDaily(731).toJson());
    expect((await source.dailyPairs(0)).toJson(), generatePairsDaily(0).toJson());
    expect((await source.dailyTrail(731)).toJson(), generateTrailDaily(731).toJson());
    expect((await source.levelNests(3)).toJson(), generateNestsLevel(3).toJson());
    expect((await source.levelPairs(3)).toJson(), generatePairsLevel(3).toJson());
    expect((await source.levelTrail(3)).toJson(), generateTrailLevel(3).toJson());

    final missing = BundledPuzzleSource(load: (key) async => throw StateError('no asset'), useIsolate: false);
    expect((await missing.dailyNests(5)).toJson(), generateNestsDaily(5).toJson());
    expect((await missing.dailyTrail(5)).toJson(), generateTrailDaily(5).toJson());
  });
}

const golden = <String, Map<String, dynamic>>{
  'nests1': {'s': 5, 'r': '0111101443000430244300444', 'x': '20413'},
  'pairs1': {
    's': 6,
    'g': '.100...10.0.10...1.110.0.001..0..1..',
    'l': [
      [0, 1, 0], [7, 8, 0], [15, 21, 1], //
    ],
    'x': '010011110100101001011010100110001101',
  },
  'trail1': {
    's': 5,
    'n': [10, 16, 20, 12, 24, 6, 4],
    'x': 'RDLDRRUURDDRUUULLLLURRRR',
  },
};
