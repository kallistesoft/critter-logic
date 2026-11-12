// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get privacyOptions => 'Options de confidentialité';

  @override
  String get rateApp => 'Noter Critter Logic';

  @override
  String noAdsPrice(String price) {
    return 'Sans pub · $price';
  }

  @override
  String get restorePurchase => 'Restaurer l’achat';

  @override
  String get parentGateTitle => 'Demande à un adulte';

  @override
  String parentGateQuestion(int a, int b) {
    return 'Pour continuer, entre la réponse à $a × $b';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get continueAction => 'Continuer';

  @override
  String get updateAvailableTitle => 'Mise à jour disponible';

  @override
  String get updateAvailableBody =>
      'Une nouvelle version de Critter Logic est prête.';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get updateNow => 'Mettre à jour';

  @override
  String get updateRequiredTitle => 'Mise à jour requise';

  @override
  String get updateRequiredBody =>
      'Cette version de Critter Logic n’est plus prise en charge. Mettez-la à jour pour continuer à jouer avec le même défi du jour que tout le monde.';

  @override
  String get updateRequiredButton => 'METTRE À JOUR';

  @override
  String get home => 'Accueil';

  @override
  String get shareResult => 'Partager le résultat';

  @override
  String get shareCopied => 'Résultat copié — collez-le où vous voulez !';

  @override
  String shareStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '📅 Série de $count jours',
      one: '📅 Série de $count jour',
    );
    return '$_temp0';
  }

  @override
  String get noAdAvailable =>
      'Aucune pub disponible pour le moment. Réessayez dans un instant.';

  @override
  String dailyTitle(int number) {
    return 'Défi #$number';
  }

  @override
  String get gameNests => 'Nids';

  @override
  String get gamePairs => 'Paires';

  @override
  String get tagline => 'Casse-tête logiques du jour';
}
