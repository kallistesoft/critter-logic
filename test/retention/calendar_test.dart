import 'package:critter_logic/meta/login_calendar.dart';
import 'package:critter_logic/meta/progress_store.dart';
import 'package:critter_logic/meta/rewards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProgressStore progress;
  late LoginCalendar calendar;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    progress = await ProgressStore.open();
    calendar = LoginCalendar(progress);
  });

  test('day 1 is claimable once, and the next step waits for the next local day', () async {
    final now = DateTime(2026, 12, 3, 9);
    var s = calendar.state(now);
    expect((s.step, s.claimedToday, s.available, s.canDouble), (0, false, true, true));
    expect(s.reward, const Reward.coins(20));

    final claim = await calendar.claim(now);
    expect(claim!.reward, const Reward.coins(20));
    expect(claim.doubled, isFalse);

    s = calendar.state(now.add(const Duration(hours: 5)));
    expect((s.step, s.claimedToday, s.available), (0, true, false));
    expect(await calendar.claim(DateTime(2026, 12, 3, 23, 59, 59)), isNull, reason: 'double claim same day');

    s = calendar.state(DateTime(2026, 12, 4, 0, 0, 1));
    expect((s.step, s.claimedToday, s.available), (1, false, true), reason: 'rolls over at local midnight');
  });

  test('missed days do not reset the track, and it loops after day 7', () async {
    final days = [1, 2, 5, 9, 10, 20, 21, 30];
    final steps = <int>[];
    for (final d in days) {
      final c = await calendar.claim(DateTime(2027, 1, d, 12));
      steps.add(c!.step);
    }
    expect(steps, [0, 1, 2, 3, 4, 5, 6, 0]);
    expect(calendar.state(DateTime(2027, 1, 30, 13)).loops, 1);
    expect(progress.calendarClaims, 8);
  });

  test('a rewarded ad doubles coin days only', () async {
    final c1 = await calendar.claim(DateTime(2027, 1, 1), doubled: true);
    expect(c1!.reward, const Reward.coins(40));
    expect(c1.doubled, isTrue);
    await calendar.claim(DateTime(2027, 1, 2));
    final s = calendar.state(DateTime(2027, 1, 3));
    expect(s.reward, const Reward.capsule());
    expect(s.canDouble, isFalse);
    final c3 = await calendar.claim(DateTime(2027, 1, 3), doubled: true);
    expect(c3!.reward, const Reward.capsule());
    expect(c3.doubled, isFalse);
  });

  test('the ad double can be switched off', () async {
    calendar = LoginCalendar(progress, adDouble: false);
    expect(calendar.state(DateTime(2027, 1, 1)).canDouble, isFalse);
    expect((await calendar.claim(DateTime(2027, 1, 1), doubled: true))!.reward, const Reward.coins(20));
  });

  test('setting the clock back does not allow a second claim', () async {
    await calendar.claim(DateTime(2027, 1, 10));
    expect(calendar.state(DateTime(2027, 1, 9)).available, isFalse);
    expect(await calendar.claim(DateTime(2027, 1, 9)), isNull);
    expect(await calendar.claim(DateTime(2027, 1, 11)), isNotNull);
  });

  test('daylight saving days count as one day each', () async {
    // US/Canada spring forward 2027-03-14 (23 h day) and fall back 2027-11-07 (25 h day).
    expect(await calendar.claim(DateTime(2027, 3, 13, 23, 30)), isNotNull);
    expect(await calendar.claim(DateTime(2027, 3, 14, 0, 30)), isNotNull);
    expect(await calendar.claim(DateTime(2027, 3, 14, 23, 30)), isNull, reason: 'same local day');
    expect(await calendar.claim(DateTime(2027, 3, 15, 0, 1)), isNotNull);

    expect(await calendar.claim(DateTime(2027, 11, 7, 0, 30)), isNotNull);
    expect(await calendar.claim(DateTime(2027, 11, 7, 23, 30)), isNull, reason: 'the 25 h day is still one day');
    expect(await calendar.claim(DateTime(2027, 11, 8, 0, 1)), isNotNull);
    expect(progress.calendarClaims, 5);
  });

  test('custom rewards from Remote Config', () async {
    calendar = LoginCalendar(progress, rewards: List.filled(7, const Reward.coins(5)));
    expect((await calendar.claim(DateTime(2027, 1, 1)))!.reward, const Reward.coins(5));
  });
}
