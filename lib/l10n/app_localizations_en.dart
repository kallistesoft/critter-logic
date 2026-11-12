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
}
