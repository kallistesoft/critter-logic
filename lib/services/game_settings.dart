/// Tuning that can change without an app update (Firebase Remote Config), with the shipped defaults.
class GameSettings {
  const GameSettings({
    this.adsEnabled = true,
    this.interstitialFirstLevel = 5,
    this.interstitialEvery = 3,
    this.interstitialGapSeconds = 180,
    this.capsuleRareOdds = 22,
    this.capsuleGoldenOdds = 3,
  });

  /// Kill switch for interstitials and banners; rewarded ads stay (the player asks for them).
  final bool adsEnabled;

  /// No interstitial before this many levels are won, then one every [interstitialEvery] wins.
  final int interstitialFirstLevel;
  final int interstitialEvery;

  /// At least this long between two interstitials.
  final int interstitialGapSeconds;

  /// Capsule rarity odds in percent.
  final int capsuleRareOdds;
  final int capsuleGoldenOdds;

  /// Remote Config parameter names and default values.
  static Map<String, Object> get defaults {
    const d = GameSettings();
    return {
      'ads_enabled': d.adsEnabled,
      'interstitial_first_level': d.interstitialFirstLevel,
      'interstitial_every': d.interstitialEvery,
      'interstitial_gap_seconds': d.interstitialGapSeconds,
      'capsule_rare_odds': d.capsuleRareOdds,
      'capsule_golden_odds': d.capsuleGoldenOdds,
    };
  }

  /// Reads the values through [getBool]/[getInt] (Remote Config getters); out-of-range values fall back to defaults.
  static GameSettings read(bool Function(String) getBool, int Function(String) getInt) {
    const d = GameSettings();
    int clamp(String key, int fallback, int min, int max) {
      final v = getInt(key);
      return v < min || v > max ? fallback : v;
    }

    final golden = clamp('capsule_golden_odds', d.capsuleGoldenOdds, 0, 100);
    return GameSettings(
      adsEnabled: getBool('ads_enabled'),
      interstitialFirstLevel: clamp('interstitial_first_level', d.interstitialFirstLevel, 0, 1000),
      interstitialEvery: clamp('interstitial_every', d.interstitialEvery, 1, 1000),
      interstitialGapSeconds: clamp('interstitial_gap_seconds', d.interstitialGapSeconds, 0, 3600),
      capsuleRareOdds: clamp('capsule_rare_odds', d.capsuleRareOdds, 0, 100 - golden),
      capsuleGoldenOdds: golden,
    );
  }
}
