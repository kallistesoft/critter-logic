import 'package:flutter/material.dart';

import '../meta/game_flow.dart';
import '../puzzles/puzzle.dart';
import 'game/game_screen.dart';
import 'result_screen.dart';
import 'services.dart';
import 'tutorial_screen.dart';

/// Soft fade-and-rise page transition.
Route<T> softRoute<T>(Widget screen) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
            child: child,
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
