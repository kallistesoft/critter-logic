import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../meta/album.dart';
import '../meta/retention.dart';
import '../meta/rewards.dart';
import '../meta/set_rewards.dart';
import '../services/sound_service.dart';
import 'capsule_screen.dart';
import 'coin_fly.dart';
import 'cosmetics.dart';
import 'critter_image.dart';
import 'meadow.dart';
import 'palette.dart';
import 'services.dart';
import 'widgets.dart';

/// Event names by theme id (`event_<theme>`).
String eventName(AppLocalizations l10n, String theme) => switch (theme) {
  'polar' => l10n.eventPolar,
  'panda' => l10n.eventPanda,
  'jungle' => l10n.eventJungle,
  'safari' => l10n.eventSafari,
  'farm' => l10n.eventFarm,
  'winter' => l10n.eventWinter,
  _ => theme,
};

/// A cozy toast at the bottom: an icon and one or more lines.
void showToast(BuildContext context, List<String> lines, {Widget? icon, Key? key}) {
  if (lines.isEmpty) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: key,
      duration: const Duration(milliseconds: 2800),
      content: Row(
        children: [
          if (icon != null) ...[SizedBox.square(dimension: 30, child: Center(child: icon)), const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [for (final l in lines) Text(l, style: chunky(16, color: Colors.white))],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Tells the player what a [Retention.recordEvent] changed: event tokens, a prize ready, new trophies, and the
/// "Set complete!" celebration for hat unlocks.
Future<void> showRetentionUpdate(BuildContext context, RetentionUpdate u, {bool tokens = true}) async {
  final l10n = AppLocalizations.of(context);
  final lines = <String>[
    if (tokens && u.tokens > 0) l10n.eventTokens(u.tokens),
    if (u.thresholdsReached.isNotEmpty) l10n.eventPrizeReady,
    if (u.newAchievements.isNotEmpty) l10n.trophyUnlocked,
  ];
  if (lines.isNotEmpty) {
    showToast(
      context,
      lines,
      key: const Key('retentionToast'),
      icon: u.newAchievements.isNotEmpty
          ? const TrophyIcon(size: 30)
          : const Text('🐾', style: TextStyle(fontSize: 22)),
    );
  }
  if (u.setUnlocks.isNotEmpty) await showSetUnlocks(context, u.setUnlocks);
}

/// The hat (and full-album coins) a set unlock gives that the player can see today; board themes come later.
List<String> visibleUnlocks(SetUnlock u) => [
  for (final c in u.cosmetics)
    if (shownCosmetic(c)) c,
];

/// "Set complete!" with what the set unlocked and an Equip button for a hat. Sets whose unlock is a board theme
/// show nothing extra (their 200 coins are already announced by the capsule reveal).
Future<void> showSetUnlocks(BuildContext context, List<SetUnlock> unlocks) async {
  for (final u in unlocks) {
    final items = visibleUnlocks(u);
    if (items.isEmpty && u.coins == 0) continue;
    if (!context.mounted) return;
    await _showSetUnlock(context, u, items);
  }
}

Future<void> _showSetUnlock(BuildContext context, SetUnlock u, List<String> items) {
  final l10n = AppLocalizations.of(context);
  final services = Services.of(context);
  services.sound.play(Sfx.chest);
  HapticFeedback.heavyImpact();
  final all = u.set == 'all';
  final hat = items.where((i) => i.startsWith('hat.')).firstOrNull;
  final critters = all
      ? ['cow', 'panda', 'elephant', 'sloth', 'narwhal']
      : [
          for (final c in album)
            if (c.set == u.set) c.id,
        ];
  return showSoftDialog<void>(
    context,
    title: all ? l10n.albumCompleteTitle : l10n.setCompleteTitle,
    body: all ? null : setName(l10n, u.set),
    content: Column(
      key: const Key('setUnlock'),
      children: [
        SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: ClipRect(child: _SpinningRays(color: gold)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final (i, id) in critters.take(3).indexed)
                    PopIn(
                      delay: Duration(milliseconds: 200 + 150 * i),
                      child: Hatted(
                        hat: hat,
                        size: i == 1 ? 86 : 64,
                        child: CritterImage(id, size: i == 1 ? 86 : 64),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.setUnlockedItem(cosmeticName(l10n, item)),
              textAlign: TextAlign.center,
              style: chunky(18, color: goldEdge),
            ),
          ),
        if (u.coins > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CoinIcon(size: 26),
              const SizedBox(width: 6),
              Text(l10n.rewardCoins(u.coins), style: chunky(18, color: woodDark)),
            ],
          ),
      ],
    ),
    actions: [
      if (hat != null)
        Builder(
          builder: (context) => ChunkyButton(
            key: const Key('equipUnlock'),
            label: l10n.shopEquip,
            expand: true,
            color: leaf,
            icon: const Icon(Icons.checkroom_rounded, color: Colors.white),
            onPressed: () async {
              final nav = Navigator.of(context);
              if (services.retention.shop.equippedHat != hat) await services.retention.shop.equip(hat);
              nav.pop();
            },
          ),
        ),
      Builder(
        builder: (context) => ChunkyButton(
          key: const Key('setUnlockOk'),
          label: hat != null ? l10n.later : l10n.nice,
          expand: true,
          small: hat != null,
          color: hat != null ? woodButton : leaf,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    ],
  );
}

class _SpinningRays extends StatefulWidget {
  const _SpinningRays({required this.color});

  final Color color;

  @override
  State<_SpinningRays> createState() => _SpinningRaysState();
}

class _SpinningRaysState extends State<_SpinningRays> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ambientMotion(context)) {
      _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => CustomPaint(painter: RaysPainter(widget.color, 1, _c.value * 2 * pi)),
  );
}

// ---- Login calendar ----

/// The once-a-day calendar popup (also opened from the home button). Coins fly to [coinTarget] when claimed.
Future<void> showCalendarPopup(BuildContext context, {GlobalKey? coinTarget}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: AppLocalizations.of(context).calendarTitle,
  barrierColor: const Color(0x664A3426),
  transitionDuration: const Duration(milliseconds: 360),
  transitionBuilder: (context, a, _, child) => FadeTransition(
    opacity: a,
    child: ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: child,
    ),
  ),
  pageBuilder: (context, _, _) => SafeArea(
    child: UiScale(
      child: Center(child: CalendarPanel(coinTarget: coinTarget)),
    ),
  ),
);

class CalendarPanel extends StatefulWidget {
  const CalendarPanel({super.key, this.coinTarget});

  final GlobalKey? coinTarget;

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  final _tileKeys = List.generate(7, (_) => GlobalKey());
  bool _busy = false;

  /// The tile just stamped (plays the stamp animation).
  int? _justClaimed;
  Reward? _won;

  Future<void> _claim({required bool doubled}) async {
    if (_busy) return;
    final services = Services.of(context);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final retention = services.retention;
    final now = services.today();
    final step = retention.calendar.state(now).step;
    setState(() => _busy = true);
    if (doubled) {
      if (!await services.ads.showRewarded()) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.noAdAvailable)));
        if (mounted) setState(() => _busy = false);
        return;
      }
      services.analytics.adReward('calendar_double');
    }
    final result = await retention.claimCalendar(now, doubled: doubled);
    if (!mounted) return;
    if (result == null) {
      setState(() => _busy = false);
      return;
    }
    final reward = result.reward;
    setState(() {
      _justClaimed = step;
      _won = reward;
    });
    HapticFeedback.mediumImpact();
    if (reward.coins > 0 && widget.coinTarget != null) {
      if (ambientMotion(context)) await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      await flyCoins(context, from: _tileKeys[step], to: widget.coinTarget!, coins: reward.coins >= 100 ? 12 : 8);
    } else {
      services.sound.play(reward.coins > 0 ? Sfx.coin : Sfx.chest);
    }
    if (mounted) setState(() => _busy = false);
    // Claiming may reach the calendar trophy.
    await retention.announceAchievements();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final state = services.retention.calendar.state(services.today());
    Widget tile(int i) => _DayTile(
      key: _tileKeys[i],
      day: i,
      reward: state.rewards[i],
      today: i == state.step,
      claimed: i < state.step || (i == state.step && state.claimedToday),
      stampNow: _justClaimed == i,
      big: i == 6,
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Material(
          type: MaterialType.transparency,
          child: CustomPaint(
            key: const Key('calendar'),
            painter: const WoodPainter(radius: 26, plank: 40),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.calendarTitle,
                    style: outlinedText(30, color: const Color(0xFFFFF4D6), stroke: woodEdge, width: 2.4),
                  ),
                  Text(
                    l10n.calendarSubtitle,
                    style: chunky(15, color: const Color(0xFFFFE6BC), weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: tile(i))],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: tile(4)),
                      const SizedBox(width: 8),
                      Expanded(child: tile(5)),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: tile(6)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_won != null) ...[
                    PopIn(
                      child: Text(
                        _rewardText(l10n, _won!),
                        key: const Key('calendarWon'),
                        style: outlinedText(24, color: const Color(0xFFFFE066), stroke: goldEdge),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (state.available) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ChunkyButton(
                            key: const Key('calendarClaim'),
                            label: l10n.calendarClaim,
                            color: leaf,
                            onPressed: _busy ? null : () => _claim(doubled: false),
                          ),
                        ),
                        if (state.canDouble) ...[
                          const SizedBox(width: 10),
                          ChunkyButton(
                            key: const Key('calendarDouble'),
                            label: l10n.calendarDouble,
                            color: sky,
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                            onPressed: _busy ? null : () => _claim(doubled: true),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    Text(
                      l10n.calendarTomorrow,
                      textAlign: TextAlign.center,
                      style: chunky(16, color: const Color(0xFFFFF4D6), weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    ChunkyButton(
                      key: const Key('calendarClose'),
                      label: l10n.close,
                      small: true,
                      color: woodButton,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _rewardText(AppLocalizations l10n, Reward r) => r.goldenCapsules > 0
    ? l10n.rewardGoldenCapsule
    : r.capsules > 0
    ? l10n.rewardCapsule
    : l10n.rewardCoins(r.coins);

class _DayTile extends StatefulWidget {
  const _DayTile({
    super.key,
    required this.day,
    required this.reward,
    required this.today,
    required this.claimed,
    required this.stampNow,
    required this.big,
  });

  final int day;
  final Reward reward;
  final bool today;
  final bool claimed;
  final bool stampNow;
  final bool big;

  @override
  State<_DayTile> createState() => _DayTileState();
}

class _DayTileState extends State<_DayTile> with SingleTickerProviderStateMixin {
  late final _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_DayTile old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final on = widget.today && !widget.claimed && ambientMotion(context);
    if (on && !_bounce.isAnimating) {
      _bounce.repeat(reverse: true);
    } else if (!on && _bounce.isAnimating) {
      _bounce.stop();
      _bounce.value = 0;
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.reward;
    final golden = widget.big || r.goldenCapsules > 0;
    final active = widget.today && !widget.claimed;
    final Widget icon = r.goldenCapsules > 0 || r.capsules > 0
        ? CapsuleEgg(size: widget.big ? 52 : 38, golden: r.goldenCapsules > 0)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoinIcon(size: r.coins >= 50 ? 32 : 28),
              Text('${r.coins}', style: chunky(15, color: woodDark, height: 1.1)),
            ],
          );
    final card = Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: BoxDecoration(
        color: golden ? goldSoft : paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? coral : (golden ? gold : paperEdge), width: active ? 3.5 : 2.5),
        boxShadow: [BoxShadow(color: active ? coralEdge : woodEdge, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(l10n.calendarDay(widget.day + 1), maxLines: 1, style: chunky(13, color: active ? coralEdge : inkSoft)),
          Expanded(
            child: Center(child: FittedBox(child: icon)),
          ),
        ],
      ),
    );
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final b = Curves.easeInOut.transform(_bounce.value);
        return Transform.translate(
          offset: Offset(0, -5 * b),
          child: Transform.scale(scale: 1 + 0.04 * b, child: child),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(opacity: widget.claimed && !widget.stampNow ? 0.75 : 1, child: card),
          if (widget.claimed)
            Positioned.fill(
              child: widget.stampNow
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 2.2, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutBack,
                      builder: (context, s, child) => Opacity(
                        opacity: ((2.2 - s) / 1.2).clamp(0, 1),
                        child: Transform.scale(scale: s, child: child),
                      ),
                      child: const PawStamp(),
                    )
                  : const PawStamp(),
            ),
        ],
      ),
    );
  }
}

/// A red ink paw print stamped over a claimed day.
class PawStamp extends StatelessWidget {
  const PawStamp({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: Transform.rotate(
        angle: -0.25,
        child: SizedBox.square(
          dimension: 46,
          child: CustomPaint(key: const Key('paw'), painter: _PawPainter()),
        ),
      ),
    ),
  );
}

class _PawPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final ink = Paint()..color = const Color(0xD9D9473F);
    canvas.drawCircle(
      Offset(s / 2, s / 2),
      s * 0.48,
      Paint()
        ..color = const Color(0xB3D9473F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.06,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.5, s * 0.62), width: s * 0.38, height: s * 0.3), ink);
    for (final (x, y) in const [(0.27, 0.42), (0.41, 0.3), (0.59, 0.3), (0.73, 0.42)]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(s * x, s * y), width: s * 0.14, height: s * 0.17), ink);
    }
  }

  @override
  bool shouldRepaint(_PawPainter old) => false;
}

