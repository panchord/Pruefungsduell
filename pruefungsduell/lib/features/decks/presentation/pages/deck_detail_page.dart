import 'package:flutter/material.dart';
import 'package:pruefungsduell/core/services/database_helper.dart';

class DeckDetailPage extends StatefulWidget {
  const DeckDetailPage({
    super.key,
    required this.deckId,
    required this.deckTitle,
  });

  final int deckId;
  final String deckTitle;

  @override
  State<DeckDetailPage> createState() => _DeckDetailPageState();
}

class _DeckDetailPageState extends State<DeckDetailPage> {
  final _dbHelper = DatabaseHelper.instance;
  late Future<List<Map<String, dynamic>>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _reloadCards();
  }

  void _reloadCards() {
    _cardsFuture = _dbHelper.getCardsForDeck(widget.deckId);
  }

  Future<void> _showAddCardDialog() async {
    final questionController = TextEditingController();
    final answerController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Frage hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Frage',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    labelText: 'Antwort',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final question = questionController.text.trim();
                final answer = answerController.text.trim();
                if (question.isEmpty || answer.isEmpty) {
                  return;
                }

                await _dbHelper.insertCard(
                  deckId: widget.deckId,
                  question: question,
                  answer: answer,
                );
                if (!mounted) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(_reloadCards);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Frage hinzugefügt')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckTitle),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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

          final cards = snapshot.data ?? [];

          if (cards.isEmpty) {
            return const Center(
              child: Text('In diesem Deck sind noch keine Fragen.\nFüge deine erste Frage hinzu!'),
            );
          }

          return ListView.separated(
            itemCount: cards.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final card = cards[index];
              return ListTile(
                title: Text(card['question'] as String),
                subtitle: Text(card['answer'] as String),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardDialog,
        icon: const Icon(Icons.add),
        label: const Text('Frage hinzufügen'),
      ),
    );
  }
}

