// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get privacyOptions => 'Opciones de privacidad';

  @override
  String get rateApp => 'Valora Critter Logic';

  @override
  String noAdsPrice(String price) {
    return 'Sin anuncios · $price';
  }

  @override
  String get restorePurchase => 'Restaurar compra';

  @override
  String get parentGateTitle => 'Pregunta a un adulto';

  @override
  String parentGateQuestion(int a, int b) {
    return 'Para continuar, escribe el resultado de $a × $b';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get updateAvailableTitle => 'Actualización disponible';

  @override
  String get updateAvailableBody =>
      'Hay una nueva versión de Critter Logic lista.';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateNow => 'Actualizar';

  @override
  String get updateRequiredTitle => 'Actualización necesaria';

  @override
  String get updateRequiredBody =>
      'Esta versión de Critter Logic ya no tiene soporte. Actualízala para seguir jugando con el mismo reto del día que todo el mundo.';

  @override
  String get updateRequiredButton => 'ACTUALIZAR';

  @override
  String get home => 'Inicio';

  @override
  String get shareResult => 'Compartir resultado';

  @override
  String get shareCopied => 'Resultado copiado: ¡pégalo donde quieras!';

  @override
  String shareStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '📅 Racha de $count días',
      one: '📅 Racha de $count día',
    );
    return '$_temp0';
  }

  @override
  String get noAdAvailable =>
      'No hay ningún video ahora mismo. Inténtalo de nuevo en un momento.';

  @override
  String dailyTitle(int number) {
    return 'Reto #$number';
  }

  @override
  String get gameNests => 'Nidos';

  @override
  String get gamePairs => 'Parejas';

  @override
  String get gameTrail => 'Sendero';

  @override
  String get tagline => 'Acertijos de lógica diarios';

  @override
  String get play => 'Jugar';

  @override
  String get todaysPuzzles => 'Retos de hoy';

  @override
  String get allDailiesDone => '¡Los tres retos hechos! Hasta mañana 🎉';

  @override
  String get levels => 'Niveles';

  @override
  String levelTitle(int level) {
    return 'Nivel $level';
  }

  @override
  String get album => 'Álbum';

  @override
  String get capsules => 'Cápsulas';

  @override
  String get openNow => '¡A abrir!';

  @override
  String get capsuleShort => 'Gánalas jugando';

  @override
  String get settings => 'Ajustes';

  @override
  String get back => 'Atrás';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: '0 días',
    );
    return '$_temp0';
  }

  @override
  String get streakBroken =>
      'Tu racha se cortó ayer. ¡Mira un video para salvarla!';

  @override
  String get repairStreak => 'Reparar con un video';

  @override
  String get streakRepaired => '¡Racha reparada! 🔥';

  @override
  String get undo => 'Deshacer';

  @override
  String get restart => 'Reiniciar';

  @override
  String get hint => 'Pista';

  @override
  String penaltySeconds(int seconds) {
    return '+$seconds s';
  }

  @override
  String get nestsRulesShort =>
      'Un animalito por fila, columna y zona. ¡Nunca se tocan!';

  @override
  String get pairsRulesShort =>
      'Tantos ☀️ como 🌙 en cada línea, nunca 3 iguales seguidos.';

  @override
  String get trailRulesShort =>
      'Un solo sendero por todas las casillas, piedras en orden, del 1 a la 🚩.';

  @override
  String get hintNoCoinsTitle => 'Faltan monedas';

  @override
  String hintNoCoinsBody(int cost) {
    return 'Una pista cuesta $cost monedas. ¿Ves un video corto y te la llevas gratis?';
  }

  @override
  String get watchVideo => 'Ver un video';

  @override
  String get solved => '¡Resuelto!';

  @override
  String levelSolved(int level) {
    return '¡Nivel $level resuelto!';
  }

  @override
  String get noHintBonus => '¡Bonus sin pistas!';

  @override
  String get nextLevel => 'Siguiente nivel';

  @override
  String get alreadySolved => 'Ya resuelto';

  @override
  String get yourTime => 'Tu tiempo';

  @override
  String get flawless => '¡Perfecto! Sin errores ni pistas ✨';

  @override
  String timeBreakdown(String clock, int mistakes, int hints, int penalty) {
    return '$clock + $penalty s ($mistakes ✗ · $hints 💡)';
  }

  @override
  String get leaderboardLoading => 'Mirando la clasificación…';

  @override
  String get leaderboardOffline => 'Clasificación no disponible por ahora.';

  @override
  String fasterThan(int percent) {
    return 'Superas al $percent% de los jugadores';
  }

  @override
  String rankOf(int rank, int total) {
    return 'Puesto $rank de $total';
  }

  @override
  String get topTimes => 'Top 10';

  @override
  String get you => 'Tú';

  @override
  String get player => 'Jugador';

  @override
  String get rewards => 'Premios';

  @override
  String rewardCoins(int coins) {
    return '+$coins monedas';
  }

  @override
  String get rewardDailyCapsule => 'Todos los retos hechos: +1 cápsula';

  @override
  String get rewardCapsule => '+1 cápsula';

  @override
  String get rewardGoldenCapsule => '+1 cápsula dorada';

  @override
  String rewardChest(int streak, int coins) {
    return 'Cofre por racha de $streak días: +$coins monedas';
  }

  @override
  String playOtherDaily(String game) {
    return 'Jugar a $game';
  }

  @override
  String get todaysGrid => 'La cuadrícula de hoy';

  @override
  String howToPlay(String game) {
    return 'Cómo jugar: $game';
  }

  @override
  String get skip => 'Saltar';

  @override
  String get tutorialTapHint => 'Toca las casillas resaltadas.';

  @override
  String get tutorialOops =>
      'Uy, eso rompe una regla. Toca otra vez para cambiarlo.';

  @override
  String get tutorialNice => '¡Bien! Siguiente';

  @override
  String get tutorialLetsPlay => '¡A jugar!';

  @override
  String get tutNestsRow =>
      '¡Un animalito por fila! Toca una casilla una vez para ✕, dos para un animalito.';

  @override
  String get tutNestsColumn => 'Y uno por columna.';

  @override
  String get tutNestsZone => 'Uno por zona de color.';

  @override
  String get tutNestsTouch =>
      'Los animalitos nunca se tocan, ni siquiera en diagonal.';

  @override
  String get tutPairsBalance =>
      'Cada línea tiene tantos ☀️ como 🌙. Toca una vez para ☀️, dos para 🌙.';

  @override
  String get tutPairsThree => 'Nunca tres iguales seguidos.';

  @override
  String get tutPairsLinks => '= significa igual, × significa lo contrario.';

  @override
  String get tutTrailStart =>
      'Pon el dedo en la piedra 1 y deslízalo hasta la piedra 2. El sendero va arriba, abajo, a la izquierda o a la derecha.';

  @override
  String get tutTrailOrder =>
      'Pasa por las piedras en orden: 1, 2, 3… Vuelve sobre el sendero para borrar un paso.';

  @override
  String get tutTrailWalls => 'Los setos cortan el paso. ¡Rodéalos!';

  @override
  String get tutTrailFill =>
      'Pasa por todas las casillas y termina en la última piedra 🚩.';

  @override
  String get tutTrailDragHint => 'Desliza desde la casilla resaltada.';

  @override
  String get tutTrailOops =>
      'Uy, ese camino rompe una regla. Prueba otra casilla.';

  @override
  String get setComplete => 'Completa';

  @override
  String capsulesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡$count cápsulas por abrir!',
      one: '¡1 cápsula por abrir!',
    );
    return '$_temp0';
  }

  @override
  String get capsulesHowTo =>
      'Resuelve los tres retos para ganar una cápsula cada día.';

  @override
  String get noCapsules => 'Aún no hay cápsulas';

  @override
  String get capsuleForVideo => 'Cápsula gratis por un video';

  @override
  String get capsuleTap => '¡Toca la cápsula!';

  @override
  String get capsuleTapAgain => '¡Otra vez!';

  @override
  String get capsuleAlmost => '¡Un toque más!';

  @override
  String get goldenCapsule => '¡Cápsula dorada!';

  @override
  String get capsuleNew => '¡Nuevo en tu álbum! ✨';

  @override
  String capsuleSetComplete(String set, int coins) {
    return '¡Colección $set completa! +$coins monedas';
  }

  @override
  String openAnother(int count) {
    return 'Abrir la siguiente ($count)';
  }

  @override
  String get seeAlbum => 'Ver el álbum';

  @override
  String get rarityCommon => 'Común';

  @override
  String get rarityRare => 'Rara';

  @override
  String get rarityGolden => 'Dorada';

  @override
  String get setFarm => 'Granja';

  @override
  String get setFriends => 'Amigos';

  @override
  String get setSavanna => 'Sabana';

  @override
  String get setJungle => 'Selva';

  @override
  String get setPolar => 'Polo';

  @override
  String get close => 'Cerrar';

  @override
  String get calendarTitle => 'Regalos diarios';

  @override
  String get calendarSubtitle => 'Un regalo por cada día que vienes';

  @override
  String calendarDay(int day) {
    return 'Día $day';
  }

  @override
  String get calendarClaim => 'Recoger';

  @override
  String get calendarDouble => 'x2';

  @override
  String get calendarTomorrow => '¡Vuelve mañana por el siguiente regalo!';

  @override
  String get capsuleWord => 'Cápsula';

  @override
  String get goldenCapsuleWord => 'Cápsula dorada';

  @override
  String get trophies => 'Trofeos';

  @override
  String get trophyClaim => 'Recoger';

  @override
  String get trophyDone => '¡Listo!';

  @override
  String get trophyUnlocked => '¡Trofeo desbloqueado!';

  @override
  String get achievementFirstDaily => 'Primeros pasos';

  @override
  String get achievementFirstDailyDesc => 'Resuelve tu primer reto del día';

  @override
  String get achievementDailies => 'Buen hábito';

  @override
  String achievementDailiesDesc(int n) {
    return 'Resuelve $n retos del día';
  }

  @override
  String get achievementStreak => 'En racha';

  @override
  String achievementStreakDesc(int n) {
    return 'Logra una racha de $n días';
  }

  @override
  String get achievementBothDailies => 'Doblete';

  @override
  String achievementBothDailiesDesc(int n) {
    return 'Resuelve los dos retos del día $n días';
  }

  @override
  String get achievementPerfectDaily => 'Sin fallos';

  @override
  String achievementPerfectDailyDesc(int n) {
    return 'Resuelve $n retos sin errores ni pistas';
  }

  @override
  String get achievementFastNests => 'Nidos exprés';

  @override
  String achievementFastNestsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Resuelve $n retos de Nidos en menos de un minuto',
      one: 'Resuelve un reto de Nidos en menos de un minuto',
    );
    return '$_temp0';
  }

  @override
  String get achievementFastPairs => 'Parejas exprés';

  @override
  String achievementFastPairsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Resuelve $n retos de Parejas en menos de un minuto',
      one: 'Resuelve un reto de Parejas en menos de un minuto',
    );
    return '$_temp0';
  }

  @override
  String get achievementNestsLevels => 'Constructor de nidos';

  @override
  String achievementNestsLevelsDesc(int n) {
    return 'Gana $n niveles de Nidos';
  }

  @override
  String get achievementPairsLevels => 'Saltapiedras';

  @override
  String achievementPairsLevelsDesc(int n) {
    return 'Gana $n niveles de Parejas';
  }

  @override
  String get achievementLevels => 'Escalador';

  @override
  String achievementLevelsDesc(int n) {
    return 'Gana $n niveles';
  }

  @override
  String get achievementNoHint => 'Sin ayuda';

  @override
  String achievementNoHintDesc(int n) {
    return 'Resuelve $n acertijos sin pistas';
  }

  @override
  String get achievementCritters => 'Coleccionista';

  @override
  String achievementCrittersDesc(int n) {
    return 'Colecciona $n animalitos';
  }

  @override
  String get achievementSets => 'Maestro coleccionista';

  @override
  String achievementSetsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Completa $n colecciones del álbum',
      one: 'Completa una colección del álbum',
    );
    return '$_temp0';
  }

  @override
  String get achievementGolden => 'Toque dorado';

  @override
  String achievementGoldenDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Encuentra $n animalitos dorados',
      one: 'Encuentra un animalito dorado',
    );
    return '$_temp0';
  }

  @override
  String get achievementCapsules => 'Abrecápsulas';

  @override
  String achievementCapsulesDesc(int n) {
    return 'Abre $n cápsulas';
  }

  @override
  String get achievementShares => '¡Mira esto!';

  @override
  String achievementSharesDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Comparte $n resultados',
      one: 'Comparte un resultado',
    );
    return '$_temp0';
  }

  @override
  String get achievementCalendar => 'Visita fiel';

  @override
  String achievementCalendarDesc(int n) {
    return 'Recoge $n regalos diarios';
  }

  @override
  String get achievementEvents => 'Estrella de eventos';

  @override
  String achievementEventsDesc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Termina $n eventos semanales',
      one: 'Termina un evento semanal',
    );
    return '$_temp0';
  }

  @override
  String get eventPolar => 'Semana polar';

  @override
  String get eventPanda => 'Semana de los pandas';

  @override
  String get eventJungle => 'Semana de la selva';

  @override
  String get eventSafari => 'Semana safari';

  @override
  String get eventFarm => 'Semana de la granja';

  @override
  String get eventWinter => 'Semana de invierno';

  @override
  String eventEndsDays(int days, int hours) {
    return 'Quedan $days d $hours h';
  }

  @override
  String eventEndsHours(int hours, int minutes) {
    return 'Quedan $hours h $minutes min';
  }

  @override
  String eventTokens(int n) {
    return '+$n fichas de evento';
  }

  @override
  String eventTokensShort(int n, String event) {
    return '+$n 🐾 $event';
  }

  @override
  String get eventPrizeReady => '¡Tienes un premio del evento!';

  @override
  String eventHowTo(int daily, int level) {
    return 'Reto del día: +$daily 🐾 · Nivel ganado: +$level 🐾';
  }

  @override
  String eventPrizeCritter(String set) {
    return 'Un animalito nuevo ($set) + un marco';
  }

  @override
  String get eventLastDay =>
      '¡Último día! Recoge tus premios antes de medianoche.';

  @override
  String get eventSetCritters => 'Los animalitos de la semana';

  @override
  String get eventClaim => 'Recoger';

  @override
  String get eventClaimed => 'Recogido';

  @override
  String get shop => 'Tienda';

  @override
  String get shopCapsules => 'Cápsulas';

  @override
  String get shopHats => 'Sombreros';

  @override
  String get shopCoins => 'Monedas';

  @override
  String get shopDeal => 'Oferta del día';

  @override
  String get shopEquip => 'Ponérselo';

  @override
  String get shopEquipped => 'Puesto';

  @override
  String get shopTakeOff => 'Quitar';

  @override
  String get shopCapsuleBody => 'Un animalito sorpresa para tu álbum';

  @override
  String get shopStreakRepair => 'Reparar racha';

  @override
  String get shopStreakRepairBody => 'Recupera el día que faltó ayer';

  @override
  String get shopStreakRepairNone => 'Tu racha está a salvo';

  @override
  String shopNotEnough(int n) {
    return 'Te faltan $n monedas.';
  }

  @override
  String get shopBought => '¡Es tuyo!';

  @override
  String shopOrSet(String set) {
    return 'Gratis con la colección $set';
  }

  @override
  String get shopOrAlbum => 'Gratis con el álbum completo';

  @override
  String get shopCoinsNote =>
      'Las monedas sirven para pistas, cápsulas y nuevos looks. Pregunta antes a un adulto.';

  @override
  String coinPackCoins(int n) {
    return '$n monedas';
  }

  @override
  String coinPackBonus(int percent) {
    return '+$percent%';
  }

  @override
  String get coinPackBest => 'Mejor oferta';

  @override
  String get hatFlowers => 'Corona de flores';

  @override
  String get hatParty => 'Gorro de fiesta';

  @override
  String get hatBeanie => 'Gorro de lana';

  @override
  String get hatCrown => 'Corona';

  @override
  String get frameAlbumGold => 'Marco de álbum dorado';

  @override
  String get luckyNest => 'Nido de la suerte';

  @override
  String get luckyFree => '¡Gratis!';

  @override
  String get luckyFreeEgg => 'Huevo gratis';

  @override
  String get luckyTapEgg => '¡Elige un huevo!';

  @override
  String get luckyOdds => 'Probabilidades';

  @override
  String get luckyOddsTitle => '¿Qué hay en un huevo?';

  @override
  String get luckyOddsNote =>
      'Cada huevo se elige por separado: las probabilidades son las mismas para todos.';

  @override
  String get luckyPrizeGolden => 'Cápsula dorada';

  @override
  String get luckyPrizeCapsule => 'Cápsula';

  @override
  String luckyPrizeCoins(int min, int max) {
    return '$min–$max monedas';
  }

  @override
  String get luckyPrizeHint => 'Pista gratis';

  @override
  String get luckyPrizeFeather => 'Una pluma';

  @override
  String get luckySoClose => '¡Casi!';

  @override
  String get luckyWonHint => '+1 pista gratis';

  @override
  String get luckyAnother => 'Otro huevo';

  @override
  String get luckyTomorrow => 'Mañana, otro huevo gratis';

  @override
  String get luckyOpenCapsule => 'Abrirla';

  @override
  String freeHintUsed(int n) {
    return 'Pista gratis usada (quedan $n)';
  }

  @override
  String get setCompleteTitle => '¡Colección completa!';

  @override
  String get albumCompleteTitle => '¡Álbum completo!';

  @override
  String setUnlockedItem(String item) {
    return 'Desbloqueado: $item';
  }

  @override
  String setRewardLabel(String item) {
    return 'Premio: $item';
  }

  @override
  String get setUnlockedBadge => '¡Desbloqueado!';

  @override
  String get later => 'Más tarde';

  @override
  String get nice => '¡Genial!';

  @override
  String get settingSound => 'Efectos de sonido';

  @override
  String get settingMusic => 'Música';

  @override
  String get settingAutoCross => 'Cruces automáticas';

  @override
  String get settingAutoCrossInfo =>
      'Nidos: atenúa las casillas que descarta un animalito';

  @override
  String get settingReminders => 'Recordatorio diario';

  @override
  String get settingLanguage => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get reminderChannel => 'Reto del día';

  @override
  String get credits => 'Dibujos y sonidos: Kenney (kenney.nl), CC0';

  @override
  String get critterChick => 'Pollito';

  @override
  String get critterChicken => 'Gallina';

  @override
  String get critterDuck => 'Pato';

  @override
  String get critterPig => 'Cerdito';

  @override
  String get critterGoat => 'Cabra';

  @override
  String get critterCow => 'Vaca';

  @override
  String get critterDog => 'Perro';

  @override
  String get critterRabbit => 'Conejo';

  @override
  String get critterFrog => 'Rana';

  @override
  String get critterHorse => 'Caballo';

  @override
  String get critterOwl => 'Búho';

  @override
  String get critterPanda => 'Panda';

  @override
  String get critterZebra => 'Cebra';

  @override
  String get critterBuffalo => 'Búfalo';

  @override
  String get critterHippo => 'Hipopótamo';

  @override
  String get critterRhino => 'Rinoceronte';

  @override
  String get critterGiraffe => 'Jirafa';

  @override
  String get critterElephant => 'Elefante';

  @override
  String get critterSnake => 'Serpiente';

  @override
  String get critterCrocodile => 'Cocodrilo';

  @override
  String get critterParrot => 'Loro';

  @override
  String get critterGorilla => 'Gorila';

  @override
  String get critterMonkey => 'Mono';

  @override
  String get critterSloth => 'Perezoso';

  @override
  String get critterMoose => 'Alce';

  @override
  String get critterBear => 'Oso';

  @override
  String get critterWalrus => 'Morsa';

  @override
  String get critterWhale => 'Ballena';

  @override
  String get critterPenguin => 'Pingüino';

  @override
  String get critterNarwhal => 'Narval';

  @override
  String get reminderTitle => 'Tus animalitos te esperan 🐣';

  @override
  String get reminderBody => 'Los Nidos y las Parejas de hoy están listos.';

  @override
  String reminderStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡Mantén tu racha 🔥 de $count días: juega hoy!',
      one: '¡Mantén tu racha 🔥 de $count día: juega hoy!',
    );
    return '$_temp0';
  }

  @override
  String get reminderDenied =>
      'Activa las notificaciones de Critter Logic en los ajustes del teléfono.';

  @override
  String get levelMap => 'Mapa';

  @override
  String get tapToPlay => '¡Toca para jugar!';

  @override
  String levelLocked(int level) {
    return 'Primero termina el nivel $level';
  }

  @override
  String levelPathTitle(String game) {
    return 'Niveles de $game';
  }

  @override
  String levelDone(int level, int stars) {
    return 'Nivel $level: $stars/3 estrellas';
  }

  @override
  String get fontCredit =>
      'Fuentes: Fredoka, Zilla Slab, Bevan, Exo 2, Inter (licencia SIL Open Font)';

  @override
  String get shopWorlds => 'Mundos';

  @override
  String get worldMeadow => 'Pradera';

  @override
  String get worldLodge => 'Refugio salvaje';

  @override
  String get worldNeon => 'Neón nocturno';

  @override
  String get worldWinter => 'Cabaña de invierno';

  @override
  String get worldPro => 'Pro limpio';

  @override
  String get worldMeadowBlurb =>
      'Colinas soleadas, carteles de madera y animalitos adorables.';

  @override
  String get worldLodgeBlurb =>
      'Atardecer entre pinos, fogata y medallones de fauna salvaje.';

  @override
  String get worldNeonBlurb => 'Cuadrículas brillantes y noches synthwave.';

  @override
  String get worldWinterBlurb =>
      'Pinos nevados, ventanas cálidas y auroras boreales.';

  @override
  String get worldProBlurb => 'Pizarra y oro, sin adornos. Solo tus tiempos.';

  @override
  String get worldFree => 'Gratis';

  @override
  String get worldPreview => 'Vista previa';

  @override
  String get worldPreviewNote => 'Vista previa: toca para cerrar';

  @override
  String worldEquipped(String world) {
    return 'Tu mundo: $world';
  }

  @override
  String get welcomeWorldTitle => 'Elige tu mundo';

  @override
  String get welcomeWorldBody =>
      'Los mismos rompecabezas, a tu estilo. Puedes cambiarlo cuando quieras en la tienda.';

  @override
  String welcomeWorldGo(String world) {
    return 'Jugar en $world';
  }

  @override
  String get welcomeWorldSkip => 'Saltar';

  @override
  String get fieldJournal => 'Diario de campo';

  @override
  String get previewDaily => 'Hoy';

  @override
  String get coinsPreview =>
      'Tienda no disponible en la versión de desarrollo: esto es una vista previa.';

  @override
  String get settingWorld => 'Mundo';

  @override
  String get settingWorldMore => 'Más mundos en la tienda';

  @override
  String get achievementLevel3 => 'Estrella en ascenso';

  @override
  String get achievementLevel3Desc => 'Sube un animalito a ⭐3';

  @override
  String get achievementLevel5 => 'Superestrella';

  @override
  String achievementLevel5Desc(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sube $n animalitos a ⭐5',
      one: 'Sube un animalito a ⭐5',
    );
    return '$_temp0';
  }

  @override
  String capsuleLevelUp(int level) {
    return '¡Sube de nivel! ⭐$level';
  }

  @override
  String capsuleMaxLevel(int coins) {
    return '¡Nivel máximo! +$coins monedas';
  }

  @override
  String capsuleCopy(int have, int need, int level, int coins) {
    return '¡Uno más! $have/$need para ⭐$level · +$coins';
  }

  @override
  String critterLevelProgress(int have, int need, int level) {
    return '$have/$need → ⭐$level';
  }

  @override
  String get critterLevelMax => 'Máx ⭐5';

  @override
  String critterLevelLabel(int level) {
    return 'Nivel $level';
  }

  @override
  String levelReplayTitle(int level) {
    return '¿Repetir el nivel $level?';
  }

  @override
  String get levelReplayBody =>
      'Mira un video corto para jugarlo otra vez. Supera tus estrellas para ganar monedas.';

  @override
  String get levelReplayButton => 'Ver y repetir';

  @override
  String get levelReplayNoCoins =>
      '¡Bien! Supera tus estrellas para ganar monedas.';

  @override
  String get shopNoAdsTitle => 'Sin anuncios';

  @override
  String get shopNoAdsBody =>
      'Adiós a los banners y a los anuncios entre retos. Los videos con premio siguen siendo opcionales.';

  @override
  String get shopNoAdsOwned => 'Anuncios eliminados. ¡Gracias!';
}
