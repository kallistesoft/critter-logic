// Difficulty curves of the level tracks and the bundled dailies: dart run tools/difficulty_report.dart [--csv out.csv]
// With --typical: the median effort of every spec the ramps use, for the typical*Effort tables in levels.dart.
//
// For levels 1..100 of each game: size, requested and actual tier, solver steps per rule and the estimated human
// effort (lib/puzzles/effort.dart), with the rolling average of the 5 levels before and a flag when a level is
// more than 1.5× that average (a spike). For the bundled dailies: effort per weekday (mean, min, max).
import 'dart:convert';
import 'dart:io';

import 'package:critter_logic/daily.dart';
import 'package:critter_logic/puzzles/effort.dart';
import 'package:critter_logic/puzzles/levels.dart';
import 'package:critter_logic/puzzles/nests/generator.dart';
import 'package:critter_logic/puzzles/nests/nests.dart';
import 'package:critter_logic/puzzles/pairs/generator.dart';
import 'package:critter_logic/puzzles/pairs/pairs.dart';
import 'package:critter_logic/puzzles/trail/generator.dart';
import 'package:critter_logic/puzzles/trail/trail.dart';

const levelCount = 100;
const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

void main(List<String> args) {
  if (args.contains('--typical')) return _typical();
  final csvAt = args.indexOf('--csv');
  final csv = StringBuffer('game,kind,number,size,spec_tier,tier,steps,rules,effort,rolling5,ratio\n');
  final games = <(String, PuzzleSpec Function(int), Effort Function(int), Effort Function(Map<String, dynamic>))>[
    ('nests', nestsLevelSpec, (l) => nestsEffort(generateNestsLevel(l)), (j) => nestsEffort(NestsPuzzle.fromJson(j))),
    ('pairs', pairsLevelSpec, (l) => pairsEffort(generatePairsLevel(l)), (j) => pairsEffort(PairsPuzzle.fromJson(j))),
    ('trail', trailLevelSpec, (l) => trailEffort(generateTrailLevel(l)), (j) => trailEffort(TrailPuzzle.fromJson(j))),
  ];
  for (final (game, spec, level, daily) in games) {
    stdout.writeln('\n== $game levels 1..$levelCount');
    stdout.writeln('level size spec   tier   steps effort  avg5  ratio  rules');
    final efforts = <double>[];
    var spikes = 0;
    for (var l = 1; l <= levelCount; l++) {
      final e = level(l);
      final prev = efforts.length >= 5 ? efforts.sublist(efforts.length - 5) : efforts;
      final avg = prev.isEmpty ? e.score : prev.reduce((a, b) => a + b) / prev.length;
      final ratio = e.score / avg;
      final spike = l > 1 && ratio > 1.5;
      if (spike) spikes++;
      efforts.add(e.score);
      final s = spec(l);
      stdout.writeln(
        '${'$l'.padLeft(5)} ${'${e.size}'.padLeft(4)} ${s.tier.name.padRight(6)} ${e.tier.name.padRight(6)} '
        '${'${e.steps}'.padLeft(5)} ${e.score.toStringAsFixed(1).padLeft(6)} ${avg.toStringAsFixed(1).padLeft(5)} '
        '${ratio.toStringAsFixed(2).padLeft(5)}${spike ? '!' : ' '} ${_rules(e.rules)}${isBreatherLevel(l) ? '  (breather)' : ''}',
      );
      csv.writeln(
        '$game,level,$l,${e.size},${s.tier.name},${e.tier.name},${e.steps},"${_rules(e.rules)}",'
        '${e.score.toStringAsFixed(2)},${avg.toStringAsFixed(2)},${ratio.toStringAsFixed(3)}',
      );
    }
    for (final (from, to) in [(1, 10), (11, 20), (21, 40), (41, 60), (61, 100)]) {
      final part = efforts.sublist(from - 1, to);
      stdout.writeln(
        'levels $from-$to: mean effort ${(part.reduce((a, b) => a + b) / part.length).toStringAsFixed(1)}',
      );
    }
    stdout.writeln('spikes (> 1.5× the 5 before): $spikes');

    final file = File('assets/dailies/$game.json');
    if (!file.existsSync()) continue;
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final first = json['first'] as int;
    final puzzles = (json['puzzles'] as List).cast<Map<String, dynamic>>();
    final byDay = List.generate(7, (_) => <double>[]);
    final tiers = List.generate(7, (_) => List.filled(3, 0));
    for (var i = 0; i < puzzles.length; i++) {
      final number = first + i;
      final e = daily(puzzles[i]);
      final day = dateOfDaily(number).weekday - 1;
      byDay[day].add(e.score);
      tiers[day][e.tier.index]++;
      csv.writeln(
        '$game,daily,$number,${e.size},${weekdays[day]},${e.tier.name},${e.steps},"${_rules(e.rules)}",'
        '${e.score.toStringAsFixed(2)},,',
      );
    }
    stdout.writeln('\n== $game dailies (${puzzles.length}): effort by weekday');
    double? last;
    var monotonic = true;
    for (var d = 0; d < 7; d++) {
      final v = byDay[d]..sort();
      final mean = v.reduce((a, b) => a + b) / v.length;
      if (last != null && mean < last) monotonic = false;
      last = mean;
      stdout.writeln(
        '${weekdays[d]}  mean ${mean.toStringAsFixed(1).padLeft(5)}  min ${v.first.toStringAsFixed(1).padLeft(5)}  '
        'median ${v[v.length ~/ 2].toStringAsFixed(1).padLeft(5)}  max ${v.last.toStringAsFixed(1).padLeft(5)}  '
        'tiers e/m/h ${tiers[d].join('/')}',
      );
    }
    stdout.writeln('weekday means rise Monday to Sunday: $monotonic');
  }
  if (csvAt >= 0 && csvAt + 1 < args.length) {
    File(args[csvAt + 1]).writeAsStringSync(csv.toString());
    stdout.writeln('\nCSV written to ${args[csvAt + 1]}');
  }
}

