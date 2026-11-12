import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  /// **'Both dailies done — see you tomorrow! 🎉'**
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
  /// **'Both dailies done: +1 capsule'**
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
  /// **'Solve both dailies to earn a capsule each day.'**
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
