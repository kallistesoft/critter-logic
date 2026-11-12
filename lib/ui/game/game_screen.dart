import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../meta/economy.dart';
import '../../meta/game_flow.dart';
import '../../meta/level_ad_pacer.dart';
import '../../meta/retention.dart';
import '../../puzzles/nests/nests.dart';
import '../../puzzles/puzzle.dart';
import '../../services/share_text.dart';
import '../../services/sound_service.dart';
import '../../services/stats_store.dart';
import '../coin_fly.dart';
import '../critter_actor.dart';
import '../meadow.dart';
import '../navigation.dart';
import '../palette.dart';
import '../result_screen.dart';
import '../retention_ui.dart';
import '../services.dart';
import '../widgets.dart';
import 'confetti.dart';
import 'nests_board.dart';
import 'pairs_board.dart';
import 'session.dart';
import 'trail_board.dart';

String gameName(AppLocalizations l10n, GameKind kind) => switch (kind) {
      GameKind.nests => l10n.gameNests,
      GameKind.pairs => l10n.gamePairs,
      GameKind.trail => l10n.gameTrail,
    };

/// The one-line rules under the board.
String rulesShort(AppLocalizations l10n, GameKind kind) => switch (kind) {
      GameKind.nests => l10n.nestsRulesShort,
      GameKind.pairs => l10n.pairsRulesShort,
      GameKind.trail => l10n.trailRulesShort,
    };

/// The critter that sits on a Nests board (and walks the Trail): one the player owns, changing with the puzzle.
String boardCritter(StatsStore stats, int number) {
  final owned = stats.owned.toList()..sort();
  return owned.isEmpty ? 'chick' : owned[number % owned.length];
}

