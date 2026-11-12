import 'package:flutter/foundation.dart';

import '../l10n/app_localizations.dart';
import '../puzzles/puzzle.dart';
import 'stats_store.dart';

const playStoreUrl = 'https://play.google.com/store/apps/details?id=ca.kallistesoft.critterlogic';

/// App Store numeric id, known once the app exists in App Store Connect; empty until then.
const appStoreId = '';

/// Store page added to every shared result so friends can install the game in one tap.
String get storeUrl {
  if (defaultTargetPlatform != TargetPlatform.iOS) return playStoreUrl;
  return appStoreId.isEmpty ? 'https://kallistesoft.ca/critter-logic/' : 'https://apps.apple.com/app/id$appStoreId';
}

/// 72 345 ms → "1:12".
String formatTime(int millis) {
  final s = millis ~/ 1000;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

const gameEmoji = {GameKind.nests: '🐣', GameKind.pairs: '☀️', GameKind.trail: '🐾'};

/// Text players paste into chats after the dailies: one line per game, the streak, the store link.
String dailyShareText(int number, List<DailyResult> results, {required int streak, required AppLocalizations l10n}) {
  return [
    'Critter Logic #$number',
    for (final r in results) '${gameEmoji[r.kind]} ${formatTime(r.millis)}${r.hints == 0 && r.mistakes == 0 ? ' ✨' : ''}',
    if (streak > 1) l10n.shareStreak(streak),
    storeUrl,
  ].join('\n');
}
