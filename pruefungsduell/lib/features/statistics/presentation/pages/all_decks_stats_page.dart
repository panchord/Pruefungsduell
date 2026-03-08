import 'package:flutter/material.dart';
import 'package:pruefungsduell/core/models/deck_progress_stats.dart';
import 'package:pruefungsduell/core/services/database_helper.dart';
import 'package:pruefungsduell/features/statistics/presentation/pages/deck_stats_page.dart';

class AllDecksStatsPage extends StatefulWidget {
  const AllDecksStatsPage({super.key});

  @override
  State<AllDecksStatsPage> createState() => _AllDecksStatsPageState();
}

class _AllDecksStatsPageState extends State<AllDecksStatsPage> {
  late Future<List<(int id, String title, DeckProgressStats stats)>> _deckStatsFuture;
  final _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _deckStatsFuture = _loadAllDeckStats();
  }

  Future<List<(int id, String title, DeckProgressStats stats)>> _loadAllDeckStats() async {
    final decks = await _dbHelper.getDecks();
    final deckStats = <(int id, String title, DeckProgressStats stats)>[];

    for (final deck in decks) {
      final id = deck['id'] as int;
      final title = deck['title'] as String;
      final stats = await _dbHelper.getProgressStats(id);
      deckStats.add((id, title, stats));
    }

    return deckStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiken')),
      body: FutureBuilder<List<(int id, String title, DeckProgressStats stats)>>(
        future: _deckStatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Fehler: ${snapshot.error}'),
            );
          }

          final deckStats = snapshot.data ?? [];

          if (deckStats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Keine Decks vorhanden'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: deckStats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final (id, title, stats) = deckStats[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${stats.percentage.toStringAsFixed(1)}%'),
                          Text('${stats.knownCards}/${stats.totalCards}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: stats.percentage / 100,
                        minHeight: 6,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeckStatsPage(
                          deckId: id,
                          deckTitle: title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
