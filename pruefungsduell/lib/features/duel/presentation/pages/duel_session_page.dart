import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pruefungsduell/core/services/database_helper.dart';
import 'package:pruefungsduell/features/duel/domain/models/duel_difficulty.dart';
import 'package:pruefungsduell/features/duel/domain/models/duel_result.dart';
import 'package:pruefungsduell/features/duel/domain/services/pruefi_bot.dart';
import 'package:pruefungsduell/features/duel/presentation/pages/duel_result_page.dart';
import 'package:pruefungsduell/features/practice/domain/models/practice_card.dart';

/// Seite, die eine komplette Duell-Session für ein Deck startet
/// und den Ladeprozess der Karten kapselt.
class DuelSessionPage extends StatefulWidget {
  const DuelSessionPage({
    super.key,
    required this.deckId,
    required this.deckTitle,
    required this.difficulty,
  });

  final int deckId;
  final String deckTitle;
  final DuelDifficulty difficulty;

  @override
  State<DuelSessionPage> createState() => _DuelSessionPageState();
}

/// Ergebnisobjekt für den asynchronen Karten-Ladevorgang.
class _DuelLoadResult {
  const _DuelLoadResult({required this.cards});

  final List<PracticeCard> cards;
}

class _DuelSessionPageState extends State<DuelSessionPage> {
  final _dbHelper = DatabaseHelper.instance;
  late Future<_DuelLoadResult> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _cardsFuture = _loadCards();
  }

  /// Lädt alle Karten für das Deck, mischt sie
  /// und wählt maximal 20 zufällige Karten aus.
  Future<_DuelLoadResult> _loadCards() async {
    final allRaw = await _dbHelper.getCardsForDeck(widget.deckId);
    final cards = allRaw.map(PracticeCard.fromMap).toList(growable: false);
    final shuffled = List.of(cards)..shuffle(Random());
    final selected = shuffled.take(min(20, shuffled.length)).toList(growable: false);
    return _DuelLoadResult(cards: selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deckTitle)),
      body: FutureBuilder<_DuelLoadResult>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Fehler beim Laden der Karten: ${snapshot.error}'),
            );
          }

          final result = snapshot.data ?? const _DuelLoadResult(cards: <PracticeCard>[]);
          if (result.cards.isEmpty) {
            return const Center(
              child: Text(
                'In diesem Deck sind noch keine Fragen.\nFüge erst Karten hinzu.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return _DuelSessionView(
            initialCards: result.cards,
            deckId: widget.deckId,
            deckTitle: widget.deckTitle,
            difficulty: widget.difficulty,
          );
        },
      ),
    );
  }
}

class _RoundFeedback {
  const _RoundFeedback({
    required this.userKnown,
    required this.botCorrect,
  });

  final bool userKnown;
  final bool botCorrect;
}

class _DuelSessionView extends StatefulWidget {
  const _DuelSessionView({
    required this.initialCards,
    required this.deckId,
    required this.deckTitle,
    required this.difficulty,
  });

  final List<PracticeCard> initialCards;
  final int deckId;
  final String deckTitle;
  final DuelDifficulty difficulty;

  @override
  State<_DuelSessionView> createState() => _DuelSessionViewState();
}

class _DuelSessionViewState extends State<_DuelSessionView> {
  late final List<PracticeCard> _cards;
  late final int _totalRounds;
  final _bot = PruefiBot();

  bool _showAnswer = false;
  int _userScore = 0;
  int _botScore = 0;
  int _answeredRounds = 0;
  _RoundFeedback? _feedback;

  @override
  void initState() {
    super.initState();
    _cards = List.of(widget.initialCards);
    _totalRounds = _cards.length;
  }

  /// Wechselt zwischen Frage- und Antwortseite der aktuellen Karte.
  void _toggleSide() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  /// Verarbeitet die Antwort des Users für die aktuelle Karte
  /// und lässt den Bot anhand der Schwierigkeit raten.
  void _answer(bool known) {
    if (_cards.isEmpty) return;

    final botCorrect = _bot.answerCorrect(widget.difficulty);

    setState(() {
      _answeredRounds++;
      _userScore += known ? 1 : 0;
      _botScore += botCorrect ? 1 : 0;
      _feedback = _RoundFeedback(userKnown: known, botCorrect: botCorrect);
    });
  }

  /// Wechselt zur nächsten Karte oder zeigt das Ergebnis,
  /// wenn alle Runden gespielt wurden.
  void _next() {
    if (_cards.isEmpty) return;

    setState(() {
      _cards.removeAt(0);
      _showAnswer = false;
      _feedback = null;
    });

    if (_cards.isEmpty) {
      final result = DuelResult(
        deckId: widget.deckId,
        deckTitle: widget.deckTitle,
        difficulty: widget.difficulty,
        playedRounds: _totalRounds,
        userScore: _userScore,
        botScore: _botScore,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DuelResultPage(result: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final card = _cards.first;
    final progressText = 'Runde $_answeredRounds/$_totalRounds';
    final scoreText = 'Du: $_userScore  ·  Prüfi: $_botScore';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                progressText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                scoreText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GestureDetector(
                  onTap: _feedback != null ? null : _toggleSide,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Card(
                      key: ValueKey(_showAnswer),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _showAnswer ? Icons.check_circle : Icons.help,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _showAnswer ? 'Antwort' : 'Frage',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showAnswer ? card.answer : card.question,
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _feedback != null
                                  ? 'Weiter geht’s…'
                                  : 'Tippe zum Umdrehen',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_feedback == null) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _answer(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Nicht gewusst'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _answer(true),
                    child: const Text('Gewusst'),
                  ),
                ),
              ],
            ),
          ] else ...[
            _DuelFeedbackCard(
              feedback: _feedback!,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _next,
                icon: const Icon(Icons.navigate_next),
                label: Text(_cards.length == 1 ? 'Ergebnis' : 'Nächste Frage'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DuelFeedbackCard extends StatelessWidget {
  const _DuelFeedbackCard({required this.feedback});

  final _RoundFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final userText = feedback.userKnown ? 'Gewusst' : 'Nicht gewusst';
    final botText = feedback.botCorrect ? 'richtig' : 'falsch';
    final botColor = feedback.botCorrect
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Du: $userText',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Icon(
                  feedback.botCorrect ? Icons.smart_toy : Icons.smart_toy_outlined,
                  color: botColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Prüfi: $botText',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: botColor,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

