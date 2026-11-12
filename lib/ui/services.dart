import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../meta/progress_store.dart';
import '../meta/retention.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/coin_store_service.dart';
import '../services/game_settings.dart';
import '../services/leaderboard_service.dart';
import '../services/music_service.dart';
import '../services/reminder_service.dart';
import '../services/premium_service.dart';
import '../services/review_service.dart';
import '../services/sound_service.dart';
import '../services/stats_store.dart';
import '../puzzles/source.dart';
import 'dev_puzzles.dart';

/// App-wide services, available to every screen.
class Services extends InheritedWidget {
  Services({
    super.key,
    required this.stats,
    required this.ads,
    required this.sound,
    required this.today,
    PremiumService? premium,
    PuzzleSource? puzzles,
    AnalyticsService? analytics,
    ValueListenable<GameSettings>? settings,
    MusicService? music,
    ValueListenable<Retention>? retention,
    CoinStoreService? coinStore,
    this.reminders = const NoReminders(),
    this.review = const NoReviewService(),
    this.leaderboard = const NoLeaderboardService(),
    this.banner,
    this.privacyOptionsRequired,
    this.showPrivacyOptions,
    required super.child,
  })  : premium = premium ?? NoPremiumService(),
        analytics = analytics ?? NoAnalytics(),
        puzzles = puzzles ?? const DevPuzzleSource(),
        settings = settings ?? ValueNotifier(const GameSettings()),
        music = music ?? NoMusic(),
        coinStore = coinStore ?? NoCoinStore(),
        retentionListenable = retention ??
            ValueNotifier(Retention(stats: stats, progress: ProgressStore(stats.prefs), analytics: analytics));

  final StatsStore stats;
  final AdService ads;
  final SoundService sound;
  final PremiumService premium;
  final AnalyticsService analytics;
  final ReviewService review;
  final LeaderboardService leaderboard;

  /// Remote Config tuning (ad pacing, capsule odds); the shipped defaults until it loads.
  final ValueListenable<GameSettings> settings;
  final MusicService music;
  final ReminderService reminders;

  /// Login calendar, trophies, weekly event, shop, Lucky Nest; replaced when Remote Config brings new settings.
  final ValueListenable<Retention> retentionListenable;
  Retention get retention => retentionListenable.value;

  /// Coin packs on the store; [NoCoinStore] (no packs) on web and in tests.
  final CoinStoreService coinStore;

  /// Dailies and level tracks.
  final PuzzleSource puzzles;

  /// Banner ad at the bottom of the screen; null where there are no banners (web, tests).
  final WidgetBuilder? banner;

  /// Consent form re-entry point (required by AdMob where consent applies); null without ads.
  final ValueListenable<bool>? privacyOptionsRequired;
  final VoidCallback? showPrivacyOptions;

  /// Injectable clock for the daily puzzle.
  final DateTime Function() today;

  static Services of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Services>()!;

  @override
  bool updateShouldNotify(Services old) =>
      old.stats != stats ||
      old.ads != ads ||
      old.sound != sound ||
      old.premium != premium ||
      old.review != review ||
      old.leaderboard != leaderboard ||
      old.analytics != analytics ||
      old.puzzles != puzzles ||
      old.settings != settings ||
      old.music != music ||
      old.reminders != reminders ||
      old.retentionListenable != retentionListenable ||
      old.coinStore != coinStore ||
      old.banner != banner;
}