/// One puzzle being played, daily or level: board, timer, undo, restart, hint.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.kind, required this.mode, required this.number, this.pacer});

  final GameKind kind;
  final PlayMode mode;

  /// Daily number or level.
  final int number;
  /// Interstitial pacing; null reads it from Remote Config ([Services.settings]).
  final LevelAdPacer? pacer;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  late Services _services;
  GameSession? _session;
  bool _started = false;
  bool _finishing = false;
  bool _levelWon = false;
  int _levelCoins = 0;
  int _stars = 0;

  /// Coins already paid but not landed on the counter yet (coin-fly).
  int _coinsHeld = 0;
  final _coinTarget = GlobalKey();
  final _rewardKey = GlobalKey();
  int _elapsedBase = 0;
  DateTime? _runningSince;
  Timer? _ticker;
  int _shownSeconds = 0;
  late String _critter;
  late final _celebrate = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  bool get _daily => widget.mode == PlayMode.daily;
  String get _slot => saveSlot(widget.kind, widget.mode);

  int get _elapsed =>
      _elapsedBase + (_runningSince == null ? 0 : _services.today().difference(_runningSince!).inMilliseconds.clamp(0, 7 * 86400000));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _services = Services.of(context);
    if (!_started) {
      _started = true;
      _critter = boardCritter(_services.stats, widget.number);
      _load();
    }
  }

  Future<void> _load() async {
    final p = _services.puzzles;
    final daily = _daily;
    final GameSession session = switch (widget.kind) {
      GameKind.nests => NestsSession(await (daily ? p.dailyNests(widget.number) : p.levelNests(widget.number))),
      GameKind.pairs => PairsSession(await (daily ? p.dailyPairs(widget.number) : p.levelPairs(widget.number))),
      GameKind.trail => TrailSession(await (daily ? p.dailyTrail(widget.number) : p.levelTrail(widget.number))),
    };
    final saved = _services.stats.savedGame(_slot);
    if (saved != null && saved['n'] == widget.number && session.restore(saved) && !session.solved) {
      _elapsedBase = saved['e'] as int? ?? 0;
    } else if (saved != null) {
      await _services.stats.clearGame(_slot);
    }
    if (!mounted) return;
    setState(() => _session = session);
    _services.analytics.levelStart(widget.kind.name, daily: daily, level: daily ? null : widget.number);
    _resume();
  }

  void _resume() {
    if (_finishing || _session == null || _runningSince != null) return;
    _runningSince = _services.today();
    // Repaints only when the shown second changes (so tests with a fixed clock settle).
    _ticker ??= Timer.periodic(const Duration(milliseconds: 500), (_) {
      final shown = _elapsed ~/ 1000;
      if (mounted && _runningSince != null && shown != _shownSeconds) setState(() => _shownSeconds = shown);
    });
  }

  void _pause() {
    if (_runningSince != null) {
      _elapsedBase = _elapsed;
      _runningSince = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else {
      _pause();
      _save();
    }
  }

  void _save() {
    final s = _session;
    if (s == null || _finishing || s.solved) return;
    _services.stats.saveGame(_slot, {...s.toJson(), 'n': widget.number, 'e': _elapsed});
  }

  @override
  void dispose() {
    _save();
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _celebrate.dispose();
    super.dispose();
  }

  // ---- Moves ----

  void _onMove(MoveOutcome outcome, int cell) {
    final s = _session!;
    final sound = _services.sound;
    if (outcome == MoveOutcome.mistake) {
      sound.play(Sfx.conflict);
      HapticFeedback.mediumImpact();
    } else if (s is TrailSession) {
      // A soft tick for each step the trail grows, a softer one when it shrinks.
      sound.play(s.onPath(cell) ? Sfx.place : Sfx.erase);
      HapticFeedback.selectionClick();
    } else {
      final value = s.cells[cell];
      sound.play(switch (value) {
        NestMark.critter => Sfx.place,
        NestMark.cross => Sfx.cross,
        NestMark.empty || null => Sfx.erase,
        _ => Sfx.place,
      });
      HapticFeedback.lightImpact();
    }
    _afterChange();
  }

  void _afterChange() {
    setState(() {});
    if (_session!.solved) {
      _onSolved();
    } else {
      _save();
    }
  }

  Future<void> _hint() async {
    final s = _session;
    if (s == null || s.solved || _finishing || s.findHint() == null) return;
    final services = _services;
    final l10n = AppLocalizations.of(context);
    if (await services.retention.progress.useFreeHint()) {
      services.sound.play(Sfx.coin);
      services.analytics.hintUsed(widget.kind.name, paidWith: 'free');
    } else if (await services.stats.spendCoins(Economy.hintCost)) {
      services.sound.play(Sfx.coin);
      services.analytics.hintUsed(widget.kind.name, paidWith: 'coins');
    } else {
      if (!mounted) return;
      final watch = await showSoftDialog<bool>(
        context,
        emoji: '💡',
        title: l10n.hintNoCoinsTitle,
        body: l10n.hintNoCoinsBody(Economy.hintCost),
        actions: [
          ChunkyButton(
            key: const Key('hintWatchAd'),
            label: l10n.watchVideo,
            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
            expand: true,
            onPressed: () => Navigator.pop(context, true),
          ),
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel, style: chunky(15, color: inkSoft))),
        ],
      );
      if (watch != true) return;
      _pause();
      final earned = await services.ads.showRewarded();
      _resume();
      if (!earned) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noAdAvailable)));
        return;
      }
      services.analytics.adReward('hint');
      services.analytics.hintUsed(widget.kind.name, paidWith: 'ad');
    }
    if (!mounted) return;
    s.applyHint();
    services.sound.play(Sfx.place);
    HapticFeedback.lightImpact();
    _afterChange();
  }

  void _undo() {
    _session?.undo();
    _services.sound.play(Sfx.erase);
    _afterChange();
  }

  void _restart() {
    _session?.restart();
    _services.sound.play(Sfx.erase);
    _afterChange();
  }

  // ---- Solved ----

  Future<void> _onSolved() async {
    if (_finishing) return;
    final s = _session!;
    final services = _services;
    final stats = services.stats;
    _pause();
    final elapsed = _elapsed;
    setState(() => _finishing = true);
    _ticker?.cancel();
    await stats.clearGame(_slot);
    services.sound.play(Sfx.solve);
    HapticFeedback.heavyImpact();
    services.analytics.levelComplete(widget.kind.name,
        daily: _daily,
        level: _daily ? null : widget.number,
        seconds: elapsed ~/ 1000,
        mistakes: s.mistakes,
        hints: s.hints);
    final celebration = _celebrate.forward();

    if (_daily) {
      final result = DailyResult(
        kind: widget.kind,
        number: widget.number,
        millis: rankedMillis(elapsed, mistakes: s.mistakes, hints: s.hints),
        mistakes: s.mistakes,
        hints: s.hints,
      );
      final first = await stats.recordDaily(result);
      final rewards = first ? await grantDailyRewards(stats, widget.number) : null;
      if (first) services.analytics.setUserState(levelsWon: stats.levelsWon, streak: rewards!.streak);
      final update = first ? await services.retention.recordEvent(DailySolved(result), services.today()) : null;
      await celebration;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(softRoute(DailyResultScreen(
        kind: widget.kind,
        number: widget.number,
        result: stats.daily(widget.kind, widget.number) ?? result,
        fresh: first,
        rewards: rewards,
        retention: update,
      )));
    } else {
      _levelCoins = levelReward(hints: s.hints);
      _coinsHeld = _levelCoins;
      _stars = starsFor(hints: s.hints, mistakes: s.mistakes);
      await stats.recordLevelStars(widget.kind, widget.number, _stars);
      await stats.addCoins(_levelCoins);
      await stats.addLevelWon();
      if (stats.level(widget.kind) <= widget.number) await stats.setLevel(widget.kind, widget.number + 1);
      final update = await services.retention.recordEvent(LevelWon(widget.kind, hints: s.hints), services.today());
      services.analytics.setUserState(levelsWon: stats.levelsWon, streak: stats.streak(todayNumber(services.today())));
      await celebration;
      if (!mounted) return;
      setState(() => _levelWon = true);
      await _flyRewardCoins();
      if (mounted) await showRetentionUpdate(context, update);
    }
  }

  /// The win panel's coins fly up to the counter, which rolls up as they land.
  Future<void> _flyRewardCoins() async {
    final motion = ambientMotion(context);
    if (motion) await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final total = _levelCoins;
    const pieces = 8;
    await flyCoins(context, from: _rewardKey, to: _coinTarget, coins: pieces, onArrive: (n) {
      if (mounted) setState(() => _coinsHeld = total - (total * n / pieces).round());
    });
    if (mounted) setState(() => _coinsHeld = 0);
  }

  bool _adShown = false;

  Future<void> _afterLevel({required bool next}) async {
    final services = _services;
    final nav = Navigator.of(context);
    final settings = services.settings.value;
    final pacer = widget.pacer ??
        LevelAdPacer(
          firstAfter: settings.interstitialFirstLevel < 1 ? 1 : settings.interstitialFirstLevel,
          every: settings.interstitialEvery,
        );
    if (!_adShown && pacer.shouldShow(services.stats.levelsWon)) {
      _adShown = true;
      await services.ads.showInterstitial();
    }
    if (!mounted) return;
    if (next) {
      nav.pushReplacement(softRoute(GameScreen(kind: widget.kind, mode: PlayMode.level, number: widget.number + 1, pacer: widget.pacer)));
    } else {
      nav.pop();
    }
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = _session;
    return MeadowScaffold(
      banner: true,
      overlays: [
        Positioned.fill(child: Confetti(animation: _celebrate)),
        if (_finishing && !_levelWon)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: PopIn(
                  child: Transform.rotate(
                    angle: -0.06,
                    child: Text(l10n.solved, style: outlinedText(60, color: const Color(0xFFFFE066), stroke: woodEdge, width: 4)),
                  ),
                ),
              ),
            ),
          ),
        if (_levelWon) _levelWinPanel(l10n),
      ],
      child: Column(children: [
        _topBar(l10n),
        const SizedBox(height: 8),
        _clockRow(l10n),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: s == null
                    ? const Center(child: CircularProgressIndicator(color: leaf))
                    : BoardStage(
                        critters: buddyCritters(_services.stats, 2, seed: widget.number),
                        cheer: _finishing,
                        child: _board(s),
                      ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: paper.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: paperEdge, width: 2),
                ),
                child: Text(
                  rulesShort(l10n, widget.kind),
                  textAlign: TextAlign.center,
                  style: chunky(14, color: inkSoft, weight: FontWeight.w500),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        _toolbar(l10n),
        const SizedBox(height: 10),
      ]),
    );
  }

  Widget _board(GameSession s) {
    final celebrate = _celebrate.view;
    return switch (s) {
      NestsSession() => NestsBoard(
          session: s,
          critter: _critter,
          autoCross: _services.stats.autoCross,
          readOnly: _finishing,
          celebrate: celebrate,
          onMove: _onMove,
        ),
      PairsSession() => PairsBoard(session: s, readOnly: _finishing, celebrate: celebrate, onMove: _onMove),
      TrailSession() => TrailBoard(
          session: s,
          critter: _critter,
          readOnly: _finishing,
          celebrate: celebrate,
          onMove: _onMove,
          onStrokeEnd: () => setState(() {}),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _topBar(AppLocalizations l10n) => MeadowTopBar(
        backKey: const Key('back'),
        backTooltip: l10n.back,
        title: gameName(l10n, widget.kind),
        subtitle: _daily ? l10n.dailyTitle(widget.number) : l10n.levelTitle(widget.number),
        trailing: [CoinCounter(key: const Key('coins'), value: _services.stats.coins - _coinsHeld, iconKey: _coinTarget)],
      );

  Widget _clockRow(AppLocalizations l10n) {
    final s = _session;
    final penalty = s == null || !_daily ? 0 : rankedMillis(0, mistakes: s.mistakes, hints: s.hints);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      StatPill(
        key: const Key('timer'),
        icon: const Icon(Icons.timer_rounded, color: skyEdge),
        text: formatTime(_elapsed),
      ),
      if (penalty > 0) ...[
        const SizedBox(width: 8),
        PopIn(
          key: ValueKey(penalty),
          child: StatPill(
            key: const Key('penalty'),
            icon: const Icon(Icons.warning_rounded, color: coralEdge),
            text: l10n.penaltySeconds(penalty ~/ 1000),
            color: accentSoft,
            textColor: coralEdge,
          ),
        ),
      ],
    ]);
  }

  Widget _toolbar(AppLocalizations l10n) {
    final s = _session;
    final active = s != null && !_finishing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Expanded(
          child: _ToolButton(
            key: const Key('undo'),
            icon: Icons.undo_rounded,
            label: l10n.undo,
            color: sky,
            onTap: active && s.canUndo ? _undo : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            key: const Key('restart'),
            icon: Icons.refresh_rounded,
            label: l10n.restart,
            color: woodButton,
            onTap: active && !s.isPristine ? _restart : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            key: const Key('hint'),
            icon: Icons.lightbulb_rounded,
            label: l10n.hint,
            color: gold,
            cost: Economy.hintCost,
            free: _services.retention.progress.freeHints,
            onTap: active ? _hint : null,
          ),
        ),
      ]),
    );
  }

  Widget _levelWinPanel(AppLocalizations l10n) {
    final cheer = buddyCritters(_services.stats, 3, seed: widget.number + 1);
    return Positioned.fill(
      child: Container(
        color: ink.withValues(alpha: 0.35),
        child: SafeArea(
          child: UiScale(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: PopIn(
                    duration: const Duration(milliseconds: 650),
                    child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 64),
                        child: SoftCard(
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 18),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(l10n.levelSolved(widget.number), textAlign: TextAlign.center, style: chunky(26)),
                            const SizedBox(height: 10),
                            StarRow(stars: _stars, size: 54),
                            const SizedBox(height: 12),
                            PopIn(
                              delay: const Duration(milliseconds: 1300),
                              child: Container(
                                key: _rewardKey,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: goldSoft,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: gold, width: 2.5),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const CoinIcon(size: 30),
                                  const SizedBox(width: 8),
                                  Text('+$_levelCoins', style: chunky(24, color: woodDark)),
                                ]),
                              ),
                            ),
                            if (_session!.hints == 0) ...[
                              const SizedBox(height: 8),
                              Text(l10n.noHintBonus,
                                  textAlign: TextAlign.center, style: chunky(15, color: inkSoft, weight: FontWeight.w500)),
                            ],
                            const SizedBox(height: 18),
                            ChunkyButton(
                              key: const Key('nextLevel'),
                              label: l10n.nextLevel,
                              expand: true,
                              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                              onPressed: () => _afterLevel(next: true),
                            ),
                            const SizedBox(height: 10),
                            ChunkyButton(
                              key: const Key('levelHome'),
                              label: l10n.levelMap,
                              expand: true,
                              small: true,
                              color: woodButton,
                              icon: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                              onPressed: () => _afterLevel(next: false),
                            ),
                          ]),
                        ),
                      ),
                      // Cheering critters sitting on the panel.
                      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        for (final (i, id) in cheer.indexed)
                          CritterBuddy(id, size: i == 1 ? 92 : 66, cheer: true, seed: i + 3, shadow: false),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The board with two critters peeking over its top edge (they hop when the puzzle is solved).
