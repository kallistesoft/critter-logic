import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';

import 'meta/progress_store.dart';
import 'meta/reminders.dart';
import 'meta/retention.dart';
import 'meta/shop.dart';
import 'puzzles/bundled_source.dart';
import 'puzzles/source.dart';
import 'services/ad_ids.dart';
import 'services/ad_service.dart';
import 'services/admob_ad_service.dart';
import 'services/analytics_service.dart';
import 'services/coin_store_service.dart';
import 'services/crash_reporting.dart';
import 'services/game_settings.dart';
import 'services/leaderboard_service.dart';
import 'services/music_service.dart';
import 'services/premium_service.dart';
import 'services/reminder_service.dart';
import 'services/retention_settings.dart';
import 'services/review_service.dart';
import 'services/sound_service.dart';
import 'services/stats_store.dart';
import 'services/update_service.dart';
import 'ui/home_screen.dart';
import 'ui/meadow.dart';
import 'ui/services.dart';
import 'ui/update_gate.dart';
import 'ui/worlds/welcome_world_screen.dart';
import 'ui/worlds/world.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final stats = await StatsStore.open();
  final firstLaunch = stats.firstLaunch();

  // Ads, the "Remove Ads" purchase and Firebase on phones; the web build stays ad-free.
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final mobile = android || (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);
  AdService ads = const NoAdService();
  PremiumService premium = NoPremiumService();
  WidgetBuilder? banner;
  ValueListenable<bool>? privacyOptionsRequired;
  VoidCallback? showPrivacyOptions;
  UpdateService? updates;
  ReviewService review = const NoReviewService();
  LeaderboardService leaderboard = const NoLeaderboardService();
  AnalyticsService? analytics;
  ReminderService reminders = const NoReminders();
  CoinStoreService coinStore = NoCoinStore();
  // Remote Config tuning; Android reads it with the update check, other platforms keep the defaults.
  ValueListenable<GameSettings> settings = ValueNotifier(const GameSettings());
  if (android) {
    updates = UpdateService();
    settings = updates.settings;
  }
  if (mobile) {
    try {
      await initCrashReporting();
      await initAppCheck();
      leaderboard = BackendLeaderboardService(FirestoreLeaderboardBackend());
      analytics = FirebaseAnalyticsService();
    } catch (_) {
      // Never block the game because Firebase couldn't start.
    }
    // Without ad units (iOS release before its AdMob app exists) there are no ads, so nothing to remove either.
    if (AdIds.configured) {
      final admob = AdMobAdService();
      final store = StorePremiumService(stats);
      premium = store;
      final capped = FrequencyCappedAdService(admob, firstLaunch: firstLaunch);
      void applySettings() => capped.gap = Duration(seconds: settings.value.interstitialGapSeconds);
      applySettings();
      settings.addListener(applySettings);
      // Remove Ads, or the Remote Config kill switch, stops interstitials and banners; rewarded ads stay.
      ads = PremiumAwareAdService(capped, () => store.isPremium || !settings.value.adsEnabled);
      banner = (_) => ValueListenableBuilder(
        valueListenable: settings,
        builder: (_, s, _) => s.adsEnabled ? admob.banner() : const SizedBox.shrink(),
      );
      privacyOptionsRequired = admob.privacyOptionsRequired;
      showPrivacyOptions = admob.showPrivacyOptions;
      admob.init();
      store.init();
      final coins = StoreCoinService(stats, stats.prefs, analytics: analytics);
      coinStore = coins;
      coins.init();
    }
    review = StoreReviewService();
    reminders = LocalReminderService();
    // Forced/recommended updates use Google Play's in-app update API; the App Store has no equivalent.
    updates?.check();
  }

  // Calendar, trophies, weekly event, shop and Lucky Nest. Rebuilt with the new tuning when Remote Config loads.
  final progress = await ProgressStore.open();
  Retention makeRetention() => Retention(
    stats: stats,
    progress: progress,
    settings: updates?.retention.value ?? const RetentionSettings(),
    analytics: analytics,
  );
  final retention = ValueNotifier(makeRetention());
  updates?.retention.addListener(() => retention.value = makeRetention());

  final music = kIsWeb
      ? NoMusic(enabled: stats.musicOn)
      : AudioMusicService(enabled: stats.musicOn, persist: stats.setMusicOn);
  // The language picked in Settings, else the phone's.
  final chosen = stats.language;
  final l10n = lookupAppLocalizations(
    chosen != null
        ? Locale(chosen)
        : basicLocaleListResolution(PlatformDispatcher.instance.locales, AppLocalizations.supportedLocales),
  );
  planReminders(stats, reminders, l10n, DateTime.now());
  music.start();

  runApp(
    CritterLogicApp(
      stats: stats,
      ads: ads,
      analytics: analytics,
      premium: premium,
      review: review,
      leaderboard: leaderboard,
      banner: banner,
      privacyOptionsRequired: privacyOptionsRequired,
      showPrivacyOptions: showPrivacyOptions,
      updateStatus: updates?.status,
      onUpdate: updates?.update,
      sound: AudioSoundService(muted: stats.muted, persist: stats.setMuted),
      puzzles: BundledPuzzleSource(),
      settings: settings,
      music: music,
      reminders: reminders,
      retention: retention,
      coinStore: coinStore,
    ),
  );
}

