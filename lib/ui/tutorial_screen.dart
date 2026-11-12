import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../puzzles/nests/nests.dart';
import '../puzzles/pairs/pairs.dart';
import '../puzzles/puzzle.dart';
import '../puzzles/trail/trail.dart';
import '../services/sound_service.dart';
import 'critter_actor.dart';
import 'game/game_screen.dart';
import 'game/nests_board.dart';
import 'game/pairs_board.dart';
import 'game/session.dart';
import 'game/trail_board.dart';
import 'meadow.dart';
import 'palette.dart';
import 'services.dart';
import 'widgets.dart';

/// One tutorial step: a tiny board with a few cells to fill, introducing one rule.
class _Step {
  const _Step(this.text, this.initial, this.editable, {this.links = const [], this.path = const [], this.goal});

  final String Function(AppLocalizations) text;

  /// Starting cells: Nests marks as '.', 'x', 'c'; Pairs as '.', '0' (sun), '1' (moon).
  final String initial;
  final Set<int> editable;
  final List<PairsLink> links;

  /// Trail: the trail drawn at the start, and the cell to reach (null: finish the puzzle).
  final List<int> path;
  final int? goal;
}

// 4×4 Nests: zones by row with a twist, so each rule decides one step. Solution columns 1, 3, 0, 2.
final _nestsPuzzle = NestsPuzzle(
  size: 4,
  regions: const [0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 2],
  solution: const [1, 3, 0, 2],
);

final _nestsSteps = <_Step>[
  _Step((l) => l.tutNestsRow, 'x.xx............', {1}),
  _Step((l) => l.tutNestsColumn, '.c........xx....', {8, 9}),
  _Step((l) => l.tutNestsZone, '.c......c...xx..', {14, 15}),
  _Step((l) => l.tutNestsTouch, '.c..xx..c.....c.', {6, 7}),
];

const _pairsSolution = [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1];

final _pairsSteps = <_Step>[
  _Step((l) => l.tutPairsBalance, '010.............', {3}),
  _Step((l) => l.tutPairsThree, '0101.........00.', {12, 15}),
  _Step(
    (l) => l.tutPairsLinks,
    '0101....0...1001',
    {9, 10, 11},
    links: const [PairsLink(8, 9, same: false), PairsLink(9, 10, same: true), PairsLink(10, 11, same: false)],
  ),
];

// 4×4 Trail: stones 1–5 at cells 0, 3, 4, 13, 11; the hedge between 8 and 9 forces the way round by 12, the one
// between 5 and 9 is just scenery.
final _trailPuzzle = TrailPuzzle(
  size: 4,
  stones: const [0, 3, 4, 13, 11],
  walls: const [(8, 9), (5, 9)],
  solution: const [0, 1, 2, 3, 7, 6, 5, 4, 8, 12, 13, 9, 10, 14, 15, 11],
);

final _trailSteps = <_Step>[
  _Step((l) => l.tutTrailStart, '', const {}, goal: 3),
  _Step((l) => l.tutTrailOrder, '', const {}, path: const [0, 1, 2, 3], goal: 4),
  _Step((l) => l.tutTrailWalls, '', const {}, path: const [0, 1, 2, 3, 7, 6, 5, 4], goal: 13),
  _Step((l) => l.tutTrailFill, '', const {}, path: const [0, 1, 2, 3, 7, 6, 5, 4, 8, 12, 13]),
];

