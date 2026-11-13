// Store-promo entry point: the real app on a staged save, for the Play screenshots and promo videos.
//
//   flutter build apk --profile -t tools/promo_main.dart
//   adb shell am start -n ca.kallistesoft.critterlogic.dev/ca.kallistesoft.critterlogic.MainActivity \
//       --esal dart_entrypoint_args reset=true,lang=fr,world=world.lodge
//
// Not shipped. Settings come as `key=value` launch arguments: lang=en|fr|es, world=world.lodge, reset=true,
// calendar=true (let the daily-gift popup open), hat=hat.crown, seed=3 (repeatable Lucky Nest draws), daily=40 (stage
// another daily than #13), boards=false (no ranking at all, for tools/daily_shorts.py). With reset=true
// (or on the first launch) the save is wiped and re-seeded: a 12-day streak, 1,240 coins, 22 of 30 critters (some at
// ⭐3–5), levels with stars, trophies, a weekly event under way, two capsules to open and the free Lucky Nest egg. The
// date is moved to daily #13 (keeping the time of day) and the boards are a local stand-in with a few thousand
// players, so the "faster than X%" line shows. No ads at all (the "No ads" purchase reads as owned) and no Firebase.
// See store/README.md.
import 'dart:math';

import 'package:critter_logic/daily.dart';
import 'package:critter_logic/main.dart';
import 'package:critter_logic/meta/onboarding.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/meta/retention.dart';
import 'package:critter_logic/meta/weekly_event.dart';
import 'package:critter_logic/puzzles/bundled_source.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/ad_service.dart';
import 'package:critter_logic/services/coin_store_service.dart';
import 'package:critter_logic/services/leaderboard_service.dart';
import 'package:critter_logic/services/music_service.dart';
import 'package:critter_logic/services/premium_service.dart';
import 'package:critter_logic/services/sound_service.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The staged day: daily #13 by default (daily=N picks another), with the 12 days before it a streak and today's
/// puzzles still to play.
var promoDaily = 13;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final config = <String, dynamic>{
    for (final a in args)
      if (a.contains('='))
        a.substring(0, a.indexOf('=')): switch (a.substring(a.indexOf('=') + 1)) {
          'true' => true,
          'false' => false,
          final v => v,
        },
  };

  promoDaily = int.tryParse('${config['daily'] ?? ''}') ?? promoDaily;
  final now = DateTime.now();
  final day = dateOfDaily(promoDaily);
  final offset = DateTime(day.year, day.month, day.day).difference(DateTime(now.year, now.month, now.day));
  DateTime today() => DateTime.now().add(offset);

  final prefs = await SharedPreferences.getInstance();
  if (config['reset'] == true || !(prefs.getBool('promo.seeded') ?? false)) {
    await prefs.clear();
    await seed(prefs, config, today());
  }
  final lang = config['lang'] as String?;
  if (lang != null) await prefs.setString('language', lang);
  final world = config['world'] as String?;
  if (world != null) await prefs.setString('progress.equipped.world', world);

  final stats = await StatsStore.open();
  final progress = await ProgressStore.open();
  final luckySeed = int.tryParse('${config['seed'] ?? ''}');
  final retention = ValueNotifier(
    Retention(stats: stats, progress: progress, random: luckySeed == null ? null : Random(luckySeed)),
  );
  runApp(
    CritterLogicApp(
      stats: stats,
      ads: const NoAdService(),
      premium: _OwnedNoAds(),
      coinStore: _SamplePacks(lang ?? 'en'),
      leaderboard: config['boards'] == false ? _NoBoards() : _StagedBoards(),
      sound: AudioSoundService(muted: stats.muted, persist: stats.setMuted),
      music: NoMusic(enabled: false),
      puzzles: BundledPuzzleSource(),
      retention: retention,
      today: today,
    ),
  );
}

