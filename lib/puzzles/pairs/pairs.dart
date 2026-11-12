import '../puzzle.dart';

/// Sun and moon, the two symbols of Pairs.
const sun = 0;
const moon = 1;

/// A clue between two side-by-side cells: [same] (=) or opposite (×).
class PairsLink {
  const PairsLink(this.a, this.b, {required this.same});

  final int a;
  final int b;
  final bool same;

  List<int> toJson() => [a, b, same ? 1 : 0];

  static PairsLink fromJson(List<dynamic> json) => PairsLink(json[0] as int, json[1] as int, same: json[2] == 1);
}

/// Pairs: fill every cell with a sun or a moon. Each row and column holds as many suns as moons,
/// never three of a kind in a row, and the =/× links between cells hold.
class PairsPuzzle {
  PairsPuzzle({required this.size, required this.givens, required this.links, required this.solution})
      : assert(size.isEven),
        assert(givens.length == size * size && solution.length == size * size);

  final int size;

  /// Fixed symbols shown at the start (null = for the player to fill).
  final List<int?> givens;
  final List<PairsLink> links;
  final List<int> solution;

  Map<String, dynamic> toJson() => {
        's': size,
        'g': [for (final g in givens) g == null ? '.' : '$g'].join(),
        'l': [for (final l in links) l.toJson()],
        'x': solution.join(),
      };

  static PairsPuzzle fromJson(Map<String, dynamic> json) => PairsPuzzle(
        size: json['s'] as int,
        givens: [for (final c in (json['g'] as String).split('')) c == '.' ? null : int.parse(c)],
        links: [for (final l in json['l'] as List) PairsLink.fromJson(l as List)],
        solution: [for (final c in (json['x'] as String).split('')) int.parse(c)],
      );
}

class PairsRules {
  const PairsRules(this.puzzle);

  final PairsPuzzle puzzle;

  /// Cells that break a rule: three in a row, a full line with unequal counts or a line with more than half of
  /// one symbol, or a broken link.
  Set<int> conflicts(List<int?> cells) {
    final n = puzzle.size;
    final bad = <int>{};
    for (var line = 0; line < n; line++) {
      for (final horizontal in [true, false]) {
        final idx = [for (var k = 0; k < n; k++) horizontal ? cellIndex(n, line, k) : cellIndex(n, k, line)];
        for (var k = 0; k + 2 < n; k++) {
          final v = cells[idx[k]];
          if (v != null && cells[idx[k + 1]] == v && cells[idx[k + 2]] == v) bad.addAll(idx.sublist(k, k + 3));
        }
        for (final symbol in [sun, moon]) {
          final mine = idx.where((i) => cells[i] == symbol).toList();
          if (mine.length > n ~/ 2) bad.addAll(mine);
        }
      }
    }
    for (final l in puzzle.links) {
      final a = cells[l.a], b = cells[l.b];
      if (a != null && b != null && (a == b) != l.same) bad.addAll([l.a, l.b]);
    }
    return bad;
  }

  bool isSolved(List<int?> cells) => !cells.contains(null) && conflicts(cells).isEmpty;
}
