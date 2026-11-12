import 'package:critter_logic/services/review_service.dart';
import 'package:critter_logic/services/stats_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeReview implements ReviewService {
  int requests = 0;
  int listings = 0;
  @override
  Future<void> requestReview() async => requests++;
  @override
  Future<void> openStoreListing() async => listings++;
}

void main() {
  late StatsStore stats;
  late FakeReview review;
  var now = DateTime(2026, 11, 4);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
    review = FakeReview();
    now = DateTime(2026, 11, 4);
  });

  ReviewPrompter prompter() => ReviewPrompter(stats, review, now: () => now);

  test('prompts from the 3rd streak day, then waits for the cooldown', () async {
    await prompter().onDailySolved(2);
    expect(review.requests, 0);
    await prompter().onDailySolved(3);
    expect(review.requests, 1);
    expect(stats.reviewPromptedAt, now);
    now = now.add(const Duration(days: 13));
    await prompter().onDailySolved(16);
    expect(review.requests, 1, reason: 'cooldown');
    now = now.add(const Duration(days: 1));
    await prompter().onDailySolved(17);
    expect(review.requests, 2);
  });

  test('never once the player tapped Rate', () async {
    await stats.setReviewed(true);
    await prompter().onDailySolved(10);
    expect(review.requests, 0);
  });
}
