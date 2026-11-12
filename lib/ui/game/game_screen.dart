import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../meta/economy.dart';
import '../../meta/game_flow.dart';
import '../../meta/level_ad_pacer.dart';
import '../../puzzles/nests/nests.dart';
import '../../puzzles/puzzle.dart';
import '../../services/share_text.dart';
import '../../services/sound_service.dart';
import '../../services/stats_store.dart';
import '../banner_slot.dart';
import '../critter_image.dart';
import '../navigation.dart';
import '../palette.dart';
import '../result_screen.dart';
import '../services.dart';
import '../widgets.dart';
import 'confetti.dart';
import 'nests_board.dart';
import 'pairs_board.dart';
import 'session.dart';

String gameName(AppLocalizations l10n, GameKind kind) => switch (kind) {
      GameKind.nests => l10n.gameNests,
      GameKind.pairs => l10n.gamePairs,
    };

/// The critter that sits on a Nests board: one the player owns, changing with the puzzle.
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
    if (await services.stats.spendCoins(Economy.hintCost)) {
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
      await celebration;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(softRoute(DailyResultScreen(
        kind: widget.kind,
        number: widget.number,
        result: stats.daily(widget.kind, widget.number) ?? result,
        fresh: first,
        rewards: rewards,
      )));
    } else {
      _levelCoins = levelReward(hints: s.hints);
      await stats.addCoins(_levelCoins);
      await stats.addLevelWon();
      if (stats.level(widget.kind) <= widget.number) await stats.setLevel(widget.kind, widget.number + 1);
      services.analytics.setUserState(levelsWon: stats.levelsWon, streak: stats.streak(todayNumber(services.today())));
      await celebration;
      if (!mounted) return;
      services.sound.play(Sfx.coin);
      setState(() => _levelWon = true);
    }
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
    return Scaffold(
      backgroundColor: background,
      body: Stack(children: [
        ScreenFrame(
          child: Column(children: [
            _topBar(l10n),
            const SizedBox(height: 8),
            _clockRow(l10n),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: s == null ? const Center(child: CircularProgressIndicator(color: accent)) : _board(s),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.kind == GameKind.nests ? l10n.nestsRulesShort : l10n.pairsRulesShort,
                textAlign: TextAlign.center,
                style: chunky(14, color: inkSoft, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            _toolbar(l10n),
            const SizedBox(height: 8),
            const BannerSlot(),
          ]),
        ),
        Positioned.fill(child: Confetti(animation: _celebrate)),
        if (_finishing && !_levelWon)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: PopIn(
                  child: Text(l10n.solved,
                      style: chunky(54, color: accent).copyWith(shadows: const [Shadow(color: Colors.white, blurRadius: 18)])),
                ),
              ),
            ),
          ),
        if (_levelWon) _levelWinPanel(l10n),
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
      _ => const SizedBox.shrink(),
    };
  }

  Widget _topBar(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          RoundIconButton(
              key: const Key('back'), icon: Icons.arrow_back_rounded, onPressed: () => Navigator.maybePop(context), tooltip: l10n.back),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(gameName(l10n, widget.kind), style: chunky(24)),
              Text(_daily ? l10n.dailyTitle(widget.number) : l10n.levelTitle(widget.number),
                  style: chunky(14, color: inkSoft, weight: FontWeight.w700)),
            ]),
          ),
          StatPill(key: const Key('coins'), emoji: '🪙', text: '${_services.stats.coins}'),
        ]),
      );

  Widget _clockRow(AppLocalizations l10n) {
    final s = _session;
    final penalty = s == null || !_daily ? 0 : rankedMillis(0, mistakes: s.mistakes, hints: s.hints);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      StatPill(key: const Key('timer'), emoji: '⏱️', text: formatTime(_elapsed)),
      if (penalty > 0) ...[
        const SizedBox(width: 8),
        PopIn(
          key: ValueKey(penalty),
          child: StatPill(
            key: const Key('penalty'),
            emoji: '⚠️',
            text: l10n.penaltySeconds(penalty ~/ 1000),
            color: accentSoft,
            textColor: const Color(0xFFC2512A),
          ),
        ),
      ],
    ]);
  }

  Widget _toolbar(AppLocalizations l10n) {
    final s = _session;
    final active = s != null && !_finishing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: _ToolButton(
            key: const Key('undo'),
            icon: Icons.undo_rounded,
            label: l10n.undo,
            onTap: active && s.canUndo ? _undo : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            key: const Key('restart'),
            icon: Icons.refresh_rounded,
            label: l10n.restart,
            onTap: active && !s.isPristine ? _restart : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            key: const Key('hint'),
            icon: Icons.lightbulb_rounded,
            label: l10n.hint,
            highlight: true,
            badge: '🪙${Economy.hintCost}',
            onTap: active ? _hint : null,
          ),
        ),
      ]),
    );
  }

  Widget _levelWinPanel(AppLocalizations l10n) {
    return Positioned.fill(
      child: Container(
        color: ink.withValues(alpha: 0.25),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: PopIn(
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CritterImage(_critter, size: 84),
                const SizedBox(height: 8),
                Text(l10n.levelSolved(widget.number), textAlign: TextAlign.center, style: chunky(26)),
                const SizedBox(height: 6),
                StatPill(emoji: '🪙', text: '+$_levelCoins', color: goldSoft),
                if (_session!.hints == 0) ...[
                  const SizedBox(height: 8),
                  Text(l10n.noHintBonus, style: chunky(14, color: inkSoft, weight: FontWeight.w700)),
                ],
                const SizedBox(height: 20),
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
                  label: l10n.home,
                  expand: true,
                  color: tileEmpty,
                  textColor: ink,
                  onPressed: () => _afterLevel(next: false),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, this.onTap, this.highlight = false, this.badge});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = enabled ? (highlight ? Colors.white : ink) : inkSoft.withValues(alpha: 0.5);
    final bg = highlight ? (enabled ? accent : accent.withValues(alpha: 0.4)) : surface;
    return Bouncy(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(color: highlight ? Color.lerp(accent, Colors.black, 0.18)! : shadow, offset: const Offset(0, 4), blurRadius: highlight ? 0 : 8),
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: fg, size: 24),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Text(badge!, style: chunky(12, color: fg, weight: FontWeight.w800)),
            ],
          ]),
          const SizedBox(height: 2),
          Text(label, style: chunky(13, color: fg, weight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
