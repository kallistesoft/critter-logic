// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get privacyOptions => 'Privacy options';

  @override
  String get rateApp => 'Rate Critter Logic';

  @override
  String noAdsPrice(String price) {
    return 'No ads · $price';
  }

  @override
  String get restorePurchase => 'Restore purchase';

  @override
  String get parentGateTitle => 'Ask a grown-up';

  @override
  String parentGateQuestion(int a, int b) {
    return 'To continue, enter the answer to $a × $b';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get continueAction => 'Continue';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateAvailableBody => 'A new version of Critter Logic is ready.';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version of Critter Logic is no longer supported. Update to keep playing, so your daily puzzle matches everyone else\'s.';

  @override
  String get updateRequiredButton => 'UPDATE';

  @override
  String get home => 'Home';

  @override
  String get shareResult => 'Share result';

  @override
  String get shareCopied => 'Result copied — paste it anywhere!';

  @override
  String shareStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '📅 $count-day streak',
      one: '📅 $count-day streak',
    );
    return '$_temp0';
  }

  @override
  String get noAdAvailable =>
      'No ad available right now. Try again in a moment.';

  @override
  String dailyTitle(int number) {
    return 'Daily #$number';
  }

  @override
  String get gameNests => 'Nests';

  @override
  String get gamePairs => 'Pairs';

  @override
  String get gameTrail => 'Trail';

  @override
  String get tagline => 'Daily logic puzzles';

  @override
  String get play => 'Play';

  @override
  String get todaysPuzzles => 'Today\'s puzzles';

  @override
  String get allDailiesDone => 'All three dailies done — see you tomorrow! 🎉';

  @override
  String get levels => 'Levels';

  @override
  String levelTitle(int level) {
    return 'Level $level';
  }

  @override
  String get album => 'Album';

  @override
  String get capsules => 'Capsules';

  @override
  String get openNow => 'Open now!';

  @override
  String get capsuleShort => 'Earn by playing';

  @override
  String get settings => 'Settings';

  @override
  String get back => 'Back';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get streakBroken =>
      'Your streak broke yesterday. Watch a video to save it!';

  @override
  String get repairStreak => 'Repair with a video';

  @override
  String get streakRepaired => 'Streak repaired! 🔥';

  @override
  String get undo => 'Undo';

  @override
  String get restart => 'Restart';

  @override
  String get hint => 'Hint';

  @override
  String penaltySeconds(int seconds) {
    return '+${seconds}s';
  }

  @override
  String get nestsRulesShort =>
      'One critter per row, column and zone. They never touch!';

  @override
  String get pairsRulesShort =>
      'As many ☀️ as 🌙 in each line, never 3 alike in a row.';

  @override
  String get trailRulesShort =>
      'One trail through every square, stones in order, from 1 to the 🚩.';

  @override
  String get hintNoCoinsTitle => 'Not enough coins';

  @override
  String hintNoCoinsBody(int cost) {
    return 'A hint costs $cost coins. Watch a short video for a free one?';
  }

  @override
  String get watchVideo => 'Watch a video';

  @override
  String get solved => 'Solved!';

  @override
  String levelSolved(int level) {
    return 'Level $level solved!';
  }

  @override
  String get noHintBonus => 'No-hint bonus!';

  @override
  String get nextLevel => 'Next level';

  @override
  String get alreadySolved => 'Already solved';

  @override
  String get yourTime => 'Your time';

  @override
  String get flawless => 'Flawless! No mistakes, no hints ✨';

  @override
  String timeBreakdown(String clock, int mistakes, int hints, int penalty) {
    return '$clock + ${penalty}s ($mistakes ✗ · $hints 💡)';
  }

  @override
  String get leaderboardLoading => 'Checking the leaderboard…';

  @override
  String get leaderboardOffline => 'Leaderboard unavailable right now.';

  @override
  String fasterThan(int percent) {
    return 'Faster than $percent% of players';
  }

  @override
  String rankOf(int rank, int total) {
    return 'Rank $rank of $total';
  }

  @override
  String get topTimes => 'Top 10';

  @override
  String get you => 'You';

  @override
  String get player => 'Player';

  @override
  String get rewards => 'Rewards';

  @override
  String rewardCoins(int coins) {
    return '+$coins coins';
  }

  @override
  String get rewardDailyCapsule => 'All dailies done: +1 capsule';

  @override
  String get rewardCapsule => '+1 capsule';

  @override
  String get rewardGoldenCapsule => '+1 golden capsule';

  @override
  String rewardChest(int streak, int coins) {
    return '$streak-day streak chest: +$coins coins';
  }

  @override
  String playOtherDaily(String game) {
    return 'Play $game';
  }

  @override
  String get todaysGrid => 'Today\'s grid';

  @override
  String howToPlay(String game) {
    return 'How to play $game';
  }

  @override
  String get skip => 'Skip';

  @override
  String get tutorialTapHint => 'Tap the highlighted cells.';

  @override
  String get tutorialOops =>
      'Oops, that breaks a rule. Tap again to change it.';

  @override
  String get tutorialNice => 'Nice! Next';

  @override
  String get tutorialLetsPlay => 'Let\'s play!';

  @override
  String get tutNestsRow =>
      'One critter per row! Tap a cell once for ✕, twice for a critter.';

  @override
  String get tutNestsColumn => 'One per column too.';

  @override
  String get tutNestsZone => 'One per color zone.';

  @override
  String get tutNestsTouch => 'Critters never touch, not even at the corners.';

  @override
  String get tutPairsBalance =>
      'Each line has as many ☀️ as 🌙. Tap once for ☀️, twice for 🌙.';

  @override
  String get tutPairsThree => 'Never three alike in a row.';

  @override
  String get tutPairsLinks => '= means the same, × means opposite.';

  @override
  String get tutTrailStart =>
      'Put your finger on stone 1 and drag to stone 2. The trail goes up, down, left or right.';

  @override
  String get tutTrailOrder =>
      'Visit the stones in order: 1, 2, 3… Drag back over the trail to undo a step.';

  @override
  String get tutTrailWalls => 'Hedges block the way. Go around them!';

  @override
  String get tutTrailFill =>
      'Cover every square, then end on the last stone 🚩.';

  @override
  String get tutTrailDragHint => 'Drag from the highlighted cell.';

  @override
  String get tutTrailOops => 'Oops, that way breaks a rule. Try another cell.';

  @override
  String get setComplete => 'Complete';

  @override
  String capsulesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capsules to open!',
      one: '1 capsule to open!',
    );
    return '$_temp0';
  }

  @override
  String get capsulesHowTo =>
      'Solve all three dailies to earn a capsule each day.';

  @override
  String get noCapsules => 'No capsules yet';

  @override
  String get capsuleForVideo => 'Free capsule for a video';

  @override
  String get capsuleTap => 'Tap the capsule!';

  @override
  String get capsuleTapAgain => 'Again!';

  @override
  String get capsuleAlmost => 'One more tap!';

  @override
  String get goldenCapsule => 'Golden capsule!';

  @override
  String get capsuleNew => 'New in your album! ✨';

  @override
  String capsuleDuplicate(int coins) {
    return 'Already in your album: +$coins coins';
  }

  @override
  String capsuleSetComplete(String set, int coins) {
    return '$set set complete! +$coins coins';
  }

  @override
  String openAnother(int count) {
    return 'Open the next one ($count)';
  }

  @override
  String get seeAlbum => 'See album';

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityGolden => 'Golden';

  @override
  String get setFarm => 'Farm';

  @override
  String get setFriends => 'Friends';

  @override
  String get setSavanna => 'Savanna';

  @override
  String get setJungle => 'Jungle';

  @override
  String get setPolar => 'Polar';

  @override
  String get close => 'Close';

  @override
  String get calendarTitle => 'Daily gifts';

  @override
  String get calendarSubtitle => 'A gift for every day you visit';

  @override
  String calendarDay(int day) {
    return 'Day $day';
  }

  @override
  String get calendarClaim => 'Claim';

  @override
  String get calendarDouble => 'x2';

  @override
  String get calendarTomorrow => 'Come back tomorrow for the next gift!';

  @override
  String get capsuleWord => 'Capsule';

  @override
  String get goldenCapsuleWord => 'Golden capsule';

  @override
  String get trophies => 'Trophies';

  @override
  String get trophyClaim => 'Claim';

  @override
  String get trophyDone => 'All done!';

  @override
  String get trophyUnlocked => 'Trophy unlocked!';

  @override
  String get achievementFirstDaily => 'First steps';

  @override
  String get achievementFirstDailyDesc => 'Solve your first daily';

  @override
  String get achievementDailies => 'Daily habit';

  @override
  String achievementDailiesDesc(int n) {
    return 'Solve $n dailies';
  }

  @override
  String get achievementStreak => 'On fire';

  @override
  String achievementStreakDesc(int n) {
    return 'Reach a $n-day streak';
  }

  @override
  String get achievementBothDailies => 'Double up';

  @override
  String achievementBothDailiesDesc(int n) {
    return 'Solve both dailies on $n days';
  }

  @override
  String get achievementPerfectDaily => 'Flawless';

  @override
  String achievementPerfectDailyDesc(int n) {
    return 'Solve $n dailies with no mistake and no hint';
  }

  @override
  String get achievementFastNests => 'Speedy nests';

  @override
  String achievementFastNestsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Solve $n Nests dailies in under a minute',
      one: 'Solve a Nests daily in under a minute',
    );
    return '$_temp0';
  }

  @override
  String get achievementFastPairs => 'Speedy pairs';

  @override
  String achievementFastPairsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Solve $n Pairs dailies in under a minute',
      one: 'Solve a Pairs daily in under a minute',
    );
    return '$_temp0';
  }

  @override
  String get achievementNestsLevels => 'Nest builder';

  @override
  String achievementNestsLevelsDesc(int n) {
    return 'Win $n Nests levels';
  }

  @override
  String get achievementPairsLevels => 'Stone hopper';

  @override
  String achievementPairsLevelsDesc(int n) {
    return 'Win $n Pairs levels';
  }

  @override
  String get achievementLevels => 'Level climber';

  @override
  String achievementLevelsDesc(int n) {
    return 'Win $n levels';
  }

  @override
  String get achievementNoHint => 'No help needed';

  @override
  String achievementNoHintDesc(int n) {
    return 'Solve $n puzzles without a hint';
  }

  @override
  String get achievementCritters => 'Collector';

  @override
  String achievementCrittersDesc(int n) {
    return 'Collect $n critters';
  }

  @override
  String get achievementSets => 'Set master';

  @override
  String achievementSetsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Complete $n album sets',
      one: 'Complete an album set',
    );
    return '$_temp0';
  }

  @override
  String get achievementGolden => 'Golden touch';

  @override
  String achievementGoldenDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Find $n golden critters',
      one: 'Find a golden critter',
    );
    return '$_temp0';
  }

  @override
  String get achievementCapsules => 'Egg cracker';

  @override
  String achievementCapsulesDesc(int n) {
    return 'Open $n capsules';
  }

  @override
  String get achievementShares => 'Show-off';

  @override
  String achievementSharesDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Share $n results',
      one: 'Share a result',
    );
    return '$_temp0';
  }

  @override
  String get achievementCalendar => 'Regular visitor';

  @override
  String achievementCalendarDesc(int n) {
    return 'Claim $n daily gifts';
  }

  @override
  String get achievementEvents => 'Event star';

  @override
  String achievementEventsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Finish $n weekly events',
      one: 'Finish a weekly event',
    );
    return '$_temp0';
  }

  @override
  String get eventPolar => 'Polar Week';

  @override
  String get eventPanda => 'Panda Week';

  @override
  String get eventJungle => 'Jungle Week';

  @override
  String get eventSafari => 'Safari Week';

  @override
  String get eventFarm => 'Farm Week';

  @override
  String get eventWinter => 'Winter Week';

  @override
  String eventEndsDays(int days, int hours) {
    return '${days}d ${hours}h left';
  }

  @override
  String eventEndsHours(int hours, int minutes) {
    return '${hours}h ${minutes}m left';
  }

  @override
  String eventTokens(int n) {
    return '+$n event tokens';
  }

  @override
  String eventTokensShort(int n, String event) {
    return '+$n 🐾 $event';
  }

  @override
  String get eventPrizeReady => 'Event prize ready!';

  @override
  String eventHowTo(int daily, int level) {
    return 'Solve a daily: +$daily 🐾 · Win a level: +$level 🐾';
  }

  @override
  String eventPrizeCritter(String set) {
    return 'A new $set critter + a frame';
  }

  @override
  String get eventLastDay => 'Last day! Claim your prizes before midnight.';

  @override
  String get eventSetCritters => 'This week\'s critters';

  @override
  String get eventClaim => 'Claim';

  @override
  String get eventClaimed => 'Claimed';

  @override
  String get shop => 'Shop';

  @override
  String get shopCapsules => 'Capsules';

  @override
  String get shopHats => 'Hats';

  @override
  String get shopCoins => 'Coins';

  @override
  String get shopDeal => 'Daily deal';

  @override
  String get shopEquip => 'Equip';

  @override
  String get shopEquipped => 'Equipped';

  @override
  String get shopTakeOff => 'Take off';

  @override
  String get shopCapsuleBody => 'A surprise critter for your album';

  @override
  String get shopStreakRepair => 'Streak repair';

  @override
  String get shopStreakRepairBody => 'Saves yesterday\'s missed day';

  @override
  String get shopStreakRepairNone => 'Your streak is safe';

  @override
  String shopNotEnough(int n) {
    return 'You need $n more coins.';
  }

  @override
  String get shopBought => 'It\'s yours!';

  @override
  String shopOrSet(String set) {
    return 'Free with the $set set';
  }

  @override
  String get shopOrAlbum => 'Free with the full album';

  @override
  String get shopCoinsNote =>
      'Coins help with hints, capsules and new looks. Ask a grown-up first.';

  @override
  String coinPackCoins(int n) {
    return '$n coins';
  }

  @override
  String coinPackBonus(int percent) {
    return '+$percent%';
  }

  @override
  String get coinPackBest => 'Best value';

  @override
  String get hatFlowers => 'Flower crown';

  @override
  String get hatParty => 'Party hat';

  @override
  String get hatBeanie => 'Beanie';

  @override
  String get hatCrown => 'Crown';

  @override
  String get frameAlbumGold => 'Gold album frame';

  @override
  String get luckyNest => 'Lucky Nest';

  @override
  String get luckyFree => 'Free!';

  @override
  String get luckyFreeEgg => 'Free egg';

  @override
  String get luckyTapEgg => 'Pick an egg!';

  @override
  String get luckyOdds => 'Odds';

  @override
  String get luckyOddsTitle => 'What\'s in an egg?';

  @override
  String get luckyOddsNote =>
      'Every egg is drawn on its own: the odds are the same for every egg.';

  @override
  String get luckyPrizeGolden => 'Golden capsule';

  @override
  String get luckyPrizeCapsule => 'Capsule';

  @override
  String luckyPrizeCoins(int min, int max) {
    return '$min–$max coins';
  }

  @override
  String get luckyPrizeHint => 'Free hint';

  @override
  String get luckyPrizeFeather => 'A feather';

  @override
  String get luckySoClose => 'So close!';

  @override
  String get luckyWonHint => '+1 free hint';

  @override
  String get luckyAnother => 'Another egg';

  @override
  String get luckyTomorrow => 'Next free egg tomorrow';

  @override
  String get luckyOpenCapsule => 'Open it';

  @override
  String freeHintUsed(int n) {
    return 'Free hint used ($n left)';
  }

  @override
  String get setCompleteTitle => 'Set complete!';

  @override
  String get albumCompleteTitle => 'Album complete!';

  @override
  String setUnlockedItem(String item) {
    return '$item unlocked';
  }

  @override
  String setRewardLabel(String item) {
    return 'Reward: $item';
  }

  @override
  String get setUnlockedBadge => 'Unlocked!';

  @override
  String get later => 'Later';

  @override
  String get nice => 'Nice!';

  @override
  String get settingSound => 'Sound effects';

  @override
  String get settingMusic => 'Music';

  @override
  String get settingAutoCross => 'Auto-cross';

  @override
  String get settingAutoCrossInfo => 'Nests: dim the cells a critter rules out';

  @override
  String get settingReminders => 'Daily reminder';

  @override
  String get settingLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get reminderChannel => 'Daily puzzle';

  @override
  String get credits => 'Art and sounds: Kenney (kenney.nl), CC0';

  @override
  String get critterChick => 'Chick';

  @override
  String get critterChicken => 'Chicken';

  @override
  String get critterDuck => 'Duck';

  @override
  String get critterPig => 'Pig';

  @override
  String get critterGoat => 'Goat';

  @override
  String get critterCow => 'Cow';

  @override
  String get critterDog => 'Dog';

  @override
  String get critterRabbit => 'Rabbit';

  @override
  String get critterFrog => 'Frog';

  @override
  String get critterHorse => 'Horse';

  @override
  String get critterOwl => 'Owl';

  @override
  String get critterPanda => 'Panda';

  @override
  String get critterZebra => 'Zebra';

  @override
  String get critterBuffalo => 'Buffalo';

  @override
  String get critterHippo => 'Hippo';

  @override
  String get critterRhino => 'Rhino';

  @override
  String get critterGiraffe => 'Giraffe';

  @override
  String get critterElephant => 'Elephant';

  @override
  String get critterSnake => 'Snake';

  @override
  String get critterCrocodile => 'Crocodile';

  @override
  String get critterParrot => 'Parrot';

  @override
  String get critterGorilla => 'Gorilla';

  @override
  String get critterMonkey => 'Monkey';

  @override
  String get critterSloth => 'Sloth';

  @override
  String get critterMoose => 'Moose';

  @override
  String get critterBear => 'Bear';

  @override
  String get critterWalrus => 'Walrus';

  @override
  String get critterWhale => 'Whale';

  @override
  String get critterPenguin => 'Penguin';

  @override
  String get critterNarwhal => 'Narwhal';

  @override
  String get reminderTitle => 'Your critters are waiting 🐣';

  @override
  String get reminderBody => 'Today\'s Nests and Pairs are ready.';

  @override
  String reminderStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Keep your 🔥 $count-day streak: play today!',
      one: 'Keep your 🔥 $count-day streak: play today!',
    );
    return '$_temp0';
  }

  @override
  String get reminderDenied =>
      'Turn on notifications for Critter Logic in your phone settings.';

  @override
  String get levelMap => 'Map';

  @override
  String get tapToPlay => 'Tap to play!';

  @override
  String levelLocked(int level) {
    return 'Finish level $level first';
  }

  @override
  String levelPathTitle(String game) {
    return '$game levels';
  }

  @override
  String levelDone(int level, int stars) {
    return 'Level $level: $stars/3 stars';
  }

  @override
  String get fontCredit =>
      'Fonts: Fredoka, Zilla Slab, Bevan, Exo 2, Inter (SIL Open Font License)';

  @override
  String get shopWorlds => 'Worlds';

  @override
  String get worldMeadow => 'Meadow';

  @override
  String get worldLodge => 'Wild Lodge';

  @override
  String get worldNeon => 'Night Neon';

  @override
  String get worldWinter => 'Winter Cabin';

  @override
  String get worldPro => 'Clean Pro';

  @override
  String get worldMeadowBlurb => 'Sunny hills, wooden signs and cute critters.';

  @override
  String get worldLodgeBlurb =>
      'Dusk in the pines, campfire glow and wildlife badges.';

  @override
  String get worldNeonBlurb => 'Glowing grids and synthwave nights.';

  @override
  String get worldWinterBlurb =>
      'Snowy pines, warm windows and northern lights.';

  @override
  String get worldProBlurb => 'Minimal slate and gold. Just your times.';

  @override
  String get worldFree => 'Free';

  @override
  String get worldPreview => 'Preview';

  @override
  String get worldPreviewNote => 'Preview: tap to close';

  @override
  String worldEquipped(String world) {
    return 'Your world is now $world';
  }

  @override
  String get welcomeWorldTitle => 'Pick your world';

  @override
  String get welcomeWorldBody =>
      'Same puzzles, your style. You can switch anytime in the shop.';

  @override
  String welcomeWorldGo(String world) {
    return 'Play in $world';
  }

  @override
  String get welcomeWorldSkip => 'Skip';

  @override
  String get fieldJournal => 'Field journal';

  @override
  String get previewDaily => 'Today';

  @override
  String get coinsPreview =>
      'Store not available in the dev build: this is a preview.';

  @override
  String get settingWorld => 'World';

  @override
  String get settingWorldMore => 'More worlds in the shop';

  @override
  String get lodgeChick => 'Quail';

  @override
  String get lodgeChicken => 'Wild turkey';

  @override
  String get lodgePig => 'Wild boar';

  @override
  String get lodgeGoat => 'Ibex';

  @override
  String get lodgeCow => 'Bison';

  @override
  String get lodgeDog => 'Grey wolf';

  @override
  String get lodgeRabbit => 'Hare';

  @override
  String get lodgeFrog => 'Bullfrog';

  @override
  String get lodgeOwl => 'Eagle-owl';

  @override
  String get lodgeBear => 'Grizzly';

  @override
  String get lodgeMonkey => 'Macaque';

  @override
  String get lodgeSnake => 'Rattlesnake';

  @override
  String get lodgeParrot => 'Macaw';

  @override
  String get lodgeGorilla => 'Silverback';
}
