import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../puzzles/nests/nests.dart';
import '../puzzles/pairs/pairs.dart';
import '../puzzles/puzzle.dart';
import '../services/sound_service.dart';
import 'game/game_screen.dart';
import 'game/nests_board.dart';
import 'game/pairs_board.dart';
import 'game/session.dart';
import 'palette.dart';
import 'services.dart';
import 'widgets.dart';

/// One tutorial step: a tiny board with a few cells to fill, introducing one rule.
class _Step {
  const _Step(this.text, this.initial, this.editable, {this.links = const []});

  final String Function(AppLocalizations) text;

  /// Starting cells: Nests marks as '.', 'x', 'c'; Pairs as '.', '0' (sun), '1' (moon).
  final String initial;
  final Set<int> editable;
  final List<PairsLink> links;
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

  List<_Step> get _steps => widget.kind == GameKind.nests ? _nestsSteps : _pairsSteps;

  @override
  void initState() {
    super.initState();
    _session = _build(_steps[0]);
  }

  GameSession _build(_Step step) {
    final GameSession session;
    if (widget.kind == GameKind.nests) {
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
    if (outcome == MoveOutcome.mistake) {
      sound.play(Sfx.conflict);
      HapticFeedback.mediumImpact();
    } else {
      sound.play(Sfx.place);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = _steps[_step];
    final last = _step == _steps.length - 1;
    return Scaffold(
      backgroundColor: background,
      body: ScreenFrame(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.maybePop(context),
                    tooltip: l10n.back,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.howToPlay(gameName(l10n, widget.kind)), style: chunky(22))),
                  TextButton(
                    key: const Key('tutorialSkip'),
                    onPressed: () => _finish(skipped: true),
                    child: Text(
                      l10n.skip,
                      style: chunky(16, color: inkSoft, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _step ? 26 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i <= _step ? accent : accentSoft,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              PopIn(
                key: ValueKey(_step),
                child: SoftCard(
                  child: Row(
                    children: [
                      Text(widget.kind == GameKind.nests ? '🐤' : '☀️', style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.text(l10n),
                          key: const Key('tutorialText'),
                          style: chunky(17, weight: FontWeight.w800, height: 1.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 320, maxHeight: (box.maxHeight - 80).clamp(120, 320)),
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
                            _ => const SizedBox.shrink(),
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 60,
                          child: _stepDone
                              ? PopIn(
                                  child: ChunkyButton(
                                    key: const Key('tutorialNext'),
                                    label: last ? l10n.tutorialLetsPlay : l10n.tutorialNice,
                                    color: good,
                                    expand: true,
                                    icon: Icon(
                                      last ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: _next,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _session.conflicts.isNotEmpty ? l10n.tutorialOops : l10n.tutorialTapHint,
                                    textAlign: TextAlign.center,
                                    style: chunky(
                                      15,
                                      color: _session.conflicts.isNotEmpty ? bad : inkSoft,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
