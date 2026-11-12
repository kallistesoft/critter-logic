import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';

import 'meta/reminders.dart';
import 'puzzles/bundled_source.dart';
import 'puzzles/source.dart';
import 'services/ad_ids.dart';
import 'services/ad_service.dart';
import 'services/admob_ad_service.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporting.dart';
import 'services/game_settings.dart';
import 'services/leaderboard_service.dart';
import 'services/music_service.dart';
import 'services/premium_service.dart';
import 'services/reminder_service.dart';
import 'services/review_service.dart';
import 'services/sound_service.dart';
import 'services/stats_store.dart';
import 'services/update_service.dart';
import 'ui/home_screen.dart';
import 'ui/meadow.dart';
import 'ui/palette.dart';
import 'ui/services.dart';
import 'ui/update_gate.dart';

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
    }
    review = StoreReviewService();
    reminders = LocalReminderService();
    // Forced/recommended updates use Google Play's in-app update API; the App Store has no equivalent.
    updates?.check();
  }

  final music = kIsWeb ? NoMusic(enabled: stats.musicOn) : AudioMusicService(enabled: stats.musicOn, persist: stats.setMusicOn);
  final l10n = lookupAppLocalizations(
      basicLocaleListResolution(PlatformDispatcher.instance.locales, AppLocalizations.supportedLocales));
  planReminders(stats, reminders, l10n, DateTime.now());
  music.start();

  runApp(CritterLogicApp(
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
  ));
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

  /// Forces a language (tests); null follows the phone, falling back to English.
  final Locale? locale;

  /// Dailies and levels; null uses the built-in development puzzles.
  final PuzzleSource? puzzles;
  final ValueListenable<GameSettings>? settings;
  final MusicService? music;
  final ReminderService reminders;

  @override
  Widget build(BuildContext context) {
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
      banner: banner,
      privacyOptionsRequired: privacyOptionsRequired,
      showPrivacyOptions: showPrivacyOptions,
      today: today,
      child: MaterialApp(
        title: 'Critter Logic',
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: leaf,
          fontFamily: displayFont,
          scaffoldBackgroundColor: Colors.transparent,
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: woodEdge,
            contentTextStyle: const TextStyle(fontFamily: displayFont, fontSize: 16, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        navigatorKey: _navigator,
        builder: (context, child) => MeadowWorld(
          child: updateStatus == null
              ? child!
              : UpdateGate(status: updateStatus!, onUpdate: onUpdate!, navigatorKey: _navigator, child: child!),
        ),
        home: const HomeScreen(),
      ),
    );
  }

  static final _navigator = GlobalKey<NavigatorState>();
}
