/// The logic games in the app. Each has a daily puzzle and an endless level track.
enum GameKind { nests, pairs, trail }

/// A cell index on a square grid of side [size], row-major.
int cellIndex(int size, int row, int col) => row * size + col;
