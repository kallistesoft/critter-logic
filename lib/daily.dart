/// Daily puzzles change at the player's local midnight (Wordle model): daily #1 is [dailyEpoch].
///
/// Dates are compared as calendar days in UTC, so a daylight saving change never skips or repeats a number.
final dailyEpoch = DateTime.utc(2026, 12, 1);

/// The daily number for the local calendar date of [now]; 1 on [dailyEpoch], below 1 before it.
int dailyNumberFor(DateTime now) => DateTime.utc(now.year, now.month, now.day).difference(dailyEpoch).inDays + 1;

/// The local calendar date of daily [number].
DateTime dateOfDaily(int number) => dailyEpoch.add(Duration(days: number - 1));