// ---- Icons ----

/// A little golden cup.
class TrophyIcon extends StatelessWidget {
  const TrophyIcon({super.key, this.size = 28, this.color = gold});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _CupPainter(color)),
  );
}

class _CupPainter extends CustomPainter {
  const _CupPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final edge = edgeOf(color);
    final line = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, s * 0.07)
      ..strokeJoin = StrokeJoin.round;
    // Handles.
    final handles = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1;
    canvas.drawArc(Rect.fromLTWH(s * 0.06, s * 0.16, s * 0.3, s * 0.32), pi * 0.5, pi, false, handles);
    canvas.drawArc(Rect.fromLTWH(s * 0.64, s * 0.16, s * 0.3, s * 0.32), -pi * 0.5, pi, false, handles);
    final cup = Path()
      ..moveTo(s * 0.22, s * 0.1)
      ..lineTo(s * 0.78, s * 0.1)
      ..quadraticBezierTo(s * 0.78, s * 0.58, s * 0.5, s * 0.62)
      ..quadraticBezierTo(s * 0.22, s * 0.58, s * 0.22, s * 0.1)
      ..close();
    canvas.drawPath(cup, Paint()..color = color);
    canvas.drawPath(cup, line);
    canvas.drawRect(Rect.fromLTWH(s * 0.44, s * 0.6, s * 0.12, s * 0.16), Paint()..color = edge);
    final base = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.26, s * 0.74, s * 0.48, s * 0.16),
      Radius.circular(s * 0.04),
    );
    canvas.drawRRect(base, Paint()..color = woodDark);
    canvas.drawOval(
      Rect.fromLTWH(s * 0.3, s * 0.16, s * 0.12, s * 0.22),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_CupPainter old) => old.color != color;
}
