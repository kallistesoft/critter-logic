import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/reminders.dart';
import '../puzzles/puzzle.dart';
import 'game/game_screen.dart';
import 'meadow.dart';
import 'navigation.dart';
import 'palette.dart';
import 'services.dart';
import 'tutorial_screen.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final stats = services.stats;
    return MeadowScaffold(
      child: Column(children: [
        MeadowTopBar(title: l10n.settings, backTooltip: l10n.back),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              SlideIn(
                child: SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Column(children: [
                    _Toggle(
                      key: const Key('soundToggle'),
                      icon: Icons.volume_up_rounded,
                      tint: sky,
                      label: l10n.settingSound,
                      value: !services.sound.muted,
                      onChanged: (v) async {
                        await services.sound.setMuted(!v);
                        setState(() {});
                      },
                    ),
                    const _Divider(),
                    _Toggle(
                      key: const Key('musicToggle'),
                      icon: Icons.music_note_rounded,
                      tint: const Color(0xFFB07CE8),
                      label: l10n.settingMusic,
                      value: services.music.enabled,
                      onChanged: (v) async {
                        await services.music.setEnabled(v);
                        setState(() {});
                      },
                    ),
                    const _Divider(),
                    _Toggle(
                      key: const Key('autoCrossToggle'),
                      icon: Icons.eco_rounded,
                      tint: leaf,
                      label: l10n.settingAutoCross,
                      subtitle: l10n.settingAutoCrossInfo,
                      value: stats.autoCross,
                      onChanged: (v) async {
                        await stats.setAutoCross(v);
                        setState(() {});
                      },
                    ),
                    const _Divider(),
                    _Toggle(
                      key: const Key('remindersToggle'),
                      icon: Icons.alarm_rounded,
                      tint: coral,
                      label: l10n.settingReminders,
                      value: stats.remindersOn,
                      onChanged: (v) async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (v && !await services.reminders.requestPermission()) {
                          messenger.showSnackBar(SnackBar(content: Text(l10n.reminderDenied)));
                          v = false;
                        }
                        await stats.setRemindersOn(v);
                        await services.analytics.log('reminder_toggle', {'on': v ? 1 : 0});
                        if (context.mounted) {
                          await planReminders(stats, services.reminders, l10n, services.today());
                        }
                        setState(() {});
                      },
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              SlideIn(
                delay: const Duration(milliseconds: 90),
                child: SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Column(children: [
                    for (final kind in GameKind.values) ...[
                      if (kind != GameKind.values.first) const _Divider(),
                      _Link(
                        icon: switch (kind) {
                          GameKind.nests => Icons.grid_view_rounded,
                          GameKind.pairs => Icons.wb_sunny_rounded,
                          GameKind.trail => Icons.pets_rounded,
                        },
                        tint: switch (kind) {
                          GameKind.nests => leaf,
                          GameKind.pairs => gold,
                          GameKind.trail => coral,
                        },
                        label: l10n.howToPlay(gameName(l10n, kind)),
                        onTap: () => Navigator.of(context).push(softRoute(TutorialScreen(kind: kind))),
                      ),
                    ],
                    if (!stats.reviewed) ...[
                      const _Divider(),
                      _Link(
                        key: const Key('settingsRate'),
                        icon: Icons.star_rounded,
                        tint: gold,
                        label: l10n.rateApp,
                        onTap: () async {
                          await stats.setReviewed(true);
                          await services.review.openStoreListing();
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                    if (services.privacyOptionsRequired != null)
                      ValueListenableBuilder(
                        valueListenable: services.privacyOptionsRequired!,
                        builder: (_, required, _) => required
                            ? Column(children: [
                                const _Divider(),
                                _Link(icon: Icons.lock_rounded, tint: inkSoft, label: l10n.privacyOptions, onTap: services.showPrivacyOptions),
                              ])
                            : const SizedBox.shrink(),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: paper.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Text(l10n.credits, textAlign: TextAlign.center, style: chunky(13, color: inkSoft, weight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(l10n.fontCredit, textAlign: TextAlign.center, style: chunky(13, color: inkSoft, weight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Critter Logic · Kallistesoft', textAlign: TextAlign.center, style: chunky(13, color: inkSoft)),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 14), color: paperEdge.withValues(alpha: 0.6));
}

/// Round colored badge with a white icon.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tint,
          shape: BoxShape.circle,
          border: Border.all(color: edgeOf(tint), width: 2.5),
          boxShadow: [BoxShadow(color: edgeOf(tint), offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      );
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    super.key,
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: () => onChanged(!value),
        builder: (context, p, child) => Transform.scale(scale: 1 - 0.02 * p, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            _Badge(icon: icon, tint: tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: chunky(17)),
                if (subtitle != null) Text(subtitle!, style: chunky(13, color: inkSoft, weight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(width: 8),
            CandySwitch(value: value),
          ]),
        ),
      );
}

/// A chunky pill switch with a sliding knob.
class CandySwitch extends StatelessWidget {
  const CandySwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 58,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? leaf : const Color(0xFFD9CFC0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? leafEdge : const Color(0xFFAFA393), width: 2.5),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: value ? leafEdge : const Color(0xFFAFA393), offset: const Offset(0, 2))],
            ),
          ),
        ),
      );
}

class _Link extends StatelessWidget {
  const _Link({super.key, required this.icon, required this.tint, required this.label, this.onTap});

  final IconData icon;
  final Color tint;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        builder: (context, p, child) => Transform.scale(scale: 1 - 0.02 * p, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            _Badge(icon: icon, tint: tint),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: chunky(17))),
            const Icon(Icons.chevron_right_rounded, color: woodDark, size: 28),
          ]),
        ),
      );
}
