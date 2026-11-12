import 'progress_store.dart';
import 'rewards.dart';

/// The default 7-day track. Coins stay small next to [Economy.hintCost] (30): one loop pays 170 coins
/// (about 6 hints), 340 if every coin day is doubled by an ad.
const defaultCalendarRewards = <Reward>[
  Reward.coins(20),
  Reward.coins(60), // "hint pack": two hints' worth
  Reward.capsule(),
  Reward.coins(30),
  Reward.capsule(),
  Reward.coins(60),
  Reward.goldenCapsule(),
];

/// Where the player is on the login calendar today.
class CalendarState {
  const CalendarState({
    required this.step,
    required this.claimedToday,
    required this.available,
    required this.rewards,
    required this.canDouble,
    required this.loops,
  });

  /// 0-based day on the track (0 = day 1): the one to claim today, or the one claimed today.
  final int step;
  final bool claimedToday;

  /// A claim is possible now: not claimed today, and the clock didn't go back before the last claim.
  final bool available;
  final List<Reward> rewards;

  /// Today's reward has coins and the ad double is on: offer "x2 with an ad".
  final bool canDouble;

  /// Full 7-day loops completed.
  final int loops;

  Reward get reward => rewards[step];
}

/// What a calendar claim gave (already doubled when [doubled]); paid by [grantReward].
class CalendarClaim {
  const CalendarClaim({required this.step, required this.reward, required this.doubled});

  final int step;
  final Reward reward;
  final bool doubled;
}

/// A 7-step reward track that moves one step per local calendar day the app is opened and the reward claimed.
/// Missed days don't reset it, the track just waits; after day 7 it loops back to day 1. One claim per local
/// day; a rewarded ad may double a coin reward (the claim itself is the once-a-day limit).
class LoginCalendar {
  LoginCalendar(this._progress, {List<Reward>? rewards, this.adDouble = true})
      : rewards = rewards ?? defaultCalendarRewards,
        assert(rewards == null || rewards.length == length);

  static const length = 7;

  final ProgressStore _progress;
  final List<Reward> rewards;

  /// Remote Config switch for the "x2 with an ad" offer.
  final bool adDouble;

  CalendarState state(DateTime now) {
    final today = localDay(now);
    final last = _progress.calendarLastDay;
    final claims = _progress.calendarClaims;
    final claimedToday = last == today;
    // A clock set back before the last claim must not allow claiming the same days again.
    final available = !claimedToday && (last == null || today > last);
    final step = (claimedToday ? claims - 1 : claims) % length;
    return CalendarState(
      step: step,
      claimedToday: claimedToday,
      available: available,
      rewards: rewards,
      canDouble: available && adDouble && rewards[step].coins > 0,
      loops: claims ~/ length,
    );
  }

  /// Claims today's reward, doubled when [doubled] (after a rewarded ad) and allowed. Null if not available
  /// (already claimed today, or the clock went back).
  Future<CalendarClaim?> claim(DateTime now, {bool doubled = false}) async {
    final s = state(now);
    if (!s.available) return null;
    final double = doubled && s.canDouble;
    await _progress.recordCalendarClaim(localDay(now));
    return CalendarClaim(step: s.step, reward: double ? s.reward.doubled() : s.reward, doubled: double);
  }
}
