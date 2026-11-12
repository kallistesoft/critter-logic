import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../puzzles/puzzle.dart';

/// Times are grouped in 10-second buckets for the "faster than X%" count; the last bucket holds 10 min and more.
const bucketMillis = 10000;
const lastBucket = 60;

int bucketOf(int millis) => (millis ~/ bucketMillis).clamp(0, lastBucket);

/// No human solves a daily faster than this; the security rules reject quicker times too.
const minDailyMillis = 4000;

/// How the player did on a daily, compared with everyone who solved it.
class DailyStanding {
  const DailyStanding({required this.top, required this.total, required this.counts, this.myMillis, this.myId});

  static const topSize = 10;

  /// Shown as a percentile from this many players; below it the rank alone.
  static const percentileFrom = 20;

  /// The fastest times, best first, with whether each one is the player's.
  final List<(int millis, bool mine)> top;

  /// Players who solved this daily.
  final int total;

  /// Players per time bucket.
  final Map<int, int> counts;
  final int? myMillis;
  final String? myId;

  /// The player's place (1 = fastest): exact inside the top, else estimated from the buckets.
  int? get rank {
    final mine = top.indexWhere((e) => e.$2);
    if (mine >= 0) return mine + 1;
    if (myMillis == null) return null;
    final b = bucketOf(myMillis!);
    var faster = 0;
    counts.forEach((bucket, n) {
      if (bucket < b) faster += n;
    });
    return (faster + 1).clamp(top.length + 1, total < 1 ? 1 : total);
  }

  /// Share of players slower than the player (0..1), or null while too few played to make it meaningful.
  double? get fasterThan {
    if (myMillis == null || total < percentileFrom) return null;
    final b = bucketOf(myMillis!);
    var slower = 0;
    counts.forEach((bucket, n) {
      if (bucket > b) slower += n;
    });
    // Players in the same bucket count as half slower.
    final same = counts[b] ?? 0;
    return ((slower + (same - 1).clamp(0, same) / 2) / (total - 1)).clamp(0, 1);
  }
}

/// Lifetime records shown on the home screen boards.
class AllTimeBoards {
  const AllTimeBoards({required this.bestStreaks, required this.solved});

  final List<(int value, bool mine)> bestStreaks;
  final List<(int value, bool mine)> solved;
}

/// Shared boards. Best effort: never throws; returns null offline.
abstract class LeaderboardService {
  /// Posts the first attempt at a daily (later attempts are ignored by the server) and returns the standing.
  Future<DailyStanding?> submitDaily(GameKind kind, int day, int millis);

  /// The standing of a daily without posting (e.g. reopening a solved daily); [myMillis] is the player's own time.
  Future<DailyStanding?> standing(GameKind kind, int day, {int? myMillis});

  /// Lifetime records; they only ever go up.
  Future<void> submitProfile({required int bestStreak, required int solved});
  Future<AllTimeBoards?> allTime();
}

/// Web and tests: no boards.
class NoLeaderboardService implements LeaderboardService {
  const NoLeaderboardService();

  @override
  Future<DailyStanding?> submitDaily(GameKind kind, int day, int millis) async => null;

  @override
  Future<DailyStanding?> standing(GameKind kind, int day, {int? myMillis}) async => null;

  @override
  Future<void> submitProfile({required int bestStreak, required int solved}) async {}

  @override
  Future<AllTimeBoards?> allTime() async => null;
}

/// Where the boards live: Firestore in the app, a fake in tests.
abstract class LeaderboardBackend {
  /// The anonymous player id; null when sign-in fails (offline on the first launch).
  Future<String?> uid();

  /// Fastest times of a daily by player id, at most [limit].
  Future<Map<String, int>> fastest(GameKind kind, int day, int limit);

  /// Players per time bucket of a daily.
  Future<Map<int, int>> buckets(GameKind kind, int day);

  /// Stores the time and counts it in its bucket, both at once; rejected if the player already has a time.
  Future<void> writeDaily(GameKind kind, int day, String uid, int millis);

  Future<void> writeProfile(String uid, {required int bestStreak, required int solved});

  /// Highest values of a profile field ('streak' or 'solved') by player id.
  Future<Map<String, int>> topProfiles(String field, int limit);
}

class BackendLeaderboardService implements LeaderboardService {
  BackendLeaderboardService(this._backend);

  final LeaderboardBackend _backend;
  static const _timeout = Duration(seconds: 8);

  @override
  Future<DailyStanding?> submitDaily(GameKind kind, int day, int millis) async {
    if (millis < minDailyMillis) return standing(kind, day, myMillis: millis);
    try {
      final uid = await _backend.uid();
      if (uid != null) await _backend.writeDaily(kind, day, uid, millis).timeout(_timeout);
    } catch (e) {
      debugPrint('leaderboard submit: $e'); // already posted (another device or a reinstall), or offline
    }
    return standing(kind, day, myMillis: millis);
  }

