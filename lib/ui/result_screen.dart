import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/game_flow.dart';
import '../puzzles/nests/nests.dart';
import '../puzzles/puzzle.dart';
import '../services/leaderboard_service.dart';
import '../services/review_service.dart';
import '../services/share_text.dart';
import '../services/sound_service.dart';
import '../services/stats_store.dart';
import 'critter_image.dart';
import 'game/confetti.dart';
import 'game/game_screen.dart';
import 'game/nests_board.dart';
import 'game/pairs_board.dart';
import 'game/session.dart';
import 'navigation.dart';
import 'palette.dart';
import 'services.dart';
import 'share.dart';
import 'widgets.dart';

/// A solved daily: time with penalties, standing, top 10, share, and (on the first solve) the rewards.
class DailyResultScreen extends StatefulWidget {
  const DailyResultScreen({
    super.key,
    required this.kind,
    required this.number,
    required this.result,
    this.fresh = false,
    this.rewards,
  });

  final GameKind kind;
  final int number;
  final DailyResult result;

  /// Just solved for the first time: post the time, run the once-per-solve effects, interstitial on leaving.
  final bool fresh;
  final DailyRewards? rewards;

  @override
  State<DailyResultScreen> createState() => _DailyResultScreenState();
}

class _DailyResultScreenState extends State<DailyResultScreen> with SingleTickerProviderStateMixin {
  late final _confetti = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  late Services _services;
  Future<DailyStanding?>? _standing;
  GameSession? _board;
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_standing != null) return;
    _services = Services.of(context);
    final s = _services;
    final stats = s.stats;
    if (widget.fresh) {
      _confetti.forward();
      _standing = s.leaderboard.submitDaily(widget.kind, widget.number, widget.result.millis);
      s.leaderboard.submitProfile(bestStreak: stats.bestStreak, solved: stats.dailiesSolved);
      ReviewPrompter(stats, s.review).onDailySolved(widget.rewards?.streak ?? stats.streak(widget.number));
      final r = widget.rewards;
      if (r != null && (r.capsule || r.chest != null)) {
        s.sound.play(r.chest != null ? Sfx.chest : Sfx.coin);
      }
    } else {
      _standing = s.leaderboard.standing(widget.kind, widget.number, myMillis: widget.result.millis);
    }
    _loadBoard();
  }

  Future<void> _loadBoard() async {
    final p = _services.puzzles;
    final GameSession board = switch (widget.kind) {
      GameKind.nests =>
        await p
            .dailyNests(widget.number)
            .then(
              (puzzle) => NestsSession(
                puzzle,
                initial: [
                  for (var i = 0; i < puzzle.size * puzzle.size; i++)
                    puzzle.isCritterInSolution(i) ? NestMark.critter : NestMark.empty,
                ],
              ),
            ),
      GameKind.pairs =>
        await p.dailyPairs(widget.number).then((puzzle) => PairsSession(puzzle, initial: List.of(puzzle.solution))),
    };
    if (mounted) setState(() => _board = board);
  }

  void _onLeft() {
    if (_left) return;
    _left = true;
    if (widget.fresh) _services.ads.showInterstitial();
  }

  Future<void> _share() async {
    final stats = _services.stats;
    final l10n = AppLocalizations.of(context);
    final results = [for (final k in GameKind.values) ?stats.daily(k, widget.number)];
    _services.analytics.share(daily: true);
    await shareText(context, dailyShareText(widget.number, results, streak: stats.streak(widget.number), l10n: l10n));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = _services.stats;
    final other = GameKind.values.firstWhere((k) => k != widget.kind);
    final otherDone = stats.daily(other, widget.number) != null;
    final streak = stats.streak(widget.number);
    final rewards = widget.fresh ? widget.rewards : null;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _onLeft();
      },
      child: Scaffold(
        backgroundColor: background,
        body: Stack(
          children: [
            ScreenFrame(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        key: const Key('resultHome'),
                        icon: Icons.close_rounded,
                        tooltip: l10n.home,
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const Spacer(),
                      StatPill(emoji: '🔥', text: l10n.streakDays(streak), color: accentSoft),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PopIn(
                    child: Column(
                      children: [
                        CritterImage(boardCritter(stats, widget.number), size: 72),
                        Text(
                          widget.fresh ? l10n.solved : l10n.alreadySolved,
                          textAlign: TextAlign.center,
                          style: chunky(34, color: accent),
                        ),
                        Text(
                          '${gameName(l10n, widget.kind)} · ${l10n.dailyTitle(widget.number)}',
                          textAlign: TextAlign.center,
                          style: chunky(16, color: inkSoft, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _timeCard(l10n),
                  const SizedBox(height: 14),
                  _standingCard(l10n),
                  if (rewards != null) ...[const SizedBox(height: 14), _rewardsCard(l10n, rewards)],
                  const SizedBox(height: 20),
                  ChunkyButton(
                    key: const Key('share'),
                    label: l10n.shareResult,
                    icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                    expand: true,
                    onPressed: _share,
                  ),
                  const SizedBox(height: 12),
                  if (!otherDone) ...[
                    ChunkyButton(
                      key: const Key('playOther'),
                      label: l10n.playOtherDaily(gameName(l10n, other)),
                      color: good,
                      expand: true,
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      onPressed: () {
                        _onLeft();
                        openGame(context, other, PlayMode.daily, replace: true);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  ChunkyButton(
                    key: const Key('home'),
                    label: l10n.home,
                    color: surface,
                    textColor: ink,
                    expand: true,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  if (_board != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.todaysGrid,
                      textAlign: TextAlign.center,
                      style: chunky(15, color: inkSoft, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox.square(
                        dimension: 200,
                        child: switch (_board!) {
                          final NestsSession s => NestsBoard(
                            session: s,
                            readOnly: true,
                            autoCross: false,
                            critter: boardCritter(stats, widget.number),
                          ),
                          final PairsSession s => PairsBoard(session: s, readOnly: true),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned.fill(child: Confetti(animation: _confetti, seed: 3)),
          ],
        ),
      ),
    );
  }

  Widget _timeCard(AppLocalizations l10n) {
    final r = widget.result;
    final penalty = rankedMillis(0, mistakes: r.mistakes, hints: r.hints);
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Column(
        children: [
          Text(
            l10n.yourTime,
            style: chunky(14, color: inkSoft, weight: FontWeight.w800),
          ),
          Text(formatTime(r.millis), key: const Key('resultTime'), style: chunky(52, height: 1.1)),
          const SizedBox(height: 6),
          if (penalty == 0)
            Text(
              l10n.flawless,
              style: chunky(15, color: good, weight: FontWeight.w800),
            )
          else
            Text(
              l10n.timeBreakdown(formatTime(r.millis - penalty), r.mistakes, r.hints, penalty ~/ 1000),
              textAlign: TextAlign.center,
              style: chunky(14, color: inkSoft, weight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  Widget _standingCard(AppLocalizations l10n) => SoftCard(
    child: FutureBuilder<DailyStanding?>(
      future: _standing,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: accent)),
                const SizedBox(width: 10),
                Text(
                  l10n.leaderboardLoading,
                  style: chunky(14, color: inkSoft, weight: FontWeight.w700),
                ),
              ],
            ),
          );
        }
        final standing = snap.data;
        if (standing == null) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              l10n.leaderboardOffline,
              key: const Key('leaderboardOffline'),
              textAlign: TextAlign.center,
              style: chunky(14, color: inkSoft, weight: FontWeight.w700),
            ),
          );
        }
        final faster = standing.fasterThan;
        final rank = standing.rank;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (faster != null)
              Text(
                l10n.fasterThan((faster * 100).round()),
                textAlign: TextAlign.center,
                style: chunky(20, color: good),
              )
            else if (rank != null)
              Text(
                l10n.rankOf(rank, standing.total),
                textAlign: TextAlign.center,
                style: chunky(20, color: good),
              ),
            if (faster != null && rank != null)
              Text(
                l10n.rankOf(rank, standing.total),
                textAlign: TextAlign.center,
                style: chunky(14, color: inkSoft, weight: FontWeight.w700),
              ),
            const SizedBox(height: 10),
            Text(
              l10n.topTimes,
              style: chunky(14, color: inkSoft, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            for (final (i, (millis, mine)) in standing.top.indexed)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: mine ? accentSoft : tileEmpty,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        i < 3 ? ['🥇', '🥈', '🥉'][i] : '${i + 1}.',
                        style: chunky(15, weight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        mine ? l10n.you : l10n.player,
                        style: chunky(15, color: mine ? ink : inkSoft, weight: FontWeight.w700),
                      ),
                    ),
                    Text(formatTime(millis), style: chunky(15, weight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _rewardsCard(AppLocalizations l10n, DailyRewards r) {
    final rows = <Widget>[
      _RewardRow(emoji: '🪙', text: l10n.rewardCoins(r.coins)),
      if (r.capsule) _RewardRow(emoji: '🥚', text: l10n.rewardDailyCapsule),
      if (r.chest != null) _RewardRow(emoji: '🎁', text: l10n.rewardChest(r.streak, r.chest!.coins)),
      if (r.chest?.capsule ?? false)
        _RewardRow(
          emoji: r.chest!.golden ? '🌟' : '🥚',
          text: r.chest!.golden ? l10n.rewardGoldenCapsule : l10n.rewardCapsule,
        ),
    ];
    return SoftCard(
      key: const Key('rewards'),
      color: goldSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.rewards,
            textAlign: TextAlign.center,
            style: chunky(16, color: const Color(0xFF9A6B10)),
          ),
          const SizedBox(height: 6),
          for (final (i, row) in rows.indexed)
            PopIn(
              delay: Duration(milliseconds: 250 + 180 * i),
              child: row,
            ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, style: chunky(16, weight: FontWeight.w800)),
        ),
      ],
    ),
  );
}
