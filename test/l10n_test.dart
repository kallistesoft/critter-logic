import 'dart:convert';
import 'dart:io';

import 'package:critter_logic/l10n/app_localizations.dart';
import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/share_text.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The message keys of an ARB file (no "@" metadata).
Set<String> arbKeys(String locale) {
  final json = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  const locales = ['en', 'fr', 'es'];

  test('every string exists in English, French and Spanish', () {
    final en = arbKeys('en');
    expect(en, isNotEmpty);
    for (final locale in locales.skip(1)) {
      final other = arbKeys(locale);
      expect(en.difference(other), isEmpty, reason: 'missing in app_$locale.arb');
      expect(other.difference(en), isEmpty, reason: 'only in app_$locale.arb');
    }
  });

  test('the app supports exactly these languages', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(), locales.toSet());
  });

  test('Spanish share text', () {
    final es = lookupAppLocalizations(const Locale('es'));
    final text = dailyShareText(
      3,
      const [DailyResult(kind: GameKind.nests, number: 3, millis: 72000)],
      streak: 5,
      l10n: es,
    );
    expect(text, contains('📅 Racha de 5 días'));
    expect(es.shareStreak(1), '📅 Racha de 1 día');
    expect(es.reminderStreak(2), '¡Mantén tu racha 🔥 de 2 días: juega hoy!');
  });
}
