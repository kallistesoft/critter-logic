import 'package:critter_logic/puzzles/puzzle.dart';
import 'package:critter_logic/services/leaderboard_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory backend that enforces the same "one time per player" rule as firestore.rules.
class FakeBackend implements LeaderboardBackend {
  String? id = 'me';
  final times = <String, Map<String, int>>{};
  final counts = <String, Map<int, int>>{};
  final profiles = <String, Map<String, int>>{};
  bool offline = false;

  String _key(GameKind k, int day) => '${k.name}_$day';

  void seed(GameKind k, int day, Map<String, int> t) {
    for (final e in t.entries) {
      times.putIfAbsent(_key(k, day), () => {})[e.key] = e.value;
      final c = counts.putIfAbsent(_key(k, day), () => {});
      c[bucketOf(e.value)] = (c[bucketOf(e.value)] ?? 0) + 1;
    }
  }

  @override
  Future<String?> uid() async => id;

  @override
  Future<Map<String, int>> fastest(GameKind kind, int day, int limit) async {
    if (offline) throw Exception('offline');
    final t = times[_key(kind, day)] ?? {};
    final ids = t.keys.toList()..sort((a, b) => t[a]!.compareTo(t[b]!));
    return {for (final id in ids.take(limit)) id: t[id]!};
  }

  @override
  Future<Map<int, int>> buckets(GameKind kind, int day) async => counts[_key(kind, day)] ?? {};

  @override
  Future<void> writeDaily(GameKind kind, int day, String uid, int millis) async {
    if (offline) throw Exception('offline');
    if (times[_key(kind, day)]?.containsKey(uid) ?? false) throw Exception('permission-denied');
    seed(kind, day, {uid: millis});
  }

  @override
  Future<void> writeProfile(String uid, {required int bestStreak, required int solved}) async =>
      profiles[uid] = {'streak': bestStreak, 'solved': solved};

  @override
  Future<Map<String, int>> topProfiles(String field, int limit) async =>
      {for (final e in profiles.entries) e.key: e.value[field]!};
}

void main() {
  late FakeBackend backend;
  late BackendLeaderboardService service;

  setUp(() {
    backend = FakeBackend();
    service = BackendLeaderboardService(backend);
  });

  test('buckets', () {
    expect(bucketOf(0), 0);
    expect(bucketOf(9999), 0);
    expect(bucketOf(10000), 1);
    expect(bucketOf(3600000), lastBucket);
  });

  test('first attempt is posted and ranked; a second one is ignored', () async {
    backend.seed(GameKind.nests, 5, {'a': 30000, 'b': 90000});
    final s = (await service.submitDaily(GameKind.nests, 5, 45000))!;
    expect(s.top, [(30000, false), (45000, true), (90000, false)]);
    expect(s.rank, 2);
    expect(s.total, 3);
    expect(s.fasterThan, isNull, reason: 'fewer than 20 players');

    final again = (await service.submitDaily(GameKind.nests, 5, 5000))!;
    expect(backend.times['nests_5']!['me'], 45000, reason: 'server keeps the first time');
    expect(again.rank, 2);
  });

  test('outside the top 10: rank and percentile from the buckets', () async {
    backend.seed(GameKind.pairs, 1, {for (var i = 0; i < 30; i++) 'p$i': 20000 + i * 5000}); // 20 s .. 165 s
    final s = (await service.submitDaily(GameKind.pairs, 1, 100000))!;
    expect(s.top.length, DailyStanding.topSize);
    expect(s.top.any((e) => e.$2), isFalse);
    expect(s.total, 31);
    expect(s.rank, inInclusiveRange(15, 18));
    expect(s.fasterThan, inInclusiveRange(0.4, 0.55));
  });

  test('impossible times are not posted', () async {
    await service.submitDaily(GameKind.nests, 2, 1000);
    expect(backend.times['nests_2'], isNull);
  });

  test('offline: no standing, no throw', () async {
    backend.offline = true;
    expect(await service.submitDaily(GameKind.nests, 3, 40000), isNull);
  });

  test('all-time boards', () async {
    backend.profiles['x'] = {'streak': 40, 'solved': 10};
    await service.submitProfile(bestStreak: 12, solved: 99);
    final all = (await service.allTime())!;
    expect(all.bestStreaks, [(40, false), (12, true)]);
    expect(all.solved, [(99, true), (10, false)]);
  });
}
