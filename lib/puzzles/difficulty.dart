import 'dart:math';

/// How hard a generated puzzle is meant to be.
enum Tier { easy, medium, hard }

/// What a deduction solver found: whether it filled the whole grid, and the rules it needed.
class SolveResult {
  const SolveResult({required this.solved, required this.steps, required this.maxLevel, required this.rules});

  /// Solved by deduction alone, which also proves the solution is unique.
  final bool solved;

  /// Deduction steps taken (each places or rules out one or more cells).
  final int steps;

  /// The hardest rule level used (1 = simplest).
  final int maxLevel;

  /// How many steps each rule id took.
  final Map<String, int> rules;

  int uses(String rule) => rules[rule] ?? 0;

  @override
  String toString() => 'SolveResult(solved: $solved, steps: $steps, maxLevel: $maxLevel, rules: $rules)';
}

/// A [Random] with a fixed algorithm (SplitMix64), so a seed gives the same puzzles on every device and Dart
/// version. dart:math's seeded Random is not guaranteed to stay the same across SDK releases.
class SeededRandom implements Random {
  SeededRandom(int seed) : _state = seed;

  int _state;

  int _next() {
    _state += 0x9E3779B97F4A7C15;
    var z = _state;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
    return z ^ (z >>> 31);
  }

  @override
  int nextInt(int max) {
    if (max <= 0) throw RangeError.range(max, 1, null, 'max');
    return (_next() >>> 1) % max;
  }

  @override
  double nextDouble() => (_next() >>> 11) / (1 << 53);

  @override
  bool nextBool() => _next() < 0;
}

/// Mixes [parts] into one non-negative seed, stable across platforms (no String.hashCode).
int mixSeed(List<int> parts) {
  var h = 0x2545F4914F6CDD1D;
  for (final p in parts) {
    h ^= p;
    h *= 0x100000001B3;
    h ^= h >>> 29;
  }
  return h & 0x7FFFFFFFFFFF;
}

/// Shuffles [list] in place with [rnd] (Fisher-Yates; List.shuffle's algorithm is not part of its contract).
void shuffleWith<T>(List<T> list, Random rnd) {
  for (var i = list.length - 1; i > 0; i--) {
    final j = rnd.nextInt(i + 1);
    final t = list[i];
    list[i] = list[j];
    list[j] = t;
  }
}

int popCount(int x) {
  var c = 0;
  while (x != 0) {
    x &= x - 1;
    c++;
  }
  return c;
}
