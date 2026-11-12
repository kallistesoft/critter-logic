import 'dart:math';

import 'package:critter_logic/meta/album.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/meta/rewards.dart';
import 'package:critter_logic/meta/weekly_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProgressStore progress;
  late WeeklyEvent event;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    progress = await ProgressStore.open();
    event = WeeklyEvent(progress);
  });

  test('weeks run Monday to Sunday, local time, and rotate through the sets', () {
    final s = event.current(DateTime(2026, 12, 2, 15))!; // Wednesday
    expect(s.weekId, '2026-11-30');
    expect(s.theme, const EventTheme('polar', 'polar'));
    expect(s.startsAt, DateTime(2026, 11, 30));
    expect(s.endsAt, DateTime(2026, 12, 7));

    expect(event.current(DateTime(2026, 11, 30, 0, 0, 0))!.weekId, '2026-11-30', reason: 'Monday midnight');
    expect(event.current(DateTime(2026, 12, 6, 23, 59, 59))!.weekId, '2026-11-30', reason: 'Sunday night');
    final next = event.current(DateTime(2026, 12, 7))!;
    expect(next.weekId, '2026-12-07');
    expect(next.theme.id, 'panda');
    expect(next.theme.set, 'friends');

    final themes = [for (var w = 0; w < 6; w++) event.current(DateTime(2026, 11, 30 + 7 * w, 12))!.theme.set];
    expect(themes, ['polar', 'friends', 'jungle', 'savanna', 'farm', 'polar']);
    expect(themes.take(5).toSet(), albumSets.toSet());

    // Before the rotation start it still cycles (no negative index).
    expect(event.current(DateTime(2026, 11, 25))!.theme.set, 'farm');
    // Across New Year: Monday 2026-12-28, the week holds Jan 3 2027.
    expect(event.current(DateTime(2027, 1, 3, 20))!.weekId, '2026-12-28');
  });

  test('a week with a daylight saving change still ends at local midnight Monday', () {
    final s = event.current(DateTime(2027, 3, 14, 12))!; // spring forward Sunday
    expect(s.weekId, '2027-03-08');
    expect(s.endsAt, DateTime(2027, 3, 15));
    expect(event.current(DateTime(2027, 3, 15, 0, 30))!.weekId, '2027-03-15');
    final fall = event.current(DateTime(2027, 11, 7, 23, 30))!; // fall back Sunday
    expect(fall.weekId, '2027-11-01');
    expect(fall.endsAt, DateTime(2027, 11, 8));
  });

  test('tokens cross thresholds, and progress resets with the new week', () async {
    final mon = DateTime(2026, 11, 30, 10);
    expect(await event.addTokens(mon, 3), isEmpty);
    expect(await event.addTokens(mon, 3), [5]);
    expect(await event.addTokens(mon, 30), [15, 30]);
    expect(await event.addTokens(mon, 3), isEmpty);
    final s = event.current(mon)!;
    expect(s.tokens, 39);
    expect(s.claimable, [5, 15, 30]);
    expect(s.fraction, 1);
    expect(s.nextThreshold, isNull);
    expect(event.current(DateTime(2026, 12, 7))!.tokens, 0);
  });

  test('claims resolve the prize once each', () async {
    final now = DateTime(2026, 12, 1);
    await event.addTokens(now, 30);
    final rnd = Random(1);
    expect(await event.claim(now, 5, {}, rnd), const Reward(coins: 40));
    expect(await event.claim(now, 5, {}, rnd), isNull);
    expect(await event.claim(now, 7, {}, rnd), isNull, reason: 'not a threshold');
    expect(await event.claim(now, 15, {}, rnd), const Reward(capsules: 1));
    final top = await event.claim(now, 30, {'moose', 'bear'}, rnd);
    expect(top!.cosmetic, 'frame.polar');
    expect(['walrus', 'whale', 'penguin'], contains(top.critter), reason: 'missing, not golden');
    expect(event.current(now)!.claimable, isEmpty);
  });

  test('the top prize falls back to coins when the set is complete but for the golden one', () {
    const prize = EventPrize(critter: true, cosmetic: true);
    final owned = {for (final c in album) if (c.set == 'polar' && c.rarity != Rarity.golden) c.id};
    final r = prize.resolve(const EventTheme('polar', 'polar'), owned, Random(0));
    expect(r.critter, isNull);
    expect(r.coins, critterFallbackCoins);
  });

  test('not reached thresholds cannot be claimed', () async {
    final now = DateTime(2026, 12, 1);
    await event.addTokens(now, 4);
    expect(await event.claim(now, 5, {}, Random(0)), isNull);
  });

  test('events can be switched off', () async {
    event = WeeklyEvent(progress, settings: EventSettings.parse('{"enabled": false}'));
    expect(event.current(DateTime(2026, 12, 1)), isNull);
    expect(await event.addTokens(DateTime(2026, 12, 1), 10), isEmpty);
  });

  group('Remote Config JSON', () {
    test('empty or broken JSON gives the defaults', () {
      for (final raw in ['', '  ', 'not json', '[1,2]', '{"thresholds": "x"}']) {
        final s = EventSettings.parse(raw);
        expect(s.thresholds, [5, 15, 30], reason: raw);
        expect(s.rotation, EventSettings.defaultRotation);
        expect((s.tokensPerDaily, s.tokensPerLevel, s.enabled), (3, 1, true));
      }
    });

    test('valid fields override, bad fields fall back one by one', () {
      final s = EventSettings.parse('''{
        "thresholds": [10, 20],
        "prizes": [{"coins": 25}, {"critter": true, "golden_capsules": 1}],
        "tokens_daily": 5,
        "tokens_level": -1,
        "rotation": [{"theme": "panda", "set": "friends"}, {"theme": "jungle", "set": "jungle"}],
        "weeks": {"2026-12-21": {"theme": "winter", "set": "polar"}, "2026-12-22": {"theme": "x", "set": "polar"},
                  "2026-12-28": {"theme": "dragon", "set": "dragons"}}
      }''');
      expect(s.thresholds, [10, 20]);
      expect(s.prizes, const [EventPrize(coins: 25), EventPrize(critter: true, goldenCapsules: 1)]);
      expect(s.tokensPerDaily, 5);
      expect(s.tokensPerLevel, 1, reason: 'negative');
      expect(s.rotation.map((t) => t.id), ['panda', 'jungle']);
      expect(s.weeks, {'2026-12-21': const EventTheme('winter', 'polar')}, reason: 'not a Monday / unknown set');

      final e = WeeklyEvent(progress, settings: s);
      expect(e.current(DateTime(2026, 12, 24))!.theme.id, 'winter');
      expect(e.current(DateTime(2026, 11, 30))!.theme.id, 'panda');
      expect(e.current(DateTime(2026, 12, 7))!.theme.id, 'jungle');
    });

    test('thresholds must increase and match the prizes', () {
      const d = EventSettings();
      for (final raw in [
        '{"thresholds": [10, 5], "prizes": [{"coins": 1}, {"coins": 2}]}',
        '{"thresholds": [5, 10], "prizes": [{"coins": 1}]}',
        '{"thresholds": [0, 10], "prizes": [{"coins": 1}, {"coins": 2}]}',
        '{"thresholds": [5, 10], "prizes": [{"coins": 1}, {}]}',
        '{"thresholds": [5, 10], "prizes": [{"coins": 1}, {"coins": 5000}]}',
        '{"thresholds": [5, 10], "prizes": [{"coins": 1}, {"critter": "yes"}]}',
        '{"thresholds": [1,2,3,4,5,6], "prizes": [{"coins":1},{"coins":1},{"coins":1},{"coins":1},{"coins":1},{"coins":1}]}',
      ]) {
        final s = EventSettings.parse(raw);
        expect(s.thresholds, d.thresholds, reason: raw);
        expect(s.prizes, d.prizes, reason: raw);
      }
    });

    test('a rotation with one bad theme is ignored whole', () {
      final s = EventSettings.parse('{"rotation": [{"theme": "panda", "set": "friends"}, {"theme": "Bad!", "set": "farm"}]}');
      expect(s.rotation, EventSettings.defaultRotation);
    });
  });
}
