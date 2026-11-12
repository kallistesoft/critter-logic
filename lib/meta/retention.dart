import 'dart:math';

import '../puzzles/puzzle.dart';
import '../services/analytics_service.dart';
import '../services/retention_settings.dart';
import '../services/stats_store.dart';
import 'achievements.dart';
import 'album.dart';
import 'login_calendar.dart';
import 'progress_store.dart';
import 'rewards.dart';
import 'lucky_nest.dart';
import 'shop.dart';
import 'weekly_event.dart';

/// Something the player did that the retention systems count. Passed to [Retention.recordEvent].
sealed class RetentionEvent {
  const RetentionEvent();
}

/// A daily solved for the first time: call only when [StatsStore.recordDaily] returned true, after
/// [grantDailyRewards] (so the streak is up to date).
class DailySolved extends RetentionEvent {
  const DailySolved(this.result);

  final DailyResult result;
}

/// A level won (any attempt that pays the level reward).
class LevelWon extends RetentionEvent {
  const LevelWon(this.kind, {required this.hints});

  final GameKind kind;
  final int hints;
}

/// The share sheet completed (a result or the app was shared).
class Shared extends RetentionEvent {
  const Shared();
}

/// A capsule was opened (after the critter or the duplicate coins were paid).
class CapsuleOpened extends RetentionEvent {
  const CapsuleOpened();
}

/// What a [Retention.recordEvent] changed, for toasts and badges.
class RetentionUpdate {
  const RetentionUpdate({this.tokens = 0, this.thresholdsReached = const [], this.newAchievements = const []});

  /// Event tokens earned by this event.
  final int tokens;

  /// Weekly event thresholds just crossed ("Prize ready!").
  final List<int> thresholdsReached;

  /// Achievements with a claimable tier not announced before ("Trophy unlocked!").
  final List<AchievementProgress> newAchievements;
}

/// The login calendar, achievements and weekly events behind one object, so the UI and the game flow only call
/// a few hooks (see docs/RETENTION.md). Rewards are paid into [stats]; analytics events are logged here.
class Retention {
  Retention({
    required this.stats,
    required this.progress,
    this.settings = const RetentionSettings(),
    AnalyticsService? analytics,
    Random? random,
  })  : analytics = analytics ?? NoAnalytics(),
        _random = random ?? Random();

  final StatsStore stats;
  final ProgressStore progress;
  final RetentionSettings settings;
  final AnalyticsService analytics;
  final Random _random;

  LoginCalendar get calendar =>
      LoginCalendar(progress, rewards: settings.calendarRewards, adDouble: settings.calendarAdDouble);
  Achievements get achievements => Achievements(stats, progress, coins: settings.achievementCoins);
  WeeklyEvent get event => WeeklyEvent(progress, settings: settings.events);
  LuckyNest get luckyNest => LuckyNest(stats, progress, settings: settings.lucky, analytics: analytics, random: _random);
  Shop get shop => Shop(stats, progress, settings: settings.shop, analytics: analytics);

  // ---- App open ----

  /// On app open / resume: true the first time each local day while today's calendar reward is unclaimed.
  /// Marks the day as shown, so the popup comes at most once a day (the calendar stays reachable from home).
  Future<bool> shouldShowCalendar(DateTime now) async {
    final today = localDay(now);
    if (progress.calendarShownDay == today || !calendar.state(now).available) return false;
    await progress.setCalendarShownDay(today);
    return true;
  }

  // ---- Claims ----

  /// Claims and pays today's calendar reward ([doubled] after a rewarded ad was watched). Null if not available.
  Future<GrantResult?> claimCalendar(DateTime now, {bool doubled = false}) async {
    final claim = await calendar.claim(now, doubled: doubled);
    if (claim == null) return null;
    final result = await grantReward(stats, progress, claim.reward);
    await analytics.log('calendar_claim', {
      'day': claim.step + 1,
      'reward': claim.reward.kind,
      'coins': claim.reward.coins,
      'doubled': claim.doubled ? 1 : 0,
    });
    return result;
  }

  /// Claims an achievement tier; returns the coins paid or null.
  Future<int?> claimAchievement(String id, Tier tier) async {
    final coins = await achievements.claim(id, tier);
    if (coins != null) await analytics.log('achievement_claim', {'id': id, 'tier': tier.name, 'coins': coins});
    return coins;
  }

  /// Claims and pays this week's prize for [threshold]; null if not claimable.
  Future<GrantResult?> claimEventPrize(DateTime now, int threshold) async {
    final ev = event;
    final s = ev.current(now);
    final reward = await ev.claim(now, threshold, stats.owned, _random);
    if (s == null || reward == null) return null;
    final result = await grantReward(stats, progress, reward);
    if (threshold == s.thresholds.last) await progress.increment(Counter.eventsCompleted);
    await analytics.log('event_prize_claim', {
      'theme': s.theme.id,
      'week': s.weekId,
      'threshold': threshold,
      'reward': reward.kind,
    });
    return result;
  }

  // ---- Game flow hook ----

  /// Counts [event] for achievements and the weekly event. See docs/RETENTION.md for where to call it.
  Future<RetentionUpdate> recordEvent(RetentionEvent event, DateTime now) async {
    var tokens = 0;
    switch (event) {
      case DailySolved(:final result):
        if (result.hints == 0) await progress.increment(Counter.noHintSolves);
        if (result.hints == 0 && result.mistakes == 0) await progress.increment(Counter.perfectDailies);
        if (result.millis < fastDailyMillis) {
          await progress.increment(result.kind == GameKind.nests ? Counter.fastNests : Counter.fastPairs);
        }
        if (stats.allDailiesDone(result.number)) await progress.increment(Counter.bothDailiesDays);
        tokens = settings.events.tokensPerDaily;
      case LevelWon(:final hints):
        if (hints == 0) await progress.increment(Counter.noHintSolves);
        tokens = settings.events.tokensPerLevel;
      case Shared():
        await progress.increment(Counter.shares);
      case CapsuleOpened():
        await progress.increment(Counter.capsulesOpened);
    }
    final reached = await this.event.addTokens(now, tokens);
    if (reached.isNotEmpty) {
      final s = this.event.current(now)!;
      for (final t in reached) {
        await analytics.log('event_threshold', {'theme': s.theme.id, 'week': s.weekId, 'threshold': t});
      }
    }
    final fresh = await announceAchievements();
    return RetentionUpdate(
      tokens: settings.events.enabled ? tokens : 0,
      thresholdsReached: reached,
      newAchievements: fresh,
    );
  }

  /// Achievements with a claimable tier the player wasn't told about yet; marks them as told. [recordEvent] calls
  /// it; call it too after something else that moves a metric (a capsule adding a critter is covered by
  /// [CapsuleOpened]).
  Future<List<AchievementProgress>> announceAchievements() async {
    final announced = progress.achievementsAnnounced;
    final fresh = <AchievementProgress>[];
    final now = <String>{};
    for (final a in achievements.evaluate()) {
      final keys = {for (final t in a.claimable) '${a.def.id}:${t.index}'};
      now.addAll(keys);
      if (!announced.containsAll(keys)) fresh.add(a);
    }
    // Keep claimed tiers out of the set, so it stays small.
    if (fresh.isNotEmpty || !now.containsAll(announced)) await progress.setAchievementsAnnounced(now);
    return fresh;
  }

  /// Album critter count, for the event banner's "x/6 of this set".
  int ownedInSet(String set) => album.where((c) => c.set == set && stats.owned.contains(c.id)).length;
}
