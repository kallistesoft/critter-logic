import 'package:critter_logic/services/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('today at 19:00 while ahead and not done, then the next days', () {
    final p = plannedReminders(DateTime(2026, 12, 3, 9), todayDone: false);
    expect(p, [DateTime(2026, 12, 3, 19), DateTime(2026, 12, 4, 19), DateTime(2026, 12, 5, 19)]);
  });

  test('starts tomorrow once today is done or 19:00 has passed', () {
    expect(plannedReminders(DateTime(2026, 12, 3, 9), todayDone: true).first, DateTime(2026, 12, 4, 19));
    expect(plannedReminders(DateTime(2026, 12, 3, 20), todayDone: false).first, DateTime(2026, 12, 4, 19));
  });

  test('month end', () {
    expect(plannedReminders(DateTime(2026, 12, 31, 20), todayDone: false), [
      DateTime(2027, 1, 1, 19),
      DateTime(2027, 1, 2, 19),
      DateTime(2027, 1, 3, 19),
    ]);
  });
}
