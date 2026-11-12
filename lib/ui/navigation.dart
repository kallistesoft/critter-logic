import 'package:flutter/material.dart';

import '../meta/game_flow.dart';
import '../puzzles/puzzle.dart';
import 'game/game_screen.dart';
import 'result_screen.dart';
import 'services.dart';
import 'tutorial_screen.dart';

/// Soft scale-and-fade page transition: the new page grows in gently over the meadow.
Route<T> softRoute<T>(Widget screen) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
        final fade = CurvedAnimation(parent: animation, curve: const Interval(0, 0.6, curve: Curves.easeOut));
        // The page underneath fades out as the new one arrives (pages are see-through over the shared world).
        final out = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: secondary, curve: const Interval(0, 0.5)));
        return FadeTransition(
          opacity: out,
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
          ),
        );
      },
    );

/// Opens a game: the tutorial first if it's the first time, then the puzzle, or the result of a solved daily.
Future<void> openGame(BuildContext context, GameKind kind, PlayMode mode, {bool replace = false}) async {
  final services = Services.of(context);
  final stats = services.stats;
  final nav = Navigator.of(context);
  if (!stats.tutorialDone(kind)) {
    final done = await nav.push<bool>(softRoute(TutorialScreen(kind: kind)));
    if (done != true) return;
  }
  final Widget screen;
  if (mode == PlayMode.daily) {
    final day = todayNumber(services.today());
    final result = stats.daily(kind, day);
    screen = result == null
        ? GameScreen(kind: kind, mode: mode, number: day)
        : DailyResultScreen(kind: kind, number: day, result: result);
  } else {
    screen = GameScreen(kind: kind, mode: mode, number: stats.level(kind));
  }
  await (replace ? nav.pushReplacement(softRoute(screen)) : nav.push(softRoute(screen)));
}
