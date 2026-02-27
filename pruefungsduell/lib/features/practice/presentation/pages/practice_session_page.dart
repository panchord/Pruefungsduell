import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pruefungsduell/core/services/database_helper.dart';
import 'package:pruefungsduell/features/practice/domain/models/practice_card.dart';

class _PracticeLoadResult {
  const _PracticeLoadResult({
    required this.dueCards,
    required this.totalCards,
  });

  final List<PracticeCard> dueCards;
  final int totalCards;
}

class PracticeSessionPage extends StatefulWidget {
  const PracticeSessionPage({
    super.key,
    required this.deckId,
    required this.deckTitle,
  });

  final int deckId;
  final String deckTitle;

  @override
  State<PracticeSessionPage> createState() => _PracticeSessionPageState();
}

class _PracticeSessionPageState extends State<PracticeSessionPage> {
  final _dbHelper = DatabaseHelper.instance;
  late Future<_PracticeLoadResult> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _cardsFuture = _loadCards();
  }

  Future<void> _confirmAndResetDeck() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deck zurücksetzen'),
        content: const Text(
          'Damit wird der Lernfortschritt für dieses Deck zurückgesetzt.\n'
          'Alle Fragen werden wieder als „fällig“ behandelt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    await _dbHelper.resetPracticeForDeck(widget.deckId);
    if (!mounted) return;

    setState(_reload);
    messenger.showSnackBar(
      const SnackBar(content: Text('Deck wurde zurückgesetzt')),
    );
  }

  Future<_PracticeLoadResult> _loadCards() async {
    final dueRaw = await _dbHelper.getDueCardsForPractice(
      deckId: widget.deckId,
      hideKnownFor: const Duration(days: 2),
    );
    final allRaw = await _dbHelper.getCardsForDeck(widget.deckId);

    return _PracticeLoadResult(
      dueCards: dueRaw.map(PracticeCard.fromMap).toList(growable: false),
      totalCards: allRaw.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deckTitle)),
      body: FutureBuilder<_PracticeLoadResult>(
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

          final result = snapshot.data ??
              const _PracticeLoadResult(dueCards: <PracticeCard>[], totalCards: 0);

          if (result.totalCards == 0) {
            return const Center(
              child: Text(
                'In diesem Deck sind noch keine Fragen.\nFüge erst Karten hinzu.',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (result.dueCards.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gerade sind keine fälligen Fragen da.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '„Gewusst“-Karten werden 2 Tage ausgeblendet.\n'
                      'Wenn du das Deck nochmal komplett durchgehen willst, kannst du es zurücksetzen.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _confirmAndResetDeck,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Deck zurücksetzen'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _PracticeSessionView(initialCards: result.dueCards);
        },
      ),
    );
  }
}

class _PracticeSessionView extends StatefulWidget {
  const _PracticeSessionView({required this.initialCards});

  final List<PracticeCard> initialCards;

  @override
  State<_PracticeSessionView> createState() => _PracticeSessionViewState();
}

class _PracticeSessionViewState extends State<_PracticeSessionView> {
  late final List<PracticeCard> _cards;
  bool _showAnswer = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cards = List.of(widget.initialCards);
  }

  void _toggleSide() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _shuffle() {
    setState(() {
      _cards.shuffle(Random());
      _showAnswer = false;
    });
  }

  Future<void> _answer(bool known) async {
    if (_saving) return;
    if (_cards.isEmpty) return;

    setState(() {
      _saving = true;
    });

    final db = DatabaseHelper.instance;
    final current = _cards.first;
    await db.updatePracticeResult(cardId: current.id, known: known);

    if (!mounted) return;

    setState(() {
      _saving = false;
      _showAnswer = false;
      _cards.removeAt(0);
      if (!known) {
        _cards.add(current);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.celebration,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Für dieses Deck sind gerade keine fälligen Karten da.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '„Gewusst“-Karten werden 2 Tage ausgeblendet.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final card = _cards.first;
    final progressText = 'Fällig: ${_cards.length}';

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
              TextButton.icon(
                onPressed: _saving ? null : _shuffle,
                icon: const Icon(Icons.shuffle),
                label: const Text('Mischen'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GestureDetector(
                  onTap: _saving ? null : _toggleSide,
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
                              _saving ? 'Speichere…' : 'Tippe zum Umdrehen',
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _answer(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Nicht gewusst'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : () => _answer(true),
                  child: const Text('Gewusst'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

