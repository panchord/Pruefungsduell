import 'package:flutter/material.dart';
import 'package:pruefungsduell/features/duel/domain/models/duel_difficulty.dart';
import 'package:pruefungsduell/features/duel/domain/models/duel_result.dart';
import 'package:pruefungsduell/features/duel/presentation/pages/duel_session_page.dart';

/// Seite, die das Ergebnis eines Duells anzeigt
/// und einen Neustart oder das Zurückkehren ermöglicht.
class DuelResultPage extends StatelessWidget {
  const DuelResultPage({super.key, required this.result});

  final DuelResult result;

  @override
  Widget build(BuildContext context) {
    final scoreLine = 'Du ${result.userScore} : ${result.botScore} Prüfi';
    final subtitle =
        '${result.deckTitle} · ${result.difficulty.label} · ${result.playedRounds} Fragen';

    return Scaffold(
      appBar: AppBar(title: const Text('Ergebnis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  result.userScore >= result.botScore
                      ? Icons.emoji_events
                      : Icons.smart_toy,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  result.outcomeText,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  scoreLine,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => DuelSessionPage(
                            deckId: result.deckId,
                            deckTitle: result.deckTitle,
                            difficulty: result.difficulty,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Nochmal spielen'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Zurück'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

