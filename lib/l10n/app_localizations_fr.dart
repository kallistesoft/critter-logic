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
      'Cette version de Critter Logic n’est plus prise en charge. Mets-la à jour pour continuer à jouer avec le même défi du jour que tout le monde.';

  @override
  String get updateRequiredButton => 'METTRE À JOUR';

  @override
  String get home => 'Accueil';

  @override
  String get shareResult => 'Partager le résultat';

  @override
  String get shareCopied => 'Résultat copié — colle-le où tu veux !';

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
      'Aucune vidéo disponible pour le moment. Réessaie dans un instant.';

  @override
  String dailyTitle(int number) {
    return 'Défi #$number';
  }

  @override
  String get gameNests => 'Nids';

  @override
  String get gamePairs => 'Paires';

  @override
  String get gameTrail => 'Sentier';

  @override
  String get tagline => 'Casse-tête logiques du jour';

  @override
  String get play => 'Jouer';

  @override
  String get todaysPuzzles => 'Défis du jour';

  @override
  String get allDailiesDone => 'Les trois défis sont faits — à demain ! 🎉';

  @override
  String get levels => 'Niveaux';

  @override
  String levelTitle(int level) {
    return 'Niveau $level';
  }

  @override
  String get album => 'Album';

  @override
  String get capsules => 'Capsules';

  @override
  String get openNow => 'À ouvrir !';

  @override
  String get capsuleShort => 'À gagner en jouant';

  @override
  String get settings => 'Réglages';

  @override
  String get back => 'Retour';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String get streakBroken =>
      'Ta série s’est arrêtée hier. Regarde une vidéo pour la sauver !';

  @override
  String get repairStreak => 'Réparer avec une vidéo';

  @override
  String get streakRepaired => 'Série réparée ! 🔥';

  @override
  String get undo => 'Annuler';

  @override
  String get restart => 'Recommencer';

  @override
  String get hint => 'Indice';

  @override
  String penaltySeconds(int seconds) {
    return '+$seconds s';
  }

  @override
  String get nestsRulesShort =>
      'Une bestiole par ligne, colonne et zone. Elles ne se touchent jamais !';

  @override
  String get pairsRulesShort =>
      'Autant de ☀️ que de 🌙 par ligne, jamais 3 pareils de suite.';

  @override
  String get trailRulesShort =>
      'Un seul sentier par toutes les cases, pierres dans l’ordre, de 1 au 🚩.';

  @override
  String get hintNoCoinsTitle => 'Pas assez de pièces';

  @override
  String hintNoCoinsBody(int cost) {
    return 'Un indice coûte $cost pièces. Regarde une courte vidéo pour en avoir un gratuit ?';
  }

  @override
  String get watchVideo => 'Regarder une vidéo';

  @override
  String get solved => 'Réussi !';

  @override
  String levelSolved(int level) {
    return 'Niveau $level réussi !';
  }

  @override
  String get noHintBonus => 'Bonus sans indice !';

  @override
  String get nextLevel => 'Niveau suivant';

  @override
  String get alreadySolved => 'Déjà résolu';

  @override
  String get yourTime => 'Ton temps';

  @override
  String get flawless => 'Parfait ! Sans erreur ni indice ✨';

  @override
  String timeBreakdown(String clock, int mistakes, int hints, int penalty) {
    return '$clock + $penalty s ($mistakes ✗ · $hints 💡)';
  }

  @override
  String get leaderboardLoading => 'On regarde le classement…';

  @override
  String get leaderboardOffline => 'Classement indisponible pour le moment.';

  @override
  String fasterThan(int percent) {
    return 'Plus rapide que $percent % des joueurs';
  }

  @override
  String rankOf(int rank, int total) {
    return 'Rang $rank sur $total';
  }

  @override
  String get topTimes => 'Top 10';

  @override
  String get you => 'Toi';

  @override
  String get player => 'Joueur';

  @override
  String get rewards => 'Récompenses';

  @override
  String rewardCoins(int coins) {
    return '+$coins pièces';
  }

  @override
  String get rewardDailyCapsule => 'Tous les défis faits : +1 capsule';

  @override
  String get rewardCapsule => '+1 capsule';

  @override
  String get rewardGoldenCapsule => '+1 capsule dorée';

  @override
  String rewardChest(int streak, int coins) {
    return 'Coffre de série de $streak jours : +$coins pièces';
  }

  @override
  String playOtherDaily(String game) {
    return 'Jouer à $game';
  }

  @override
  String get todaysGrid => 'La grille du jour';

  @override
  String howToPlay(String game) {
    return 'Comment jouer : $game';
  }

  @override
  String get skip => 'Passer';

  @override
  String get tutorialTapHint => 'Touche les cases en surbrillance.';

  @override
  String get tutorialOops =>
      'Oups, ça enfreint une règle. Touche encore pour changer.';

  @override
  String get tutorialNice => 'Bravo ! Suivant';

  @override
  String get tutorialLetsPlay => 'C’est parti !';

  @override
  String get tutNestsRow =>
      'Une bestiole par ligne ! Touche une case une fois pour ✕, deux fois pour une bestiole.';

  @override
  String get tutNestsColumn => 'Une par colonne aussi.';

  @override
  String get tutNestsZone => 'Une par zone de couleur.';

  @override
  String get tutNestsTouch =>
      'Les bestioles ne se touchent jamais, même pas en diagonale.';

  @override
  String get tutPairsBalance =>
      'Chaque ligne a autant de ☀️ que de 🌙. Touche une fois pour ☀️, deux fois pour 🌙.';

  @override
  String get tutPairsThree => 'Jamais trois pareils de suite.';

  @override
  String get tutPairsLinks => '= veut dire pareil, × veut dire l’inverse.';

  @override
  String get tutTrailStart =>
      'Pose ton doigt sur la pierre 1 et glisse jusqu’à la pierre 2. Le sentier va en haut, en bas, à gauche ou à droite.';

  @override
  String get tutTrailOrder =>
      'Passe par les pierres dans l’ordre : 1, 2, 3… Reviens sur le sentier pour effacer un pas.';

  @override
  String get tutTrailWalls => 'Les haies bloquent le passage. Contourne-les !';

  @override
  String get tutTrailFill =>
      'Passe par toutes les cases, puis termine sur la dernière pierre 🚩.';

  @override
  String get tutTrailDragHint => 'Glisse depuis la case en surbrillance.';

  @override
  String get tutTrailOops =>
      'Oups, ce chemin enfreint une règle. Essaie une autre case.';

  @override
  String get setComplete => 'Complète';

  @override
  String capsulesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capsules à ouvrir !',
      one: '1 capsule à ouvrir !',
    );
    return '$_temp0';
  }

  @override
  String get capsulesHowTo =>
      'Résous les trois défis pour gagner une capsule chaque jour.';

  @override
  String get noCapsules => 'Pas de capsule pour l’instant';

  @override
  String get capsuleForVideo => 'Capsule gratuite contre une vidéo';

  @override
  String get capsuleTap => 'Touche la capsule !';

  @override
  String get capsuleTapAgain => 'Encore !';

  @override
  String get capsuleAlmost => 'Encore un petit coup !';

  @override
  String get goldenCapsule => 'Capsule dorée !';

  @override
  String get capsuleNew => 'Nouveau dans ton album ! ✨';

  @override
  String capsuleDuplicate(int coins) {
    return 'Déjà dans ton album : +$coins pièces';
  }

  @override
  String capsuleSetComplete(String set, int coins) {
    return 'Série $set complète ! +$coins pièces';
  }

  @override
  String openAnother(int count) {
    return 'Ouvrir la suivante ($count)';
  }

  @override
  String get seeAlbum => 'Voir l’album';

  @override
  String get rarityCommon => 'Commun';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityGolden => 'Doré';

  @override
  String get setFarm => 'Ferme';

  @override
  String get setFriends => 'Copains';

  @override
  String get setSavanna => 'Savane';

  @override
  String get setJungle => 'Jungle';

  @override
  String get setPolar => 'Banquise';

  @override
  String get close => 'Fermer';

  @override
  String get calendarTitle => 'Cadeaux du jour';

  @override
  String get calendarSubtitle => 'Un cadeau pour chaque jour de visite';

  @override
  String calendarDay(int day) {
    return 'Jour $day';
  }

  @override
  String get calendarClaim => 'Récupérer';

  @override
  String get calendarDouble => 'x2';

  @override
  String get calendarTomorrow => 'Reviens demain pour le prochain cadeau !';

  @override
  String get capsuleWord => 'Capsule';

  @override
  String get goldenCapsuleWord => 'Capsule dorée';

  @override
  String get trophies => 'Trophées';

  @override
  String get trophyClaim => 'Récupérer';

  @override
  String get trophyDone => 'Terminé !';

  @override
  String get trophyUnlocked => 'Trophée débloqué !';

  @override
  String get achievementFirstDaily => 'Premiers pas';

  @override
  String get achievementFirstDailyDesc => 'Résous ton premier défi du jour';

  @override
  String get achievementDailies => 'Bonne habitude';

  @override
  String achievementDailiesDesc(int n) {
    return 'Résous $n défis du jour';
  }

  @override
  String get achievementStreak => 'En feu';

  @override
  String achievementStreakDesc(int n) {
    return 'Atteins une série de $n jours';
  }

  @override
  String get achievementBothDailies => 'Doublé';

  @override
  String achievementBothDailiesDesc(int n) {
    return 'Résous les deux défis du jour $n jours';
  }

  @override
  String get achievementPerfectDaily => 'Sans faute';

  @override
  String achievementPerfectDailyDesc(int n) {
    return 'Résous $n défis sans erreur ni indice';
  }

  @override
  String get achievementFastNests => 'Nids éclair';

  @override
  String achievementFastNestsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Résous $n défis Nids en moins d\'une minute',
      one: 'Résous un défi Nids en moins d\'une minute',
    );
    return '$_temp0';
  }

  @override
  String get achievementFastPairs => 'Paires éclair';

  @override
  String achievementFastPairsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Résous $n défis Paires en moins d\'une minute',
      one: 'Résous un défi Paires en moins d\'une minute',
    );
    return '$_temp0';
  }

  @override
  String get achievementNestsLevels => 'Bâtisseur de nids';

  @override
  String achievementNestsLevelsDesc(int n) {
    return 'Gagne $n niveaux de Nids';
  }

  @override
  String get achievementPairsLevels => 'Saute-pierres';

  @override
  String achievementPairsLevelsDesc(int n) {
    return 'Gagne $n niveaux de Paires';
  }

  @override
  String get achievementLevels => 'Grimpeur';

  @override
  String achievementLevelsDesc(int n) {
    return 'Gagne $n niveaux';
  }

  @override
  String get achievementNoHint => 'Sans aide';

  @override
  String achievementNoHintDesc(int n) {
    return 'Résous $n casse-têtes sans indice';
  }

  @override
  String get achievementCritters => 'Collectionneur';

  @override
  String achievementCrittersDesc(int n) {
    return 'Collectionne $n bestioles';
  }

  @override
  String get achievementSets => 'Maître des collections';

  @override
  String achievementSetsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Complète $n collections de l\'album',
      one: 'Complète une collection de l\'album',
    );
    return '$_temp0';
  }

  @override
  String get achievementGolden => 'Touche dorée';

  @override
  String achievementGoldenDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Trouve $n bestioles dorées',
      one: 'Trouve une bestiole dorée',
    );
    return '$_temp0';
  }

  @override
  String get achievementCapsules => 'Casse-œufs';

  @override
  String achievementCapsulesDesc(int n) {
    return 'Ouvre $n capsules';
  }

  @override
  String get achievementShares => 'Fier de moi';

  @override
  String achievementSharesDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Partage $n résultats',
      one: 'Partage un résultat',
    );
    return '$_temp0';
  }

  @override
  String get achievementCalendar => 'Habitué';

  @override
  String achievementCalendarDesc(int n) {
    return 'Récupère $n cadeaux du jour';
  }

  @override
  String get achievementEvents => 'Star des événements';

  @override
  String achievementEventsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Termine $n événements de la semaine',
      one: 'Termine un événement de la semaine',
    );
    return '$_temp0';
  }

  @override
  String get eventPolar => 'Semaine polaire';

  @override
  String get eventPanda => 'Semaine des pandas';

  @override
  String get eventJungle => 'Semaine de la jungle';

  @override
  String get eventSafari => 'Semaine safari';

  @override
  String get eventFarm => 'Semaine de la ferme';

  @override
  String get eventWinter => 'Semaine d\'hiver';

  @override
  String eventEndsDays(int days, int hours) {
    return 'Encore $days j $hours h';
  }

  @override
  String eventEndsHours(int hours, int minutes) {
    return 'Encore $hours h $minutes min';
  }

  @override
  String eventTokens(int n) {
    return '+$n jetons d\'événement';
  }

  @override
  String eventTokensShort(int n, String event) {
    return '+$n 🐾 $event';
  }

  @override
  String get eventPrizeReady => 'Un prix d\'événement t\'attend !';

  @override
  String eventHowTo(int daily, int level) {
    return 'Défi du jour : +$daily 🐾 · Niveau gagné : +$level 🐾';
  }

  @override
  String eventPrizeCritter(String set) {
    return 'Une nouvelle bestiole ($set) + un cadre';
  }

  @override
  String get eventLastDay => 'Dernier jour ! Récupère tes prix avant minuit.';

  @override
  String get eventSetCritters => 'Les bestioles de la semaine';

  @override
  String get eventClaim => 'Récupérer';

  @override
  String get eventClaimed => 'Récupéré';

  @override
  String get shop => 'Boutique';

  @override
  String get shopCapsules => 'Capsules';

  @override
  String get shopHats => 'Chapeaux';

  @override
  String get shopCoins => 'Pièces';

  @override
  String get shopDeal => 'Offre du jour';

  @override
  String get shopEquip => 'Équiper';

  @override
  String get shopEquipped => 'Équipé';

  @override
  String get shopTakeOff => 'Retirer';

  @override
  String get shopCapsuleBody => 'Une bestiole surprise pour ton album';

  @override
  String get shopStreakRepair => 'Réparer la série';

  @override
  String get shopStreakRepairBody => 'Rattrape la journée manquée d\'hier';

  @override
  String get shopStreakRepairNone => 'Ta série est intacte';

  @override
  String shopNotEnough(int n) {
    return 'Il te manque $n pièces.';
  }

  @override
  String get shopBought => 'C\'est à toi !';

  @override
  String shopOrSet(String set) {
    return 'Offert avec la collection $set';
  }

  @override
  String get shopOrAlbum => 'Offert avec l\'album complet';

  @override
  String get shopCoinsNote =>
      'Les pièces servent aux indices, aux capsules et aux décors. Demande d\'abord à un adulte.';

  @override
  String coinPackCoins(int n) {
    return '$n pièces';
  }

  @override
  String coinPackBonus(int percent) {
    return '+$percent %';
  }

  @override
  String get coinPackBest => 'Meilleure offre';

  @override
  String get hatFlowers => 'Couronne de fleurs';

  @override
  String get hatParty => 'Chapeau de fête';

  @override
  String get hatBeanie => 'Tuque';

  @override
  String get hatCrown => 'Couronne';

  @override
  String get frameAlbumGold => 'Cadre d\'album doré';

  @override
  String get luckyNest => 'Nid chanceux';

  @override
  String get luckyFree => 'Gratuit !';

  @override
  String get luckyFreeEgg => 'Œuf gratuit';

  @override
  String get luckyTapEgg => 'Choisis un œuf !';

  @override
  String get luckyOdds => 'Probabilités';

  @override
  String get luckyOddsTitle => 'Que contient un œuf ?';

  @override
  String get luckyOddsNote =>
      'Chaque œuf est tiré à part : les chances sont les mêmes pour chaque œuf.';

  @override
  String get luckyPrizeGolden => 'Capsule dorée';

  @override
  String get luckyPrizeCapsule => 'Capsule';

  @override
  String luckyPrizeCoins(int min, int max) {
    return '$min à $max pièces';
  }

  @override
  String get luckyPrizeHint => 'Indice gratuit';

  @override
  String get luckyPrizeFeather => 'Une plume';

  @override
  String get luckySoClose => 'Presque !';

  @override
  String get luckyWonHint => '+1 indice gratuit';

  @override
  String get luckyAnother => 'Un autre œuf';

  @override
  String get luckyTomorrow => 'Prochain œuf gratuit demain';

  @override
  String get luckyOpenCapsule => 'L\'ouvrir';

  @override
  String freeHintUsed(int n) {
    return 'Indice gratuit utilisé (encore $n)';
  }

  @override
  String get setCompleteTitle => 'Collection complète !';

  @override
  String get albumCompleteTitle => 'Album complet !';

  @override
  String setUnlockedItem(String item) {
    return 'Débloqué : $item';
  }

  @override
  String setRewardLabel(String item) {
    return 'Récompense : $item';
  }

  @override
  String get setUnlockedBadge => 'Débloqué !';

  @override
  String get later => 'Plus tard';

  @override
  String get nice => 'Super !';

  @override
  String get settingSound => 'Effets sonores';

  @override
  String get settingMusic => 'Musique';

  @override
  String get settingAutoCross => 'Croix automatiques';

  @override
  String get settingAutoCrossInfo =>
      'Nids : grise les cases exclues par une bestiole';

  @override
  String get settingReminders => 'Rappel quotidien';

  @override
  String get settingLanguage => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get reminderChannel => 'Défi du jour';

  @override
  String get credits => 'Dessins et sons : Kenney (kenney.nl), CC0';

  @override
  String get critterChick => 'Poussin';

  @override
  String get critterChicken => 'Poule';

  @override
  String get critterDuck => 'Canard';

  @override
  String get critterPig => 'Cochon';

  @override
  String get critterGoat => 'Chèvre';

  @override
  String get critterCow => 'Vache';

  @override
  String get critterDog => 'Chien';

  @override
  String get critterRabbit => 'Lapin';

  @override
  String get critterFrog => 'Grenouille';

  @override
  String get critterHorse => 'Cheval';

  @override
  String get critterOwl => 'Hibou';

  @override
  String get critterPanda => 'Panda';

  @override
  String get critterZebra => 'Zèbre';

  @override
  String get critterBuffalo => 'Buffle';

  @override
  String get critterHippo => 'Hippo';

  @override
  String get critterRhino => 'Rhino';

  @override
  String get critterGiraffe => 'Girafe';

  @override
  String get critterElephant => 'Éléphant';

  @override
  String get critterSnake => 'Serpent';

  @override
  String get critterCrocodile => 'Crocodile';

  @override
  String get critterParrot => 'Perroquet';

  @override
  String get critterGorilla => 'Gorille';

  @override
  String get critterMonkey => 'Singe';

  @override
  String get critterSloth => 'Paresseux';

  @override
  String get critterMoose => 'Orignal';

  @override
  String get critterBear => 'Ours';

  @override
  String get critterWalrus => 'Morse';

  @override
  String get critterWhale => 'Baleine';

  @override
  String get critterPenguin => 'Pingouin';

  @override
  String get critterNarwhal => 'Narval';

  @override
  String get reminderTitle => 'Tes bestioles t’attendent 🐣';

  @override
  String get reminderBody => 'Les Nids et les Paires du jour sont prêts.';

  @override
  String reminderStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Garde ta série 🔥 de $count jours : joue aujourd’hui !',
      one: 'Garde ta série 🔥 de $count jour : joue aujourd’hui !',
    );
    return '$_temp0';
  }

  @override
  String get reminderDenied =>
      'Active les notifications de Critter Logic dans les réglages du téléphone.';

  @override
  String get levelMap => 'Carte';

  @override
  String get tapToPlay => 'Touche pour jouer !';

  @override
  String levelLocked(int level) {
    return 'Termine d’abord le niveau $level';
  }

  @override
  String levelPathTitle(String game) {
    return 'Niveaux $game';
  }

  @override
  String levelDone(int level, int stars) {
    return 'Niveau $level : $stars/3 étoiles';
  }

  @override
  String get fontCredit => 'Police : Fredoka (licence SIL Open Font)';

  @override
  String get coinsPreview =>
      'Boutique indisponible dans la version de développement : ceci est un aperçu.';
}