/// Writes the staged save.
Future<void> seed(SharedPreferences prefs, Map<String, dynamic> config, DateTime now) async {
  final stats = StatsStore(prefs);
  final progress = ProgressStore(prefs);
  final rng = Random(7);
  await prefs.setBool('promo.seeded', true);
  await prefs.setBool(Onboarding.skipKey, true);
  for (final k in GameKind.values) {
    await stats.setTutorialDone(k);
  }
  await progress.setWorldChosen();
  await prefs.setBool('music', false);
  await stats.setPremium(true);
  await stats.setReviewed(true);
  await prefs.setInt('firstLaunch', now.subtract(const Duration(days: 13)).millisecondsSinceEpoch);

  // The 12 days before: every daily solved, so a 12-day streak, chests claimed.
  for (var d = max(1, promoDaily - 12); d < promoDaily; d++) {
    for (final k in GameKind.values) {
      await stats.recordDaily(DailyResult(kind: k, number: d, millis: 45000 + rng.nextInt(90000)));
    }
    await stats.setDailyCapsuleGiven(d);
    await stats.updateBestStreak(d);
  }
  for (final d in [3, 7]) {
    await stats.claimChest(d);
  }
  await prefs.setInt('coins', 1240);

  // Levels with stars.
  const reached = {GameKind.nests: 38, GameKind.pairs: 26, GameKind.trail: 21};
  var won = 0;
  for (final e in reached.entries) {
    await stats.setLevel(e.key, e.value);
    for (var l = 1; l < e.value; l++) {
      await stats.recordLevelStars(e.key, l, rng.nextInt(5) == 0 ? 2 : 3);
      won++;
    }
  }
  await prefs.setInt('levelsWon', won);

  // 22 of 30 critters; some leveled up (copies → ⭐).
  const copies = {
    'chick': 7,
    'chicken': 4,
    'duck': 2,
    'pig': 10,
    'goat': 3,
    'cow': 1,
    'dog': 11,
    'rabbit': 4,
    'frog': 7,
    'horse': 2,
    'owl': 5,
    'panda': 3,
    'zebra': 2,
    'hippo': 1,
    'giraffe': 1,
    'parrot': 2,
    'monkey': 2,
    'moose': 4,
    'bear': 7,
    'walrus': 1,
    'penguin': 3,
    'whale': 1,
  };
  for (final e in copies.entries) {
    await stats.setCopies(e.key, e.value);
  }
  await progress.setSetRewarded('farm');
  await progress.setSetRewarded('friends');
  await prefs.setInt('capsules', 2);
  await progress.increment(Counter.capsulesOpened, 38);

  // Trophies, the login calendar (today's gift waiting) and this week's event under way.
  await progress.increment(Counter.noHintSolves, 81);
  await progress.increment(Counter.perfectDailies, 19);
  await progress.increment(Counter.bothDailiesDays, 12);
  await progress.increment(Counter.fastNests, 6);
  await progress.increment(Counter.shares, 3);
  // Every reached tier claimed (tier index 0 = bronze) but two, so the trophy badge shows 2.
  const claimed = {
    'first_daily': 1,
    'dailies': 2,
    'streak': 2,
    'both_dailies': 1,
    'perfect_daily': 1,
    'fast_nests': 1,
    'nests_levels': 1,
    'pairs_levels': 1,
    'levels': 1,
    'no_hint': 2,
    'critters': 2,
    'golden': 1,
    'critter_level3': 1,
    'capsules': 1,
    'shares': 1,
  };
  for (final e in claimed.entries) {
    for (var t = 0; t < e.value; t++) {
      await progress.addAchievementClaim(e.key, t);
    }
  }
  await progress.setAchievementsAnnounced(const {'sets:0', 'critter_level5:0'});
  for (var i = 0; i < 11; i++) {
    await progress.recordCalendarClaim(promoDaily - 12 + i);
  }
  if (config['calendar'] != true) await progress.setCalendarShownDay(localDay(now));
  final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  await progress.setEventTokens(weekId(monday), 18);
  await progress.addEventClaimed(weekId(monday), 5);
  await progress.addEventClaimed(weekId(monday), 15);

  // Worlds and hats.
  for (final id in ['world.neon', 'world.winter', 'hat.flowers', 'hat.party', 'hat.crown']) {
    await progress.addCosmetic(id);
  }
  await progress.setEquipped('hat', (config['hat'] as String?) ?? 'hat.party');
  await progress.setEquipped('world', (config['world'] as String?) ?? 'world.meadow');
}

/// "No ads" already bought: no banners, no interstitials.
class _OwnedNoAds extends PremiumService {
  @override
  bool get isPremium => true;
  @override
  bool get available => false;
  @override
  String? get price => null;
  @override
  Future<void> buy() async {}
  @override
  Future<void> restore() async {}
}

/// The coin packs with sample prices in the screenshot's language.
class _SamplePacks extends CoinStoreService {
  _SamplePacks(this.lang);

  final String lang;

  @override
  List<(CoinPack, String)> get packs {
    const usd = ['\$0.99', '\$1.99', '\$4.99'];
    const fr = ['0,99 \$', '1,99 \$', '4,99 \$'];
    const es = ['0,99 US\$', '1,99 US\$', '4,99 US\$'];
    final prices = switch (lang) {
      'fr' => fr,
      'es' => es,
      _ => usd,
    };
    return [for (var i = 0; i < coinPacks.length; i++) (coinPacks[i], prices[i])];
  }

  @override
  Future<void> buy(CoinPack pack) async {}
}

/// No online boards (boards=false): the daily Shorts must not show the stand-in's made-up player counts.
class _NoBoards extends _StagedBoards {
  @override
  Future<DailyStanding?> submitDaily(GameKind kind, int day, int millis) async => null;

  @override
  Future<DailyStanding?> standing(GameKind kind, int day, {int? myMillis}) async => null;
}

/// A stand-in for the online boards: a few thousand players, most slower than a quick solve.
class _StagedBoards implements LeaderboardService {
  DailyStanding _standing(GameKind kind, int day, int? mine) {
    const total = 4836;
    // Times spread around ~2½ minutes (10 s buckets).
    final counts = <int, int>{};
    var left = total;
    for (var b = 0; b <= lastBucket && left > 0; b++) {
      final x = (b - 14) / 6.5;
      final n = min(left, (total * 0.061 * exp(-x * x / 2)).round());
      if (n > 0) counts[b] = n;
      left -= n;
    }
    if (left > 0) counts[lastBucket] = (counts[lastBucket] ?? 0) + left;
    final top = <(int, bool)>[for (var i = 0; i < DailyStanding.topSize; i++) (18400 + i * 2300, false)];
    return DailyStanding(top: top, total: total, counts: counts, myMillis: mine);
  }

  @override
  Future<DailyStanding?> submitDaily(GameKind kind, int day, int millis) async => _standing(kind, day, millis);

  @override
  Future<DailyStanding?> standing(GameKind kind, int day, {int? myMillis}) async => _standing(kind, day, myMillis);

  @override
  Future<void> submitProfile({required int bestStreak, required int solved}) async {}

  @override
  Future<AllTimeBoards?> allTime() async => const AllTimeBoards(
    bestStreaks: [(164, false), (151, false), (128, false), (97, false), (12, true)],
    solved: [(612, false), (540, false), (471, false), (388, false), (36, true)],
  );
}