/// First-time tutorial: learn each rule by doing, on tiny boards. Pops `true` when finished or skipped.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, required this.kind});

  final GameKind kind;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;
  late GameSession _session;
  bool _stepDone = false;

  /// Trail: the last move was refused.
  bool _refused = false;

  List<_Step> get _steps => switch (widget.kind) {
    GameKind.nests => _nestsSteps,
    GameKind.pairs => _pairsSteps,
    GameKind.trail => _trailSteps,
  };

  @override
  void initState() {
    super.initState();
    _session = _build(_steps[0]);
  }

  GameSession _build(_Step step) {
    final GameSession session;
    if (widget.kind == GameKind.trail) {
      return TrailSession(_trailPuzzle, path: step.path);
    } else if (widget.kind == GameKind.nests) {
      session = NestsSession(
        _nestsPuzzle,
        initial: [
          for (final c in step.initial.split(''))
            c == 'c' ? NestMark.critter : (c == 'x' ? NestMark.cross : NestMark.empty),
        ],
      );
    } else {
      final givens = [for (final c in step.initial.split('')) c == '.' ? null : int.parse(c)];
      session = PairsSession(PairsPuzzle(size: 4, givens: givens, links: step.links, solution: _pairsSolution));
    }
    return session..editable = step.editable;
  }

  bool _isDone() {
    final s = _session;
    if (s is TrailSession) {
      final goal = _steps[_step].goal;
      return goal == null ? s.solved : s.head == goal;
    }
    final cells = _session.cells;
    for (final i in _steps[_step].editable) {
      final ok = widget.kind == GameKind.nests
          ? (cells[i] == NestMark.critter) == _nestsPuzzle.isCritterInSolution(i)
          : cells[i] == _pairsSolution[i];
      if (!ok) return false;
    }
    return true;
  }

  void _onMove(MoveOutcome outcome, int cell) {
    final sound = Services.of(context).sound;
    final s = _session;
    _refused = outcome == MoveOutcome.mistake;
    if (outcome == MoveOutcome.mistake) {
      sound.play(Sfx.conflict);
      HapticFeedback.mediumImpact();
    } else {
      sound.play(s is TrailSession && !s.onPath(cell) ? Sfx.erase : Sfx.place);
      HapticFeedback.lightImpact();
    }
    if (_isDone()) {
      sound.play(Sfx.solve);
      setState(() => _stepDone = true);
    } else {
      setState(() {});
    }
  }

  void _next() {
    if (_step + 1 < _steps.length) {
      setState(() {
        _step++;
        _session = _build(_steps[_step]);
        _stepDone = false;
        _refused = false;
      });
    } else {
      _finish(skipped: false);
    }
  }

  Future<void> _finish({required bool skipped}) async {
    final services = Services.of(context);
    final nav = Navigator.of(context);
    await services.stats.setTutorialDone(widget.kind);
    if (!skipped) services.analytics.tutorialDone(widget.kind.name);
    nav.pop(true);
  }

  String get _mascot => switch (widget.kind) {
    GameKind.nests => 'chick',
    GameKind.pairs => 'owl',
    GameKind.trail => 'rabbit',
  };

  /// Trail: the hand points where to start dragging (the trail's end), then at the cell to reach.
  Set<int> _trailTargets(TrailSession s, _Step step) {
    final goal = step.goal ?? _trailPuzzle.stones.last;
    return s.isPristine ? {s.head ?? _trailPuzzle.stones.first, goal} : {goal};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = _steps[_step];
    final last = _step == _steps.length - 1;
    final trail = widget.kind == GameKind.trail;
    final oops = trail ? _refused : _session.conflicts.isNotEmpty;
    return MeadowScaffold(
      child: Column(children: [
        MeadowTopBar(
          title: l10n.howToPlay(gameName(l10n, widget.kind)),
          backTooltip: l10n.back,
          trailing: [
            ChunkyButton(
              key: const Key('tutorialSkip'),
              label: l10n.skip,
              small: true,
              color: woodButton,
              onPressed: () => _finish(skipped: true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < _steps.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _step ? 30 : 14,
              height: 14,
              decoration: BoxDecoration(
                color: i <= _step ? leaf : paper,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: i <= _step ? leafEdge : paperEdge, width: 2),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        // The mascot explains the rule in a speech bubble.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            CritterBuddy(_mascot, size: 76, seed: 1),
            const SizedBox(width: 4),
            Expanded(
              child: PopIn(
                key: ValueKey(_step),
                child: SpeechBubble(
                  child: Text(
                    step.text(l10n),
                    key: const Key('tutorialText'),
                    style: chunky(17, weight: FontWeight.w600, height: 1.25),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 330, maxHeight: (box.maxHeight - 84).clamp(120, 330)),
                    child: switch (_session) {
                      final NestsSession s => NestsBoard(
                        key: ValueKey('tut$_step'),
                        session: s,
                        autoCross: false,
                        readOnly: _stepDone,
                        targets: _stepDone ? const {} : step.editable,
                        onMove: _onMove,
                      ),
                      final PairsSession s => PairsBoard(
                        key: ValueKey('tut$_step'),
                        session: s,
                        readOnly: _stepDone,
                        targets: _stepDone ? const {} : step.editable,
                        onMove: _onMove,
                      ),
                      final TrailSession s => TrailBoard(
                        key: ValueKey('tut$_step'),
                        session: s,
                        critter: _mascot,
                        readOnly: _stepDone,
                        targets: _stepDone ? const {} : _trailTargets(s, step),
                        onMove: _onMove,
                        onStrokeEnd: () => setState(() {}),
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 64,
                    child: _stepDone
                        ? PopIn(
                            child: ChunkyButton(
                              key: const Key('tutorialNext'),
                              label: last ? l10n.tutorialLetsPlay : l10n.tutorialNice,
                              color: leaf,
                              expand: true,
                              icon: Icon(last ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded, color: Colors.white),
                              onPressed: _next,
                            ),
                          )
                        : Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: oops ? accentSoft : paper.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: oops ? bad : paperEdge, width: 2),
                              ),
                              child: Text(
                                switch ((oops, trail)) {
                                  (true, true) => l10n.tutTrailOops,
                                  (true, false) => l10n.tutorialOops,
                                  (false, true) => l10n.tutTrailDragHint,
                                  (false, false) => l10n.tutorialTapHint,
                                },
                                textAlign: TextAlign.center,
                                style: chunky(15, color: oops ? bad : inkSoft, weight: FontWeight.w600),
                              ),
                            ),
                          ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// A paper speech bubble with a tail pointing left (at the mascot).
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _BubblePainter(),
        child: Padding(padding: const EdgeInsets.fromLTRB(26, 14, 16, 16), child: child),
      );
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const tail = 12.0;
    final body = RRect.fromLTRBR(tail, 0, size.width, size.height, const Radius.circular(20));
    final path = Path()
      ..addRRect(body)
      ..moveTo(tail + 2, size.height - 34)
      ..lineTo(0, size.height - 14)
      ..lineTo(tail + 16, size.height - 18)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 4)), Paint()..color = paperEdge);
    canvas.drawPath(path, Paint()..color = paper);
    canvas.drawRRect(body, Paint()
      ..color = paperEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}
