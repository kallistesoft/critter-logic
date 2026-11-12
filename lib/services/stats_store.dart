import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../meta/economy.dart';
import '../puzzles/puzzle.dart';

/// Result of a solved daily puzzle (the first attempt only).
class DailyResult {
  const DailyResult({required this.kind, required this.number, required this.millis, this.mistakes = 0, this.hints = 0});

  final GameKind kind;
  final int number;

  /// Solve time including penalties, in milliseconds: what the leaderboard ranks.
  final int millis;
  final int mistakes;
  final int hints;

  String encode() => '$millis,$mistakes,$hints';

  static DailyResult? decode(GameKind kind, int number, String? raw) {
    final parts = raw?.split(',');
    if (parts == null || parts.length != 3) return null;
    return DailyResult(
      kind: kind,
      number: number,
      millis: int.parse(parts[0]),
      mistakes: int.parse(parts[1]),
      hints: int.parse(parts[2]),
    );
  }
}

/// Everything the player has, on the device (SharedPreferences).
class StatsStore {
  StatsStore(this._prefs);

  final SharedPreferences _prefs;

  /// The preferences behind this store (the retention [ProgressStore] keeps its keys there too).
  SharedPreferences get prefs => _prefs;

  static Future<StatsStore> open() async => StatsStore(await SharedPreferences.getInstance());

  // ---- Daily puzzles and streak ----

  DailyResult? daily(GameKind kind, int number) =>
      DailyResult.decode(kind, number, _prefs.getString('daily.${kind.name}.$number'));

  /// One attempt per day and game: the first result is kept. Returns false if there already was one.
  Future<bool> recordDaily(DailyResult result) async {
    if (daily(result.kind, result.number) != null) return false;
    await _prefs.setString('daily.${result.kind.name}.${result.number}', result.encode());
    await _prefs.setInt('dailiesSolved', dailiesSolved + 1);
    return true;
  }

  /// All of day [number]'s dailies solved: that day's capsule is earned.
  bool allDailiesDone(int number) => GameKind.values.every((k) => daily(k, number) != null);

  int get dailiesSolved => _prefs.getInt('dailiesSolved') ?? 0;

  /// A day counts for the streak when at least one daily was solved, or it was repaired.
  bool dayCounts(int number) =>
      GameKind.values.any((k) => daily(k, number) != null) || (_prefs.getBool('repaired.$number') ?? false);

  /// Consecutive counted days ending today (or yesterday while today isn't played yet).
  int streak(int today) {
    var day = dayCounts(today) ? today : today - 1;
    var streak = 0;
    while (day > 0 && dayCounts(day)) {
      streak++;
      day--;
    }
    return streak;
  }

  int get bestStreak => _prefs.getInt('bestStreak') ?? 0;

  /// Call after a daily is recorded; keeps [bestStreak] up to date.
  Future<void> updateBestStreak(int today) async {
    final s = streak(today);
    if (s > bestStreak) await _prefs.setInt('bestStreak', s);
  }

  /// A streak broken by exactly one missed day (yesterday) can be repaired, at most once a week.
  bool canRepair(int today) {
    final last = _prefs.getInt('lastRepair');
    return !dayCounts(today - 1) && dayCounts(today - 2) && (last == null || today - last >= 7);
  }

  Future<void> repairYesterday(int today) async {
    await _prefs.setBool('repaired.${today - 1}', true);
    await _prefs.setInt('lastRepair', today);
  }

  /// Streak chests already given, by the day they were given (so a chest comes once per milestone reached).
  bool chestClaimed(int day) => _prefs.getBool('chest.$day') ?? false;
  Future<void> claimChest(int day) => _prefs.setBool('chest.$day', true);

  // ---- Levels ----

  /// The next level to play in [kind]'s endless track (1-based).
  int level(GameKind kind) => _prefs.getInt('level.${kind.name}') ?? 1;
  Future<void> setLevel(GameKind kind, int level) => _prefs.setInt('level.${kind.name}', level);

  /// Best stars (1–3) won on [level] of [kind]'s track; 0 when not solved yet (or solved before stars existed).
  int levelStars(GameKind kind, int level) => _prefs.getInt('stars.${kind.name}.$level') ?? 0;

  /// Keeps the best result: a replay with fewer stars doesn't lower it. Returns the stored stars.
  Future<int> recordLevelStars(GameKind kind, int level, int stars) async {
    final best = stars.clamp(1, 3) > levelStars(kind, level) ? stars.clamp(1, 3) : levelStars(kind, level);
    await _prefs.setInt('stars.${kind.name}.$level', best);
    return best;
  }

  /// Levels won, all games: paces interstitials and the review prompt.
  int get levelsWon => _prefs.getInt('levelsWon') ?? 0;
  Future<void> addLevelWon() => _prefs.setInt('levelsWon', levelsWon + 1);

