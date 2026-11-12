import 'package:critter_logic/services/game_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults round-trip', () {
    final d = GameSettings.defaults;
    final s = GameSettings.read((k) => d[k] as bool, (k) => d[k] as int);
    expect(s.interstitialFirstLevel, 5);
    expect(s.interstitialEvery, 3);
    expect(s.interstitialGapSeconds, 180);
    expect((s.capsuleRareOdds, s.capsuleGoldenOdds), (22, 3));
  });

  test('bad values fall back to defaults', () {
    final s = GameSettings.read((_) => false, (k) => k == 'interstitial_every' ? 0 : (k == 'capsule_golden_odds' ? 90 : 5));
    expect(s.adsEnabled, isFalse);
    expect(s.interstitialEvery, 3, reason: '0 would divide by zero');
    expect(s.capsuleGoldenOdds, 90);
    expect(s.capsuleRareOdds, 5);
  });
}
