import 'package:flutter/material.dart';

import '../daily.dart';
import '../l10n/app_localizations.dart';
import '../puzzles/puzzle.dart';
import 'palette.dart';
import 'remove_ads.dart';
import 'services.dart';

/// Home: today's dailies, levels, album. (Placeholder until the game screens land.)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final stats = services.stats;
    final today = dailyNumberFor(services.today());
    final l10n = AppLocalizations.of(context);
    final names = {GameKind.nests: l10n.gameNests, GameKind.pairs: l10n.gamePairs};

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Spacer(),
                const Text('Critter Logic',
                    style: TextStyle(color: ink, fontSize: 34, fontWeight: FontWeight.w900)),
                Text(l10n.tagline, style: const TextStyle(color: inkSoft)),
                const Spacer(),
                for (final kind in GameKind.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      key: Key('daily-${kind.name}'),
                      tileColor: surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(names[kind]!, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
                      subtitle: Text(l10n.dailyTitle(today), style: const TextStyle(color: inkSoft)),
                      trailing: Icon(
                        stats.daily(kind, today) == null ? Icons.play_arrow_rounded : Icons.check_circle_rounded,
                        color: accent,
                      ),
                    ),
                  ),
                const Spacer(),
                RemoveAdsButtons(premium: services.premium),
                if (services.privacyOptionsRequired != null)
                  ValueListenableBuilder(
                    valueListenable: services.privacyOptionsRequired!,
                    builder: (_, required, _) => required
                        ? TextButton(
                            key: const Key('privacy'),
                            onPressed: services.showPrivacyOptions,
                            child: Text(l10n.privacyOptions, style: const TextStyle(color: inkSoft)),
                          )
                        : const SizedBox.shrink(),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
