import 'package:flutter/material.dart';
import 'package:pruefungsduell/core/services/database_helper.dart';
import 'package:pruefungsduell/features/practice/presentation/pages/practice_session_page.dart';

class PracticeDeckSelectPage extends StatefulWidget {
  const PracticeDeckSelectPage({super.key});

  @override
  State<PracticeDeckSelectPage> createState() => _PracticeDeckSelectPageState();
}

class _PracticeDeckSelectPageState extends State<PracticeDeckSelectPage> {
  final _dbHelper = DatabaseHelper.instance;
  late Future<List<Map<String, dynamic>>> _decksFuture;

  @override
  void initState() {
    super.initState();
    _decksFuture = _dbHelper.getDecks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abgefragt werden'),
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
              child: Text(
                'Du hast noch keine Decks.\nLege erst ein Deck mit Fragen an.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: decks.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final deck = decks[index];
              return ListTile(
                leading: const Icon(Icons.style),
                title: Text(deck['title'] as String),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PracticeSessionPage(
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
    );
  }
}

