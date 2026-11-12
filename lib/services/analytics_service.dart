import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Gameplay events, measured to see where players stay or leave. No personal data: games, levels, times, counts.
/// Event names are the ones in the plan, so the GA4 dashboards match Unarrow's.
abstract class AnalyticsService {
  Future<void> log(String name, [Map<String, Object> params = const {}]);

  /// Who the player is now (user properties): progress and streak.
  Future<void> setUserState({required int levelsWon, required int streak});

  // Shorthands for the plan's events.
  Future<void> levelStart(String game, {required bool daily, int? level}) =>
      log('level_start', {'game': game, 'daily': daily ? 1 : 0, 'level': ?level});

  Future<void> levelComplete(String game,
          {required bool daily, int? level, required int seconds, required int mistakes, required int hints}) =>
      log('level_complete', {
        'game': game,
        'daily': daily ? 1 : 0,
        'level': ?level,
        'seconds': seconds,
        'mistakes': mistakes,
        'hints': hints,
      });

  /// [paidWith]: 'coins' or 'ad'.
  Future<void> hintUsed(String game, {required String paidWith}) => log('hint_used', {'game': game, 'paid_with': paidWith});

  /// [reward]: 'hint', 'coins', 'capsule' or 'repair'.
  Future<void> adReward(String reward) => log('ad_reward', {'reward': reward});

  Future<void> capsuleOpen({required String rarity, required bool duplicate}) =>
      log('capsule_open', {'rarity': rarity, 'duplicate': duplicate ? 1 : 0});

  Future<void> share({required bool daily}) => log('share', {'daily': daily ? 1 : 0});

  Future<void> tutorialDone(String game) => log('tutorial_done', {'game': game});
}

/// Web and tests: events are kept in memory.
class NoAnalytics extends AnalyticsService {
  final events = <(String, Map<String, Object>)>[];

  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) async => events.add((name, params));

  @override
  Future<void> setUserState({required int levelsWon, required int streak}) async {}
}

/// Google Analytics for Firebase. Collection follows the consent mode set in AdMob's consent form.
class FirebaseAnalyticsService extends AnalyticsService {
  final _analytics = FirebaseAnalytics.instance;

  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('analytics: $e');
    }
  }

  @override
  Future<void> setUserState({required int levelsWon, required int streak}) async {
    try {
      await _analytics.setUserProperty(name: 'levels_won', value: '$levelsWon');
      await _analytics.setUserProperty(name: 'streak', value: '$streak');
    } catch (e) {
      debugPrint('analytics: $e');
    }
  }
}
