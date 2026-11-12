/// Trail: draw one path through every cell of the grid, moving up, down, left or right. It starts on stone 1, ends on
/// the last stone, passes the stones in order and never crosses a wall.
class TrailPuzzle {
  TrailPuzzle({required this.size, required this.stones, this.walls = const [], required this.solution})
    : assert(stones.length >= 2),
      assert(solution.length == size * size),
      assert(solution.first == stones.first && solution.last == stones.last);

  final int size;

  /// The cell of each stone in order: stones[0] holds 1, stones[k - 1] holds k.
  final List<int> stones;

  /// Walls between two side-by-side cells, as (smaller cell, larger cell).
  final List<(int, int)> walls;

  /// The cells in path order.
  final List<int> solution;

  int get cellCount => size * size;

  /// The number on each cell (1-based), or null.
  late final Map<int, int> numbers = {for (var i = 0; i < stones.length; i++) stones[i]: i + 1};

  late final Set<int> _wallKeys = {for (final (a, b) in walls) _key(a, b)};

  int _key(int a, int b) => a < b ? a * cellCount + b : b * cellCount + a;

  bool hasWall(int a, int b) => _wallKeys.contains(_key(a, b));

  /// Side-by-side cells.
  bool adjacent(int a, int b) {
    final n = size;
    final ra = a ~/ n, ca = a % n, rb = b ~/ n, cb = b % n;
    return (ra == rb && (ca - cb).abs() == 1) || (ca == cb && (ra - rb).abs() == 1);
  }

  /// A legal single move: side by side and no wall between.
  bool canStep(int a, int b) => adjacent(a, b) && !hasWall(a, b);

  /// Compact form: stones as a cell list, walls as [a, b] pairs, the solution as moves (U/D/L/R) from stone 1.
  Map<String, dynamic> toJson() => {
    's': size,
    'n': stones,
    if (walls.isNotEmpty)
      'w': [
        for (final (a, b) in walls) [a, b],
      ],
    'x': _moves(),
  };

  String _moves() {
    final out = StringBuffer();
    for (var i = 1; i < solution.length; i++) {
      final d = solution[i] - solution[i - 1];
      out.write(
        d == 1
            ? 'R'
            : d == -1
            ? 'L'
            : d == size
            ? 'D'
            : 'U',
      );
    }
    return out.toString();
  }

  static TrailPuzzle fromJson(Map<String, dynamic> json) {
    final size = json['s'] as int;
    final stones = (json['n'] as List).cast<int>();
    final path = [stones.first];
    for (final m in (json['x'] as String).split('')) {
      path.add(
        path.last +
            switch (m) {
              'R' => 1,
              'L' => -1,
              'D' => size,
              _ => -size,
            },
      );
    }
    return TrailPuzzle(
      size: size,
      stones: List.unmodifiable(stones),
      walls: [for (final w in (json['w'] as List? ?? const [])) ((w as List)[0] as int, w[1] as int)],
      solution: path,
    );
  }
}

/// Why a step of a drawn path is wrong.
enum TrailError {
  /// The path doesn't start on stone 1.
  start,

  /// Not side by side with the cell before.
  jump,

  /// Through a wall.
  wall,

  /// A cell the path already went through.
  revisit,

  /// A stone reached before the stones below it.
  order,

  /// A step past the last stone (the path must end there).
  end,
}

class TrailRules {
  const TrailRules(this.puzzle);

  final TrailPuzzle puzzle;

  /// The first broken step of [path] (its index and why), or null when the whole path is legal so far.
  (int, TrailError)? firstError(List<int> path) {
    final numbers = puzzle.numbers;
    final seen = <int>{};
    var next = 1;
    for (var i = 0; i < path.length; i++) {
      final cell = path[i];
      if (i == 0 && cell != puzzle.stones.first) return (0, TrailError.start);
      if (i > 0) {
        if (path[i - 1] == puzzle.stones.last) return (i, TrailError.end);
        if (!puzzle.adjacent(path[i - 1], cell)) return (i, TrailError.jump);
        if (puzzle.hasWall(path[i - 1], cell)) return (i, TrailError.wall);
      }
      if (!seen.add(cell)) return (i, TrailError.revisit);
      final number = numbers[cell];
      if (number != null) {
        if (number != next) return (i, TrailError.order);
        next++;
      }
    }
    return null;
  }

  /// Cells of [path] from its first broken step on (for the UI to mark); empty when the path is legal so far.
  Set<int> conflicts(List<int> path) {
    final error = firstError(path);
    return error == null ? const {} : path.sublist(error.$1).toSet();
  }

  /// Whether [path] is legal so far, so the player may keep drawing from its end.
  bool isValid(List<int> path) => firstError(path) == null;

  /// Whether a legal [path] can grow by [cell].
  bool canExtend(List<int> path, int cell) => isValid([...path, cell]);

  /// Every cell once, legal, ending on the last stone (which, with the order rule, means every stone in order).
  bool isSolved(List<int> path) =>
      path.length == puzzle.cellCount && path.last == puzzle.stones.last && firstError(path) == null;
}