  @override
  Future<DailyStanding?> standing(GameKind kind, int day, {int? myMillis}) async {
    try {
      final uid = await _backend.uid();
      final results = await Future.wait([
        _backend.fastest(kind, day, DailyStanding.topSize),
        _backend.buckets(kind, day),
      ]).timeout(_timeout);
      final fastest = results[0] as Map<String, int>;
      final counts = results[1] as Map<int, int>;
      final ids = fastest.keys.toList()..sort((a, b) => fastest[a]!.compareTo(fastest[b]!));
      final total = counts.values.fold(0, (a, b) => a + b);
      return DailyStanding(
        top: [for (final id in ids) (fastest[id]!, id == uid)],
        total: total < ids.length ? ids.length : total,
        counts: counts,
        myMillis: myMillis ?? (uid == null ? null : fastest[uid]),
        myId: uid,
      );
    } catch (e) {
      debugPrint('leaderboard standing: $e');
      return null;
    }
  }

  @override
  Future<void> submitProfile({required int bestStreak, required int solved}) async {
    try {
      final uid = await _backend.uid();
      if (uid != null) await _backend.writeProfile(uid, bestStreak: bestStreak, solved: solved).timeout(_timeout);
    } catch (e) {
      debugPrint('leaderboard profile: $e');
    }
  }

  @override
  Future<AllTimeBoards?> allTime() async {
    try {
      final uid = await _backend.uid();
      final results = await Future.wait([
        _backend.topProfiles('streak', 5),
        _backend.topProfiles('solved', 5),
      ]).timeout(_timeout);
      List<(int, bool)> rank(Map<String, int> m) {
        final ids = m.keys.toList()..sort((a, b) => m[b]!.compareTo(m[a]!));
        return [for (final id in ids) (m[id]!, id == uid)];
      }

      return AllTimeBoards(bestStreaks: rank(results[0]), solved: rank(results[1]));
    } catch (e) {
      debugPrint('leaderboard all time: $e');
      return null;
    }
  }
}

/// Cloud Firestore, anonymous players, times only (no names).
///
/// `dailies/{kind}_{day}` holds the bucket counts (`b`), `dailies/{kind}_{day}/times/{uid}` one time per player,
/// `players/{uid}` the lifetime records. The rules (firestore.rules) allow one time per player and daily, written
/// together with exactly one bucket increment, and App Check limits access to the genuine app.
class FirestoreLeaderboardBackend implements LeaderboardBackend {
  final _db = FirebaseFirestore.instance;

  @override
  Future<String?> uid() async {
    try {
      final auth = FirebaseAuth.instance;
      return auth.currentUser?.uid ?? (await auth.signInAnonymously()).user?.uid;
    } catch (e) {
      debugPrint('leaderboard sign-in: $e');
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>> _daily(GameKind kind, int day) =>
      _db.collection('dailies').doc('${kind.name}_$day');

  @override
  Future<Map<String, int>> fastest(GameKind kind, int day, int limit) async {
    final snap = await _daily(kind, day)
        .collection('times')
        .orderBy('ms')
        .limit(limit)
        .get(const GetOptions(source: Source.server));
    return {for (final d in snap.docs) d.id: d.data()['ms'] as int};
  }

  @override
  Future<Map<int, int>> buckets(GameKind kind, int day) async {
    final snap = await _daily(kind, day).get(const GetOptions(source: Source.server));
    final b = (snap.data()?['b'] as Map<String, dynamic>?) ?? const {};
    return {for (final e in b.entries) int.parse(e.key): (e.value as num).toInt()};
  }

  @override
  Future<void> writeDaily(GameKind kind, int day, String uid, int millis) async {
    final daily = _daily(kind, day);
    final batch = _db.batch()
      ..set(daily.collection('times').doc(uid), {'ms': millis})
      ..set(daily, {'b': {'${bucketOf(millis)}': FieldValue.increment(1)}}, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<void> writeProfile(String uid, {required int bestStreak, required int solved}) =>
      _db.collection('players').doc(uid).set({'streak': bestStreak, 'solved': solved});

  @override
  Future<Map<String, int>> topProfiles(String field, int limit) async {
    final snap = await _db
        .collection('players')
        .orderBy(field, descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.server));
    return {for (final d in snap.docs) d.id: (d.data()[field] as num).toInt()};
  }
}

/// App Check: Firestore only answers the genuine app (Play Integrity on Android, App Attest on iOS), so scripts can't
/// post times.
/// Debug builds use the debug provider; pass `--dart-define=APP_CHECK_DEBUG_TOKEN=<token registered in the console>`,
/// or read the token the SDK logs on first run and register it.
Future<void> initAppCheck() => FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(debugToken: _debugToken.isEmpty ? null : _debugToken)
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider(debugToken: _debugToken.isEmpty ? null : _debugToken)
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );

const _debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
