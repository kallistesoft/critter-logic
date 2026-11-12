import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// Home: opens the ad consent form
  ///
  /// In en, this message translates to:
  /// **'Privacy options'**
  String get privacyOptions;

  /// Home: opens the store page to leave a review; hidden once tapped
  ///
  /// In en, this message translates to:
  /// **'Rate Critter Logic'**
  String get rateApp;

  /// Remove ads purchase button; price comes localized from the store
  ///
  /// In en, this message translates to:
  /// **'No ads · {price}'**
  String noAdsPrice(String price);

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get restorePurchase;

  /// Parental gate before a purchase; addresses a child
  ///
  /// In en, this message translates to:
  /// **'Ask a grown-up'**
  String get parentGateTitle;

  /// Parental gate multiplication; addresses a child
  ///
  /// In en, this message translates to:
  /// **'To continue, enter the answer to {a} × {b}'**
  String parentGateQuestion(int a, int b);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Dialog confirm button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'A new version of Critter Logic is ready.'**
  String get updateAvailableBody;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of Critter Logic is no longer supported. Update to keep playing, so your daily puzzle matches everyone else\'s.'**
  String get updateRequiredBody;

  /// No description provided for @updateRequiredButton.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get updateRequiredButton;

  /// Game over: back to the home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Daily game over share button
  ///
  /// In en, this message translates to:
  /// **'Share result'**
  String get shareResult;

  /// Snackbar when sharing falls back to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Result copied — paste it anywhere!'**
  String get shareCopied;

  /// Shared text: consecutive days played
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{📅 {count}-day streak} other{📅 {count}-day streak}}'**
  String shareStreak(int count);

  /// No description provided for @noAdAvailable.
  ///
  /// In en, this message translates to:
  /// **'No ad available right now. Try again in a moment.'**
  String get noAdAvailable;

  /// Daily puzzle name, on the home card and the game screen
  ///
  /// In en, this message translates to:
  /// **'Daily #{number}'**
  String dailyTitle(int number);

  /// Name of the Queens-like game: one critter per row, column and color zone
  ///
  /// In en, this message translates to:
  /// **'Nests'**
  String get gameNests;

  /// Name of the Tango-like game: suns and moons
  ///
  /// In en, this message translates to:
  /// **'Pairs'**
  String get gamePairs;

  /// Name of the Zip-like game: one path through every cell, numbered stones in order
  ///
  /// In en, this message translates to:
  /// **'Trail'**
  String get gameTrail;

  /// Home subtitle under the game name
  ///
  /// In en, this message translates to:
  /// **'Daily logic puzzles'**
  String get tagline;

  /// Home daily card button
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Home section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s puzzles'**
  String get todaysPuzzles;

  /// No description provided for @allDailiesDone.
  ///
  /// In en, this message translates to:
  /// **'All three dailies done — see you tomorrow! 🎉'**
  String get allDailiesDone;

  /// Home section: endless level tracks
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levels;

  /// No description provided for @levelTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelTitle(int level);

  /// Critter collection
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// Surprise eggs holding a critter
  ///
  /// In en, this message translates to:
  /// **'Capsules'**
  String get capsules;

  /// Home capsule button when capsules wait
  ///
  /// In en, this message translates to:
  /// **'Open now!'**
  String get openNow;

  /// Home capsule button when none wait
  ///
  /// In en, this message translates to:
  /// **'Earn by playing'**
  String get capsuleShort;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Streak counter
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 days} =1{1 day} other{{count} days}}'**
  String streakDays(int count);

  /// No description provided for @streakBroken.
  ///
  /// In en, this message translates to:
  /// **'Your streak broke yesterday. Watch a video to save it!'**
  String get streakBroken;

  /// No description provided for @repairStreak.
  ///
  /// In en, this message translates to:
  /// **'Repair with a video'**
  String get repairStreak;

  /// No description provided for @streakRepaired.
  ///
  /// In en, this message translates to:
  /// **'Streak repaired! 🔥'**
  String get streakRepaired;

  /// Game toolbar
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Game toolbar: clears the board
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// Game toolbar
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// Daily: time added by mistakes and hints
  ///
  /// In en, this message translates to:
  /// **'+{seconds}s'**
  String penaltySeconds(int seconds);

  /// No description provided for @nestsRulesShort.
  ///
  /// In en, this message translates to:
  /// **'One critter per row, column and zone. They never touch!'**
  String get nestsRulesShort;

  /// No description provided for @pairsRulesShort.
  ///
  /// In en, this message translates to:
  /// **'As many ☀️ as 🌙 in each line, never 3 alike in a row.'**
  String get pairsRulesShort;

  /// No description provided for @trailRulesShort.
  ///
  /// In en, this message translates to:
  /// **'One trail through every square, stones in order, from 1 to the 🚩.'**
  String get trailRulesShort;

  /// No description provided for @hintNoCoinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get hintNoCoinsTitle;

  /// No description provided for @hintNoCoinsBody.
  ///
  /// In en, this message translates to:
  /// **'A hint costs {cost} coins. Watch a short video for a free one?'**
  String hintNoCoinsBody(int cost);

  /// No description provided for @watchVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch a video'**
  String get watchVideo;

  /// No description provided for @solved.
  ///
  /// In en, this message translates to:
  /// **'Solved!'**
  String get solved;

  /// No description provided for @levelSolved.
  ///
  /// In en, this message translates to:
  /// **'Level {level} solved!'**
  String levelSolved(int level);

  /// No description provided for @noHintBonus.
  ///
  /// In en, this message translates to:
  /// **'No-hint bonus!'**
  String get noHintBonus;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// Result of a daily reopened later
  ///
  /// In en, this message translates to:
  /// **'Already solved'**
  String get alreadySolved;

  /// No description provided for @yourTime.
  ///
  /// In en, this message translates to:
  /// **'Your time'**
  String get yourTime;

  /// No description provided for @flawless.
  ///
  /// In en, this message translates to:
  /// **'Flawless! No mistakes, no hints ✨'**
  String get flawless;

  /// Clock time, penalty seconds, mistakes and hints
  ///
  /// In en, this message translates to:
  /// **'{clock} + {penalty}s ({mistakes} ✗ · {hints} 💡)'**
  String timeBreakdown(String clock, int mistakes, int hints, int penalty);

  /// No description provided for @leaderboardLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking the leaderboard…'**
  String get leaderboardLoading;

  /// No description provided for @leaderboardOffline.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard unavailable right now.'**
  String get leaderboardOffline;

  /// No description provided for @fasterThan.
  ///
  /// In en, this message translates to:
  /// **'Faster than {percent}% of players'**
  String fasterThan(int percent);

  /// No description provided for @rankOf.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank} of {total}'**
  String rankOf(int rank, int total);

  /// No description provided for @topTimes.
  ///
  /// In en, this message translates to:
  /// **'Top 10'**
  String get topTimes;

  /// Leaderboard: the player
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Leaderboard: someone else (anonymous)
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @rewardCoins.
  ///
  /// In en, this message translates to:
  /// **'+{coins} coins'**
  String rewardCoins(int coins);

  /// No description provided for @rewardDailyCapsule.
  ///
  /// In en, this message translates to:
  /// **'All dailies done: +1 capsule'**
  String get rewardDailyCapsule;

  /// No description provided for @rewardCapsule.
  ///
  /// In en, this message translates to:
  /// **'+1 capsule'**
  String get rewardCapsule;

  /// No description provided for @rewardGoldenCapsule.
  ///
  /// In en, this message translates to:
  /// **'+1 golden capsule'**
  String get rewardGoldenCapsule;

  /// No description provided for @rewardChest.
  ///
  /// In en, this message translates to:
  /// **'{streak}-day streak chest: +{coins} coins'**
  String rewardChest(int streak, int coins);

  /// Result: open the other daily
  ///
  /// In en, this message translates to:
  /// **'Play {game}'**
  String playOtherDaily(String game);

  /// No description provided for @todaysGrid.
  ///
  /// In en, this message translates to:
  /// **'Today\'s grid'**
  String get todaysGrid;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play {game}'**
  String howToPlay(String game);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @tutorialTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the highlighted cells.'**
  String get tutorialTapHint;

  /// No description provided for @tutorialOops.
  ///
  /// In en, this message translates to:
  /// **'Oops, that breaks a rule. Tap again to change it.'**
  String get tutorialOops;

  /// No description provided for @tutorialNice.
  ///
  /// In en, this message translates to:
  /// **'Nice! Next'**
  String get tutorialNice;

  /// No description provided for @tutorialLetsPlay.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play!'**
  String get tutorialLetsPlay;

  /// No description provided for @tutNestsRow.
  ///
  /// In en, this message translates to:
  /// **'One critter per row! Tap a cell once for ✕, twice for a critter.'**
  String get tutNestsRow;

  /// No description provided for @tutNestsColumn.
  ///
  /// In en, this message translates to:
  /// **'One per column too.'**
  String get tutNestsColumn;

  /// No description provided for @tutNestsZone.
  ///
  /// In en, this message translates to:
  /// **'One per color zone.'**
  String get tutNestsZone;

  /// No description provided for @tutNestsTouch.
  ///
  /// In en, this message translates to:
  /// **'Critters never touch, not even at the corners.'**
  String get tutNestsTouch;

  /// No description provided for @tutPairsBalance.
  ///
  /// In en, this message translates to:
  /// **'Each line has as many ☀️ as 🌙. Tap once for ☀️, twice for 🌙.'**
  String get tutPairsBalance;

  /// No description provided for @tutPairsThree.
  ///
  /// In en, this message translates to:
  /// **'Never three alike in a row.'**
  String get tutPairsThree;

  /// No description provided for @tutPairsLinks.
  ///
  /// In en, this message translates to:
  /// **'= means the same, × means opposite.'**
  String get tutPairsLinks;

  /// No description provided for @tutTrailStart.
  ///
  /// In en, this message translates to:
  /// **'Put your finger on stone 1 and drag to stone 2. The trail goes up, down, left or right.'**
  String get tutTrailStart;

  /// No description provided for @tutTrailOrder.
  ///
  /// In en, this message translates to:
  /// **'Visit the stones in order: 1, 2, 3… Drag back over the trail to undo a step.'**
  String get tutTrailOrder;

  /// No description provided for @tutTrailWalls.
  ///
  /// In en, this message translates to:
  /// **'Hedges block the way. Go around them!'**
  String get tutTrailWalls;

  /// No description provided for @tutTrailFill.
  ///
  /// In en, this message translates to:
  /// **'Cover every square, then end on the last stone 🚩.'**
  String get tutTrailFill;

  /// No description provided for @tutTrailDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag from the highlighted cell.'**
  String get tutTrailDragHint;

  /// No description provided for @tutTrailOops.
  ///
  /// In en, this message translates to:
  /// **'Oops, that way breaks a rule. Try another cell.'**
  String get tutTrailOops;

  /// Album set badge
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get setComplete;

  /// No description provided for @capsulesWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 capsule to open!} other{{count} capsules to open!}}'**
  String capsulesWaiting(int count);

  /// No description provided for @capsulesHowTo.
  ///
  /// In en, this message translates to:
  /// **'Solve all three dailies to earn a capsule each day.'**
  String get capsulesHowTo;

  /// No description provided for @noCapsules.
  ///
  /// In en, this message translates to:
  /// **'No capsules yet'**
  String get noCapsules;

  /// No description provided for @capsuleForVideo.
  ///
  /// In en, this message translates to:
  /// **'Free capsule for a video'**
  String get capsuleForVideo;

  /// No description provided for @capsuleTap.
  ///
  /// In en, this message translates to:
  /// **'Tap the capsule!'**
  String get capsuleTap;

  /// No description provided for @capsuleTapAgain.
  ///
  /// In en, this message translates to:
  /// **'Again!'**
  String get capsuleTapAgain;

  /// No description provided for @capsuleAlmost.
  ///
  /// In en, this message translates to:
  /// **'One more tap!'**
  String get capsuleAlmost;

  /// No description provided for @goldenCapsule.
  ///
  /// In en, this message translates to:
  /// **'Golden capsule!'**
  String get goldenCapsule;

  /// No description provided for @capsuleNew.
  ///
  /// In en, this message translates to:
  /// **'New in your album! ✨'**
  String get capsuleNew;

  /// No description provided for @capsuleDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already in your album: +{coins} coins'**
  String capsuleDuplicate(int coins);

  /// No description provided for @capsuleSetComplete.
  ///
  /// In en, this message translates to:
  /// **'{set} set complete! +{coins} coins'**
  String capsuleSetComplete(String set, int coins);

  /// No description provided for @openAnother.
  ///
  /// In en, this message translates to:
  /// **'Open the next one ({count})'**
  String openAnother(int count);

  /// No description provided for @seeAlbum.
  ///
  /// In en, this message translates to:
  /// **'See album'**
  String get seeAlbum;

  /// No description provided for @rarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get rarityCommon;

  /// No description provided for @rarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityGolden.
  ///
  /// In en, this message translates to:
  /// **'Golden'**
  String get rarityGolden;

  /// No description provided for @setFarm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get setFarm;

  /// No description provided for @setFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get setFriends;

  /// No description provided for @setSavanna.
  ///
  /// In en, this message translates to:
  /// **'Savanna'**
  String get setSavanna;

  /// No description provided for @setJungle.
  ///
  /// In en, this message translates to:
  /// **'Jungle'**
  String get setJungle;

  /// No description provided for @setPolar.
  ///
  /// In en, this message translates to:
  /// **'Polar'**
  String get setPolar;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily gifts'**
  String get calendarTitle;

  /// No description provided for @calendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A gift for every day you visit'**
  String get calendarSubtitle;

  /// No description provided for @calendarDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String calendarDay(int day);

  /// No description provided for @calendarClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get calendarClaim;

  /// No description provided for @calendarDouble.
  ///
  /// In en, this message translates to:
  /// **'x2'**
  String get calendarDouble;

  /// No description provided for @calendarTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow for the next gift!'**
  String get calendarTomorrow;

  /// No description provided for @capsuleWord.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get capsuleWord;

  /// No description provided for @goldenCapsuleWord.
  ///
  /// In en, this message translates to:
  /// **'Golden capsule'**
  String get goldenCapsuleWord;

  /// No description provided for @trophies.
  ///
  /// In en, this message translates to:
  /// **'Trophies'**
  String get trophies;

  /// No description provided for @trophyClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get trophyClaim;

  /// No description provided for @trophyDone.
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get trophyDone;

  /// No description provided for @trophyUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Trophy unlocked!'**
  String get trophyUnlocked;

  /// No description provided for @achievementFirstDaily.
  ///
  /// In en, this message translates to:
  /// **'First steps'**
  String get achievementFirstDaily;

  /// No description provided for @achievementFirstDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Solve your first daily'**
  String get achievementFirstDailyDesc;

  /// No description provided for @achievementDailies.
  ///
  /// In en, this message translates to:
  /// **'Daily habit'**
  String get achievementDailies;

  /// No description provided for @achievementDailiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Solve {n} dailies'**
  String achievementDailiesDesc(int n);

  /// No description provided for @achievementStreak.
  ///
  /// In en, this message translates to:
  /// **'On fire'**
  String get achievementStreak;

  /// No description provided for @achievementStreakDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach a {n}-day streak'**
  String achievementStreakDesc(int n);

  /// No description provided for @achievementBothDailies.
  ///
  /// In en, this message translates to:
  /// **'Double up'**
  String get achievementBothDailies;

  /// No description provided for @achievementBothDailiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Solve both dailies on {n} days'**
  String achievementBothDailiesDesc(int n);

  /// No description provided for @achievementPerfectDaily.
  ///
  /// In en, this message translates to:
  /// **'Flawless'**
  String get achievementPerfectDaily;

  /// No description provided for @achievementPerfectDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Solve {n} dailies with no mistake and no hint'**
  String achievementPerfectDailyDesc(int n);

  /// No description provided for @achievementFastNests.
  ///
  /// In en, this message translates to:
  /// **'Speedy nests'**
  String get achievementFastNests;

  /// No description provided for @achievementFastNestsDesc.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Solve a Nests daily in under a minute} other{Solve {n} Nests dailies in under a minute}}'**
  String achievementFastNestsDesc(int n);

  /// No description provided for @achievementFastPairs.
  ///
  /// In en, this message translates to:
  /// **'Speedy pairs'**
  String get achievementFastPairs;

  /// No description provided for @achievementFastPairsDesc.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Solve a Pairs daily in under a minute} other{Solve {n} Pairs dailies in under a minute}}'**
  String achievementFastPairsDesc(int n);

  /// No description provided for @achievementNestsLevels.
  ///
  /// In en, this message translates to:
  /// **'Nest builder'**
  String get achievementNestsLevels;

  /// No description provided for @achievementNestsLevelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Win {n} Nests levels'**
  String achievementNestsLevelsDesc(int n);

  /// No description provided for @achievementPairsLevels.
  ///
  /// In en, this message translates to:
  /// **'Stone hopper'**
  String get achievementPairsLevels;

  /// No description provided for @achievementPairsLevelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Win {n} Pairs levels'**
  String achievementPairsLevelsDesc(int n);

  /// No description provided for @achievementLevels.
  ///
  /// In en, this message translates to:
  /// **'Level climber'**
  String get achievementLevels;

  /// No description provided for @achievementLevelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Win {n} levels'**
  String achievementLevelsDesc(int n);

  /// No description provided for @achievementNoHint.
  ///
  /// In en, this message translates to:
  /// **'No help needed'**
  String get achievementNoHint;

  /// No description provided for @achievementNoHintDesc.
  ///
  /// In en, this message translates to:
  /// **'Solve {n} puzzles without a hint'**
  String achievementNoHintDesc(int n);

  /// No description provided for @achievementCritters.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get achievementCritters;

  /// No description provided for @achievementCrittersDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect {n} critters'**
  String achievementCrittersDesc(int n);

  /// No description provided for @achievementSets.
  ///
  /// In en, this message translates to:
  /// **'Set master'**
  String get achievementSets;

  /// No description provided for @achievementSetsDesc.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Complete an album set} other{Complete {n} album sets}}'**
  String achievementSetsDesc(int n);

  /// No description provided for @achievementGolden.
  ///
  /// In en, this message translates to:
  /// **'Golden touch'**
  String get achievementGolden;

  /// No description provided for @achievementGoldenDesc.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Find a golden critter} other{Find {n} golden critters}}'**
  String achievementGoldenDesc(int n);

  /// No description provided for @achievementCapsules.
  ///
  /// In en, this message translates to:
  /// **'Egg cracker'**
  String get achievementCapsules;

  /// No description provided for @achievementCapsulesDesc.
  ///
  /// In en, this message translates to:
  /// **'Open {n} capsules'**
  String achievementCapsulesDesc(int n);

  /// No description provided for @achievementShares.
  ///
  /// In en, this message translates to:
  /// **'Show-off'**
  String get achievementShares;

  /// No description provided for @achievementSharesDesc.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Share a result} other{Share {n} results}}'**
  String achievementSharesDesc(int n);

  /// No description provided for @achievementCalendar.
  ///
  /// In en, this message translates to:
  /// **'Regular visitor'**
  String get achievementCalendar;

  /// No description provided for @achievementCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Claim {n} daily gifts'**
  String achievementCalendarDesc(int n);

  /// No description provided for @achievementEvents.
  ///
  /// In en, this message translates to:
  /// **'Event star'**
  String get achievementEvents;

  /// No description provided for @achievementEventsDesc.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Finish a weekly event} other{Finish {n} weekly events}}'**
  String achievementEventsDesc(int n);

  /// No description provided for @eventPolar.
  ///
  /// In en, this message translates to:
  /// **'Polar Week'**
  String get eventPolar;

  /// No description provided for @eventPanda.
  ///
  /// In en, this message translates to:
  /// **'Panda Week'**
  String get eventPanda;

  /// No description provided for @eventJungle.
  ///
  /// In en, this message translates to:
  /// **'Jungle Week'**
  String get eventJungle;

  /// No description provided for @eventSafari.
  ///
  /// In en, this message translates to:
  /// **'Safari Week'**
  String get eventSafari;

  /// No description provided for @eventFarm.
  ///
  /// In en, this message translates to:
  /// **'Farm Week'**
  String get eventFarm;

  /// No description provided for @eventWinter.
  ///
  /// In en, this message translates to:
  /// **'Winter Week'**
  String get eventWinter;

  /// No description provided for @eventEndsDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h left'**
  String eventEndsDays(int days, int hours);

  /// No description provided for @eventEndsHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left'**
  String eventEndsHours(int hours, int minutes);

  /// No description provided for @eventTokens.
  ///
  /// In en, this message translates to:
  /// **'+{n} event tokens'**
  String eventTokens(int n);

  /// No description provided for @eventTokensShort.
  ///
  /// In en, this message translates to:
  /// **'+{n} 🐾 {event}'**
  String eventTokensShort(int n, String event);

  /// No description provided for @eventPrizeReady.
  ///
  /// In en, this message translates to:
  /// **'Event prize ready!'**
  String get eventPrizeReady;

  /// No description provided for @eventHowTo.
  ///
  /// In en, this message translates to:
  /// **'Solve a daily: +{daily} 🐾 · Win a level: +{level} 🐾'**
  String eventHowTo(int daily, int level);

  /// No description provided for @eventPrizeCritter.
  ///
  /// In en, this message translates to:
  /// **'A new {set} critter + a frame'**
  String eventPrizeCritter(String set);

  /// No description provided for @eventLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day! Claim your prizes before midnight.'**
  String get eventLastDay;

  /// No description provided for @eventSetCritters.
  ///
  /// In en, this message translates to:
  /// **'This week\'s critters'**
  String get eventSetCritters;

  /// No description provided for @eventClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get eventClaim;

  /// No description provided for @eventClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get eventClaimed;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @shopCapsules.
  ///
  /// In en, this message translates to:
  /// **'Capsules'**
  String get shopCapsules;

  /// No description provided for @shopHats.
  ///
  /// In en, this message translates to:
  /// **'Hats'**
  String get shopHats;

  /// No description provided for @shopCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get shopCoins;

  /// No description provided for @shopDeal.
  ///
  /// In en, this message translates to:
  /// **'Daily deal'**
  String get shopDeal;

  /// No description provided for @shopEquip.
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get shopEquip;

  /// No description provided for @shopEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get shopEquipped;

  /// No description provided for @shopTakeOff.
  ///
  /// In en, this message translates to:
  /// **'Take off'**
  String get shopTakeOff;

  /// No description provided for @shopCapsuleBody.
  ///
  /// In en, this message translates to:
  /// **'A surprise critter for your album'**
  String get shopCapsuleBody;

  /// No description provided for @shopStreakRepair.
  ///
  /// In en, this message translates to:
  /// **'Streak repair'**
  String get shopStreakRepair;

  /// No description provided for @shopStreakRepairBody.
  ///
  /// In en, this message translates to:
  /// **'Saves yesterday\'s missed day'**
  String get shopStreakRepairBody;

  /// No description provided for @shopStreakRepairNone.
  ///
  /// In en, this message translates to:
  /// **'Your streak is safe'**
  String get shopStreakRepairNone;

  /// No description provided for @shopNotEnough.
  ///
  /// In en, this message translates to:
  /// **'You need {n} more coins.'**
  String shopNotEnough(int n);

  /// No description provided for @shopBought.
  ///
  /// In en, this message translates to:
  /// **'It\'s yours!'**
  String get shopBought;

  /// No description provided for @shopOrSet.
  ///
  /// In en, this message translates to:
  /// **'Free with the {set} set'**
  String shopOrSet(String set);

  /// No description provided for @shopOrAlbum.
  ///
  /// In en, this message translates to:
  /// **'Free with the full album'**
  String get shopOrAlbum;

  /// No description provided for @shopCoinsNote.
  ///
  /// In en, this message translates to:
  /// **'Coins help with hints, capsules and new looks. Ask a grown-up first.'**
  String get shopCoinsNote;

  /// No description provided for @coinPackCoins.
  ///
  /// In en, this message translates to:
  /// **'{n} coins'**
  String coinPackCoins(int n);

  /// No description provided for @coinPackBonus.
  ///
  /// In en, this message translates to:
  /// **'+{percent}%'**
  String coinPackBonus(int percent);

  /// No description provided for @coinPackBest.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get coinPackBest;

  /// No description provided for @hatFlowers.
  ///
  /// In en, this message translates to:
  /// **'Flower crown'**
  String get hatFlowers;

  /// No description provided for @hatParty.
  ///
  /// In en, this message translates to:
  /// **'Party hat'**
  String get hatParty;

  /// No description provided for @hatBeanie.
  ///
  /// In en, this message translates to:
  /// **'Beanie'**
  String get hatBeanie;

  /// No description provided for @hatCrown.
  ///
  /// In en, this message translates to:
  /// **'Crown'**
  String get hatCrown;

  /// No description provided for @frameAlbumGold.
  ///
  /// In en, this message translates to:
  /// **'Gold album frame'**
  String get frameAlbumGold;

  /// No description provided for @luckyNest.
  ///
  /// In en, this message translates to:
  /// **'Lucky Nest'**
  String get luckyNest;

  /// No description provided for @luckyFree.
  ///
  /// In en, this message translates to:
  /// **'Free!'**
  String get luckyFree;

  /// No description provided for @luckyFreeEgg.
  ///
  /// In en, this message translates to:
  /// **'Free egg'**
  String get luckyFreeEgg;

  /// No description provided for @luckyTapEgg.
  ///
  /// In en, this message translates to:
  /// **'Pick an egg!'**
  String get luckyTapEgg;

  /// No description provided for @luckyOdds.
  ///
  /// In en, this message translates to:
  /// **'Odds'**
  String get luckyOdds;

  /// No description provided for @luckyOddsTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s in an egg?'**
  String get luckyOddsTitle;

  /// No description provided for @luckyOddsNote.
  ///
  /// In en, this message translates to:
  /// **'Every egg is drawn on its own: the odds are the same for every egg.'**
  String get luckyOddsNote;

  /// No description provided for @luckyPrizeGolden.
  ///
  /// In en, this message translates to:
  /// **'Golden capsule'**
  String get luckyPrizeGolden;

  /// No description provided for @luckyPrizeCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get luckyPrizeCapsule;

  /// No description provided for @luckyPrizeCoins.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} coins'**
  String luckyPrizeCoins(int min, int max);

  /// No description provided for @luckyPrizeHint.
  ///
  /// In en, this message translates to:
  /// **'Free hint'**
  String get luckyPrizeHint;

  /// No description provided for @luckyPrizeFeather.
  ///
  /// In en, this message translates to:
  /// **'A feather'**
  String get luckyPrizeFeather;

  /// No description provided for @luckySoClose.
  ///
  /// In en, this message translates to:
  /// **'So close!'**
  String get luckySoClose;

  /// No description provided for @luckyWonHint.
  ///
  /// In en, this message translates to:
  /// **'+1 free hint'**
  String get luckyWonHint;

  /// No description provided for @luckyAnother.
  ///
  /// In en, this message translates to:
  /// **'Another egg'**
  String get luckyAnother;

  /// No description provided for @luckyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Next free egg tomorrow'**
  String get luckyTomorrow;

  /// No description provided for @luckyOpenCapsule.
  ///
  /// In en, this message translates to:
  /// **'Open it'**
  String get luckyOpenCapsule;

  /// No description provided for @freeHintUsed.
  ///
  /// In en, this message translates to:
  /// **'Free hint used ({n} left)'**
  String freeHintUsed(int n);

  /// No description provided for @setCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Set complete!'**
  String get setCompleteTitle;

  /// No description provided for @albumCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Album complete!'**
  String get albumCompleteTitle;

  /// No description provided for @setUnlockedItem.
  ///
  /// In en, this message translates to:
  /// **'{item} unlocked'**
  String setUnlockedItem(String item);

  /// No description provided for @setRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'Reward: {item}'**
  String setRewardLabel(String item);

  /// No description provided for @setUnlockedBadge.
  ///
  /// In en, this message translates to:
  /// **'Unlocked!'**
  String get setUnlockedBadge;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @nice.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get nice;

  /// No description provided for @settingSound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingSound;

  /// No description provided for @settingMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingMusic;

  /// No description provided for @settingAutoCross.
  ///
  /// In en, this message translates to:
  /// **'Auto-cross'**
  String get settingAutoCross;

  /// No description provided for @settingAutoCrossInfo.
  ///
  /// In en, this message translates to:
  /// **'Nests: dim the cells a critter rules out'**
  String get settingAutoCrossInfo;

  /// No description provided for @settingReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingReminders;

  /// Settings row: picks the app language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingLanguage;

  /// Language picker: follow the phone's language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// Android notification channel name for the daily reminder, shown in the phone's settings
  ///
  /// In en, this message translates to:
  /// **'Daily puzzle'**
  String get reminderChannel;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Art and sounds: Kenney (kenney.nl), CC0'**
  String get credits;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Chick'**
  String get critterChick;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get critterChicken;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Duck'**
  String get critterDuck;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Pig'**
  String get critterPig;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Goat'**
  String get critterGoat;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Cow'**
  String get critterCow;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get critterDog;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get critterRabbit;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Frog'**
  String get critterFrog;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Horse'**
  String get critterHorse;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Owl'**
  String get critterOwl;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Panda'**
  String get critterPanda;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Zebra'**
  String get critterZebra;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Buffalo'**
  String get critterBuffalo;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Hippo'**
  String get critterHippo;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Rhino'**
  String get critterRhino;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Giraffe'**
  String get critterGiraffe;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Elephant'**
  String get critterElephant;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Snake'**
  String get critterSnake;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Crocodile'**
  String get critterCrocodile;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Parrot'**
  String get critterParrot;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Gorilla'**
  String get critterGorilla;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Monkey'**
  String get critterMonkey;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Sloth'**
  String get critterSloth;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Moose'**
  String get critterMoose;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Bear'**
  String get critterBear;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Walrus'**
  String get critterWalrus;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Whale'**
  String get critterWhale;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Penguin'**
  String get critterPenguin;

  /// Album critter name
  ///
  /// In en, this message translates to:
  /// **'Narwhal'**
  String get critterNarwhal;

  /// Daily reminder notification
  ///
  /// In en, this message translates to:
  /// **'Your critters are waiting 🐣'**
  String get reminderTitle;

  /// Daily reminder notification
  ///
  /// In en, this message translates to:
  /// **'Today\'s Nests and Pairs are ready.'**
  String get reminderBody;

  /// Daily reminder notification
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Keep your 🔥 {count}-day streak: play today!} other{Keep your 🔥 {count}-day streak: play today!}}'**
  String reminderStreak(int count);

  /// Snackbar when the notification permission is refused
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications for Critter Logic in your phone settings.'**
  String get reminderDenied;

  /// Win panel button: back to the level path map
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get levelMap;

  /// Bubble over the current level on the path map
  ///
  /// In en, this message translates to:
  /// **'Tap to play!'**
  String get tapToPlay;

  /// Tapping a locked level on the path map
  ///
  /// In en, this message translates to:
  /// **'Finish level {level} first'**
  String levelLocked(int level);

  /// Title of a game's level path map
  ///
  /// In en, this message translates to:
  /// **'{game} levels'**
  String levelPathTitle(String game);

  /// Tapping a finished level on the path map
  ///
  /// In en, this message translates to:
  /// **'Level {level}: {stars}/3 stars'**
  String levelDone(int level, int stars);

  /// Settings credits line for the bundled font
  ///
  /// In en, this message translates to:
  /// **'Font: Fredoka (SIL Open Font License)'**
  String get fontCredit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