class BoardStage extends StatelessWidget {
  const BoardStage({super.key, required this.child, this.critters = const [], this.cheer = false, this.maxSide = 720});

  final Widget child;
  final List<String> critters;
  final bool cheer;
  final double maxSide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final peek = critters.isEmpty ? 0.0 : (box.maxWidth * 0.2).clamp(44.0, 110.0);
        const shown = 0.62;
        final side = [box.maxWidth, box.maxHeight - peek * shown, maxSide].reduce((a, b) => a < b ? a : b);
        return Center(
          heightFactor: 1,
          child: SizedBox(
            width: side,
            height: side + peek * shown,
            child: Stack(clipBehavior: Clip.none, children: [
              for (final (i, id) in critters.indexed)
                Positioned(
                  left: i == 0 ? side * 0.1 : null,
                  right: i == 0 ? null : side * 0.1,
                  top: 0,
                  child: CritterBuddy(id, size: peek, cheer: cheer, seed: i + 11, shadow: false),
                ),
              Positioned(left: 0, right: 0, bottom: 0, height: side, child: child),
            ]),
          ),
        );
      });
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.color, this.onTap, this.cost, this.free = 0});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final int? cost;

  /// Free hints won at the Lucky Nest: shown instead of the price while there are some.
  final int free;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final face = enabled ? color : Color.lerp(color, const Color(0xFFC9C3B8), 0.7)!;
    final rim = edgeOf(face);
    return Bouncy(
      onTap: onTap,
      builder: (context, p, child) {
        final pressed = p.clamp(0.0, 1.0);
        return CustomPaint(
          painter: CandyPainter(face: face, edge: rim, press: pressed, depth: 6, radius: 18),
          child: Padding(padding: EdgeInsets.only(top: 6 * pressed, bottom: 6 * (1 - pressed)), child: child),
        );
      },
      child: SizedBox(
        height: 60,
        child: Stack(clipBehavior: Clip.none, children: [
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 26, shadows: [Shadow(color: rim, offset: const Offset(0, 2))]),
              FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(label, maxLines: 1, style: outlinedText(14, stroke: rim, width: 1.3))),
            ]),
          ),
          if (free > 0)
            Positioned(
              right: -4,
              top: -10,
              child: Container(
                key: const Key('freeHints'),
                padding: const EdgeInsets.fromLTRB(4, 2, 7, 2),
                decoration: BoxDecoration(
                  color: leaf,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 14),
                  Text('×$free', style: outlinedText(12, stroke: leafEdge, width: 1)),
                ]),
              ),
            )
          else if (cost != null)
            Positioned(
              right: -4,
              top: -10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(3, 2, 7, 2),
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: woodEdge.withValues(alpha: 0.7), width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const CoinIcon(size: 16),
                  const SizedBox(width: 2),
                  Text('$cost', style: chunky(12, color: woodDark)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
