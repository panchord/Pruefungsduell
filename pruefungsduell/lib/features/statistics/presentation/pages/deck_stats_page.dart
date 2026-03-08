import 'package:flutter/material.dart';
import 'package:pruefungsduell/core/models/deck_progress_stats.dart';
import 'package:pruefungsduell/core/services/database_helper.dart';

class DeckStatsPage extends StatefulWidget {
  final int deckId;
  final String deckTitle;

  const DeckStatsPage({
    super.key,
    required this.deckId,
    required this.deckTitle,
  });

  @override
  State<DeckStatsPage> createState() => _DeckStatsPageState();
}

class _DeckStatsPageState extends State<DeckStatsPage> {
  late Future<DeckProgressStats> _statsFuture;
  final _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _statsFuture = _dbHelper.getProgressStats(widget.deckId);
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fortschritt zurücksetzen?'),
        content: const Text(
          'Alle "gelernt"-Markierungen werden gelöscht. '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zurücksetzen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.resetPracticeForDeck(widget.deckId);
      setState(() {
        _statsFuture = _dbHelper.getProgressStats(widget.deckId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fortschritt zurückgesetzt')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiken: ${widget.deckTitle}'),
      ),
      body: FutureBuilder<DeckProgressStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Fehler: ${snapshot.error}'),
            );
          }

          final stats = snapshot.data!;

          if (stats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Keine Karten in diesem Deck'),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Zurück'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fortschritt',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${stats.percentage.toStringAsFixed(1)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(color: Colors.green),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: stats.percentage / 100,
                                    minHeight: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Gelernt: ${stats.knownCards}'),
                            Text('Ungelernt: ${stats.unknownCards}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _StatCard(
                      title: 'Gesamt',
                      value: stats.totalCards.toString(),
                      icon: Icons.library_books,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Fällig',
                      value: stats.dueCards.toString(),
                      icon: Icons.assignment,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'Gelernt',
                      value: stats.knownCards.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'Streak',
                      value: stats.streak.toString(),
                      icon: Icons.local_fire_department,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _resetProgress,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Fortschritt zurücksetzen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
