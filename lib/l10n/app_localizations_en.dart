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
  String get tagline => 'Daily logic puzzles';

  @override
  String get play => 'Play';

  @override
  String get todaysPuzzles => 'Today\'s puzzles';

  @override
  String get allDailiesDone => 'Both dailies done — see you tomorrow! 🎉';

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
  String get rewardDailyCapsule => 'Both dailies done: +1 capsule';

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
  String get capsulesHowTo => 'Solve both dailies to earn a capsule each day.';

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
}