class CritterLogicApp extends StatelessWidget {
  const CritterLogicApp({
    super.key,
    required this.stats,
    required this.ads,
    required this.sound,
    this.premium,
    this.analytics,
    this.review = const NoReviewService(),
    this.leaderboard = const NoLeaderboardService(),
    this.banner,
    this.privacyOptionsRequired,
    this.showPrivacyOptions,
    this.updateStatus,
    this.onUpdate,
    this.today = DateTime.now,
    this.locale,
    this.puzzles,
    this.settings,
    this.music,
    this.reminders = const NoReminders(),
    this.retention,
    this.coinStore,
  });

  final StatsStore stats;
  final AdService ads;
  final SoundService sound;
  final PremiumService? premium;
  final AnalyticsService? analytics;
  final ReviewService review;
  final LeaderboardService leaderboard;
  final WidgetBuilder? banner;
  final ValueListenable<bool>? privacyOptionsRequired;
  final VoidCallback? showPrivacyOptions;

  /// Force / recommended update from Remote Config; null where it isn't wired (web, tests).
  final ValueListenable<UpdateStatus>? updateStatus;
  final VoidCallback? onUpdate;
  final DateTime Function() today;

  /// Forces a language (tests); null uses the one picked in Settings ([StatsStore.language]), else the phone's,
  /// falling back to English.
  final Locale? locale;

  /// Dailies and levels; null uses the built-in development puzzles.
  final PuzzleSource? puzzles;
  final ValueListenable<GameSettings>? settings;
  final MusicService? music;
  final ReminderService reminders;

  /// Retention systems; null builds one on [stats]' preferences with the default settings (web, tests).
  final ValueListenable<Retention>? retention;

  /// Coin packs; null = none (web, tests).
  final CoinStoreService? coinStore;

  @override
  Widget build(BuildContext context) {
    final progress = retention?.value.progress ?? ProgressStore(stats.prefs);
    return Services(
      stats: stats,
      ads: ads,
      sound: sound,
      premium: premium,
      analytics: analytics,
      review: review,
      leaderboard: leaderboard,
      puzzles: puzzles,
      settings: settings,
      music: music,
      reminders: reminders,
      retention: retention,
      coinStore: coinStore,
      banner: banner,
      privacyOptionsRequired: privacyOptionsRequired,
      showPrivacyOptions: showPrivacyOptions,
      today: today,
      child: WorldHost(
        initial: worldById(Shop(stats, progress).equippedWorld),
        builder: (context, world) => ValueListenableBuilder(
          valueListenable: stats.languageChanges,
          builder: (context, language, _) => MaterialApp(
            title: 'Critter Logic',
            debugShowCheckedModeBanner: false,
            locale: locale ?? (language == null ? null : Locale(language)),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              useMaterial3: true,
              brightness: world.brightness,
              colorSchemeSeed: world.palette.leaf,
              fontFamily: world.font,
              scaffoldBackgroundColor: Colors.transparent,
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: world.palette.woodEdge,
                contentTextStyle: TextStyle(fontFamily: world.font, fontSize: 16, color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            navigatorKey: _navigator,
            builder: (context, child) => WorldBackdrop(
              child: updateStatus == null
                  ? child!
                  : UpdateGate(status: updateStatus!, onUpdate: onUpdate!, navigatorKey: _navigator, child: child!),
            ),
            // The World picker greets new players once (and players updating to the version with Worlds).
            home: progress.worldChosen ? const HomeScreen() : const WelcomeWorldScreen(),
          ),
        ),
      ),
    );
  }

  static final _navigator = GlobalKey<NavigatorState>();
}
