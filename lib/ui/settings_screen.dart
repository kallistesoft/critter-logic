import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/reminders.dart';
import '../puzzles/puzzle.dart';
import 'game/game_screen.dart';
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
    return Scaffold(
      backgroundColor: background,
      body: ScreenFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.maybePop(context),
                  tooltip: l10n.back,
                ),
                const SizedBox(width: 12),
                Text(l10n.settings, style: chunky(26)),
              ],
            ),
            const SizedBox(height: 16),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    _Toggle(
                      key: const Key('soundToggle'),
                      emoji: '🔊',
                      label: l10n.settingSound,
                      value: !services.sound.muted,
                      onChanged: (v) async {
                        await services.sound.setMuted(!v);
                        setState(() {});
                      },
                    ),
                    _Toggle(
                      key: const Key('musicToggle'),
                      emoji: '🎵',
                      label: l10n.settingMusic,
                      value: services.music.enabled,
                      onChanged: (v) async {
                        await services.music.setEnabled(v);
                        setState(() {});
                      },
                    ),
                    _Toggle(
                      key: const Key('autoCrossToggle'),
                      emoji: '✖️',
                      label: l10n.settingAutoCross,
                      subtitle: l10n.settingAutoCrossInfo,
                      value: stats.autoCross,
                      onChanged: (v) async {
                        await stats.setAutoCross(v);
                        setState(() {});
                      },
                    ),
                    _Toggle(
                      key: const Key('remindersToggle'),
                      emoji: '⏰',
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    for (final kind in GameKind.values)
                      _Link(
                        emoji: kind == GameKind.nests ? '🐤' : '☀️',
                        label: l10n.howToPlay(gameName(l10n, kind)),
                        onTap: () => Navigator.of(context).push(softRoute(TutorialScreen(kind: kind))),
                      ),
                    if (!stats.reviewed)
                      _Link(
                        key: const Key('settingsRate'),
                        emoji: '⭐',
                        label: l10n.rateApp,
                        onTap: () async {
                          await stats.setReviewed(true);
                          await services.review.openStoreListing();
                          if (mounted) setState(() {});
                        },
                      ),
                    if (services.privacyOptionsRequired != null)
                      ValueListenableBuilder(
                        valueListenable: services.privacyOptionsRequired!,
                        builder: (_, required, _) => required
                            ? _Link(emoji: '🔒', label: l10n.privacyOptions, onTap: services.showPrivacyOptions)
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.credits,
              textAlign: TextAlign.center,
              style: chunky(13, color: inkSoft, weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Critter Logic · Kallistesoft',
              textAlign: TextAlign.center,
              style: chunky(13, color: inkSoft, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String emoji;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: value,
    onChanged: onChanged,
    activeThumbColor: Colors.white,
    activeTrackColor: good,
    secondary: Text(emoji, style: const TextStyle(fontSize: 22)),
    title: Text(label, style: chunky(16, weight: FontWeight.w800)),
    subtitle: subtitle == null
        ? null
        : Text(
            subtitle!,
            style: chunky(13, color: inkSoft, weight: FontWeight.w600),
          ),
  );
}

class _Link extends StatelessWidget {
  const _Link({super.key, required this.emoji, required this.label, this.onTap});

  final String emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Text(emoji, style: const TextStyle(fontSize: 22)),
    title: Text(label, style: chunky(16, weight: FontWeight.w800)),
    trailing: const Icon(Icons.chevron_right_rounded, color: inkSoft),
  );
}
