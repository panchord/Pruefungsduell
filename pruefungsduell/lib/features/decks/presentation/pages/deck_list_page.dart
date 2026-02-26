import 'package:flutter/material.dart';
import 'package:pruefungsduell/core/services/database_helper.dart';
import 'package:pruefungsduell/features/decks/presentation/pages/deck_detail_page.dart';

class DeckListPage extends StatefulWidget {
  const DeckListPage({super.key});

  @override
  State<DeckListPage> createState() => _DeckListPageState();
}

class _DeckListPageState extends State<DeckListPage> {
  final _dbHelper = DatabaseHelper.instance;
  late Future<List<Map<String, dynamic>>> _decksFuture;

  @override
  void initState() {
    super.initState();
    _reloadDecks();
  }

  void _reloadDecks() {
    _decksFuture = _dbHelper.getDecks();
  }

  Future<void> _showAddDeckDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neues Deck anlegen'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Deck-Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isEmpty) {
                  return;
                }

                await _dbHelper.insertDeck(title);
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
      setState(_reloadDecks);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck angelegt')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decks'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _decksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Fehler beim Laden der Decks: ${snapshot.error}'),
            );
          }

          final decks = snapshot.data ?? [];

          if (decks.isEmpty) {
            return const Center(
              child: Text('Noch keine Decks angelegt.\nLege dein erstes Deck an!'),
            );
          }

          return ListView.separated(
            itemCount: decks.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final deck = decks[index];
              return ListTile(
                title: Text(deck['title'] as String),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DeckDetailPage(
                        deckId: deck['id'] as int,
                        deckTitle: deck['title'] as String,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDeckDialog,
        icon: const Icon(Icons.add),
        label: const Text('Deck anlegen'),
      ),
    );
  }
}

