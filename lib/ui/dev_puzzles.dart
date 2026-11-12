import '../puzzles/nests/nests.dart';
import '../puzzles/pairs/pairs.dart';
import '../puzzles/levels.dart';
import '../puzzles/source.dart';
import '../puzzles/trail/trail.dart';

/// A few hand-checked puzzles (unique solutions) to run the app before the bundled source lands.
class DevPuzzleSource implements PuzzleSource {
  const DevPuzzleSource();

  static final _nests = [
    for (final (s, r, x) in const [
      (4, '0122022202330333', '1302'),
      (5, '0001100211222213222432244', '14203'),
      (6, '000001000001200031224444255444255444', '524031'),
      (5, '0011200312003220032243322', '31420'),
      (6, '011222111222333322333322333345333444', '024153'),
    ])
      NestsPuzzle.fromJson({'s': s, 'r': r, 'x': x}),
  ];

  static final _pairs = [
    PairsPuzzle.fromJson(const {
      's': 4,
      'g': '0.0...0.........',
      'l': [
        [0, 4, 1]
      ],
      'x': '0101010110101010',
    }),
    PairsPuzzle.fromJson(const {
      's': 6,
      'g': '.....................1.............1',
      'l': [
        [23, 29, 1],
        [11, 17, 0],
        [4, 10, 0],
        [0, 6, 1],
        [2, 3, 1]
      ],
      'x': '001101010110101001010110110010101001',
    }),
    PairsPuzzle.fromJson(const {
      's': 4,
      'g': '.1..............',
      'l': [
        [0, 1, 0],
        [11, 15, 0],
        [5, 9, 1],
        [0, 4, 1]
      ],
      'x': '0110001110011100',
    }),
    PairsPuzzle.fromJson(const {
      's': 6,
      'g': '.........0....1.....................',
      'l': [
        [0, 6, 0],
        [9, 15, 0],
        [2, 3, 0],
        [17, 23, 1],
        [28, 34, 1],
        [8, 9, 0],
        [27, 33, 0]
      ],
      'x': '010110101010001101010011110100101001',
    }),
  ];

  @override
  Future<NestsPuzzle> dailyNests(int number) async => _nests[(number + 1) % _nests.length];

  @override
  Future<PairsPuzzle> dailyPairs(int number) async => _pairs[(number + 1) % _pairs.length];

  @override
  Future<NestsPuzzle> levelNests(int level) async => _nests[(level - 1) % _nests.length];

  @override
  Future<PairsPuzzle> levelPairs(int level) async => _pairs[(level - 1) % _pairs.length];

  // Trail puzzles are quick to make: the real generator.
  @override
  Future<TrailPuzzle> dailyTrail(int number) async => generateTrailDaily(number);

  @override
  Future<TrailPuzzle> levelTrail(int level) async => generateTrailLevel(level);
}
