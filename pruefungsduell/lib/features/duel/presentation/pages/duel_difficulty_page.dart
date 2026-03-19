import 'package:flutter/material.dart';
import 'package:pruefungsduell/features/duel/domain/models/duel_difficulty.dart';
import 'package:pruefungsduell/features/duel/presentation/pages/duel_session_page.dart';

/// Seite zur Auswahl der Duell-Schwierigkeit für ein bestimmtes Deck.
class DuelDifficultyPage extends StatefulWidget {
  const DuelDifficultyPage({
    super.key,
    required this.deckId,
    required this.deckTitle,
  });

  final int deckId;
  final String deckTitle;

  @override
  State<DuelDifficultyPage> createState() => _DuelDifficultyPageState();
}

class _DuelDifficultyPageState extends State<DuelDifficultyPage> {
  DuelDifficulty _difficulty = DuelDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schwierigkeit wählen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.deckTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              child: Column(
                children: DuelDifficulty.values.map((d) {
                  return RadioListTile<DuelDifficulty>(
                    value: d,
                    groupValue: _difficulty,
                    title: Text(d.label),
                    subtitle: Text(
                      'Trefferquote: ${(d.hitRate * 100).round()}%',
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _difficulty = value);
                    },
                  );
                }).toList(growable: false),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DuelSessionPage(
                      deckId: widget.deckId,
                      deckTitle: widget.deckTitle,
                      difficulty: _difficulty,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