  bool tutorialDone(GameKind kind) => _prefs.getBool('tutorial.${kind.name}') ?? false;
  Future<void> setTutorialDone(GameKind kind) => _prefs.setBool('tutorial.${kind.name}', true);

  // ---- Coins, capsules, album ----

  int get coins => _prefs.getInt('coins') ?? Economy.starting;
  Future<void> addCoins(int amount) => _prefs.setInt('coins', coins + amount);

  /// Spends [amount] if the player has it.
  Future<bool> spendCoins(int amount) async {
    if (coins < amount) return false;
    await _prefs.setInt('coins', coins - amount);
    return true;
  }

  /// Capsules earned but not opened yet.
  int get capsules => _prefs.getInt('capsules') ?? 0;
  int get goldenCapsules => _prefs.getInt('goldenCapsules') ?? 0;
  Future<void> addCapsule({bool golden = false}) =>
      golden ? _prefs.setInt('goldenCapsules', goldenCapsules + 1) : _prefs.setInt('capsules', capsules + 1);
  Future<void> takeCapsule({bool golden = false}) => golden
      ? _prefs.setInt('goldenCapsules', (goldenCapsules - 1).clamp(0, 1 << 30))
      : _prefs.setInt('capsules', (capsules - 1).clamp(0, 1 << 30));

  /// The day's capsule for solving every daily, given once per day.
  bool dailyCapsuleGiven(int day) => _prefs.getBool('dailyCapsule.$day') ?? false;
  Future<void> setDailyCapsuleGiven(int day) => _prefs.setBool('dailyCapsule.$day', true);

  /// One extra capsule per day for a rewarded ad.
  bool adCapsuleTaken(int day) => _prefs.getBool('adCapsule.$day') ?? false;
  Future<void> setAdCapsuleTaken(int day) => _prefs.setBool('adCapsule.$day', true);

  Set<String> get owned => (_prefs.getStringList('album') ?? const []).toSet();
  Future<void> addCritter(String id) => _prefs.setStringList('album', {...owned, id}.toList());

  // ---- Settings and app state ----

  /// First launch on this device; stored on the first call.
  DateTime firstLaunch() {
    final ms = _prefs.getInt('firstLaunch');
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    _prefs.setInt('firstLaunch', now.millisecondsSinceEpoch);
    return now;
  }

  /// "Remove Ads" bought; cached so it holds offline.
  bool get premium => _prefs.getBool('premium') ?? false;
  Future<void> setPremium(bool value) => _prefs.setBool('premium', value);

  /// The player tapped the "rate" button; the button and the rating prompt stay hidden afterwards.
  bool get reviewed => _prefs.getBool('reviewed') ?? false;
  Future<void> setReviewed(bool value) => _prefs.setBool('reviewed', value);

  /// Last time the in-app rating dialog was requested.
  DateTime? get reviewPromptedAt {
    final ms = _prefs.getInt('reviewPromptedAt');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setReviewPromptedAt(DateTime time) => _prefs.setInt('reviewPromptedAt', time.millisecondsSinceEpoch);

  bool get muted => _prefs.getBool('muted') ?? false;
  Future<void> setMuted(bool value) => _prefs.setBool('muted', value);

  /// Nests: shade the cells a placed critter rules out. On by default.
  bool get autoCross => _prefs.getBool('autoCross') ?? true;
  Future<void> setAutoCross(bool value) => _prefs.setBool('autoCross', value);

  bool get musicOn => _prefs.getBool('music') ?? true;
  Future<void> setMusicOn(bool value) => _prefs.setBool('music', value);

  /// Opt-in daily reminder, and how many in a row went unanswered (they stop after 3).
  bool get remindersOn => _prefs.getBool('reminders') ?? false;
  Future<void> setRemindersOn(bool value) => _prefs.setBool('reminders', value);
  int get unansweredReminders => _prefs.getInt('unansweredReminders') ?? 0;
  Future<void> setUnansweredReminders(int value) => _prefs.setInt('unansweredReminders', value);

  /// App language chosen in Settings ('en', 'fr', 'es'); null follows the phone.
  String? get language => languageChanges.value;
  Future<void> setLanguage(String? code) async {
    code == null ? await _prefs.remove('language') : await _prefs.setString('language', code);
    _language.value = code;
  }

  /// Notifies when [language] changes, so the app switches language at once.
  ValueListenable<String?> get languageChanges => _language;
  late final _language = ValueNotifier<String?>(_prefs.getString('language'));

  // Puzzle in progress, one slot per game and mode (e.g. 'nests.daily', 'pairs.level').
  Map<String, dynamic>? savedGame(String slot) {
    final raw = _prefs.getString('save.$slot');
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveGame(String slot, Map<String, dynamic> json) => _prefs.setString('save.$slot', jsonEncode(json));
  Future<void> clearGame(String slot) => _prefs.remove('save.$slot');
}