String _rules(Map<String, int> rules) => [for (final e in rules.entries) '${e.key}:${e.value}'].join(' ');

/// Median effort over 80 seeds of each spec used by levels 1..300 and the dailies.
void _typical() {
  final games = <(String, PuzzleSpec Function(int), PuzzleSpec Function(int), Effort Function(PuzzleSpec, int))>[
    ('nests', nestsLevelSpec, nestsDailySpec, (s, seed) => nestsEffort(NestsGenerator(seed).generate(s.size, s.tier))),
    (
      'pairs',
      pairsLevelSpec,
      pairsDailySpec,
      (s, seed) =>
          pairsEffort(PairsGenerator(seed).generate(s.size, s.tier, minGivens: (s.givens * s.size * s.size).round())),
    ),
    ('trail', trailLevelSpec, trailDailySpec, (s, seed) => trailEffort(TrailGenerator(seed).generate(s.size, s.tier))),
  ];
  for (final (game, level, daily, effort) in games) {
    final specs = {for (var l = 1; l <= 300; l++) level(l), for (var d = 1; d <= 7; d++) daily(d)}.toList()
      ..sort(
        (a, b) => a.size != b.size
            ? a.size - b.size
            : a.tier != b.tier
            ? a.tier.index - b.tier.index
            : a.givens.compareTo(b.givens),
      );
    stdout.writeln('== $game');
    for (final s in specs) {
      final v = [for (var i = 0; i < 80; i++) effort(s, 777000 + i).score]..sort();
      stdout.writeln(
        "  '$s': ${v[40].toStringAsFixed(1)},  // p10 ${v[8].toStringAsFixed(1)} p90 ${v[72].toStringAsFixed(1)}",
      );
    }
  }
}
