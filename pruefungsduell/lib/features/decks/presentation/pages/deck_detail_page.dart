import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pruefungsduell/core/services/database_helper.dart';
import 'package:pruefungsduell/features/decks/domain/services/deck_import_export_service.dart';
import 'package:pruefungsduell/features/statistics/presentation/pages/deck_stats_page.dart';

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

  Future<void> _shareDeckPackageJson({
    required String filename,
    required String json,
  }) async {
    final tmpDir = await getTemporaryDirectory();
    final filePath = '${tmpDir.path}/$filename';
    final file = File(filePath);
    await file.writeAsString(json, encoding: utf8);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Pruefungsduell Deckpaket teilen',
      subject: 'Deckpaket',
    );
  }

  String _timestampForFilename() {
    return DateTime.now().toIso8601String().replaceAll(':', '-');
  }

  String _sanitizeFilename(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'deck_package';
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  Future<void> _exportCurrentDeck() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final service = DeckImportExportService();
      final package = await service.exportDecks(deckIds: [widget.deckId]);
      final jsonStr = jsonEncode(package.toJson());

      final title = _sanitizeFilename(widget.deckTitle);
      final filename =
          '${title}_${_timestampForFilename()}.pddeck.json';
      await _shareDeckPackageJson(filename: filename, json: jsonStr);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export fehlgeschlagen: $e'),
        ),
      );
    }
  }

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
    final messenger = ScaffoldMessenger.of(context);

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

                final navigator = Navigator.of(context);
                await _dbHelper.insertCard(
                  deckId: widget.deckId,
                  question: question,
                  answer: answer,
                );
                if (!context.mounted) return;
                navigator.pop(true);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      setState(_reloadCards);
      messenger.showSnackBar(
        const SnackBar(content: Text('Frage hinzugefügt')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Deckpaket exportieren',
            onPressed: _exportCurrentDeck,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiken anzeigen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeckStatsPage(
                    deckId: widget.deckId,
                    deckTitle: widget.deckTitle,
                  ),
                ),
              );
            },
          ),
        ],
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Frage löschen'),
                        content: const Text(
                          'Möchtest du diese Frage wirklich löschen?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Abbrechen'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Löschen'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await _dbHelper.deleteCard(card['id'] as int);
                      if (!context.mounted) return;
                      setState(_reloadCards);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Frage gelöscht')),
                      );
                    }
                  },
                ),
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

