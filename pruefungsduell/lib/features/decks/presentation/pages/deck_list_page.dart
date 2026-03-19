import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pruefungsduell/core/services/database_helper.dart';
import 'package:pruefungsduell/features/decks/domain/services/deck_import_export_service.dart';
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

  Future<void> _importDeckPackage() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (pickerResult == null) return;

      final picked = pickerResult.files.single;
      final bytes = picked.bytes;
      final jsonStr = bytes != null
          ? utf8.decode(bytes)
          : picked.path != null
              ? utf8.decode(await File(picked.path!).readAsBytes())
              : throw StateError('Import-Datei konnte nicht gelesen werden.');

      final service = DeckImportExportService();
      final result = await service.importDeckPackage(json: jsonStr);

      if (!context.mounted) return;
      setState(_reloadDecks);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Import abgeschlossen: ${result.decksImported} Decks, ${result.cardsImported} Karten.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import fehlgeschlagen: $e'),
        ),
      );
    }
  }

  Future<void> _exportAllDecks() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final decks = await _dbHelper.getDecks();
      if (decks.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Keine Decks vorhanden.')),
        );
        return;
      }

      final deckIds = decks.map((d) => d['id'] as int).toList(growable: false);
      final service = DeckImportExportService();
      final package = await service.exportDecks(deckIds: deckIds);
      final jsonStr = jsonEncode(package.toJson());

      final filename = 'pruefungsduell_decks_${_timestampForFilename()}.pddeck.json';
      await _shareDeckPackageJson(filename: filename, json: jsonStr);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export fehlgeschlagen: $e'),
        ),
      );
    }
  }

  Future<void> _showAddDeckDialog() async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

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

                final navigator = Navigator.of(context);
                await _dbHelper.insertDeck(title);
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
      setState(_reloadDecks);
      messenger.showSnackBar(
        const SnackBar(content: Text('Deck angelegt')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Deckpaket importieren',
            onPressed: _importDeckPackage,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Deckpaket exportieren',
            onPressed: _exportAllDecks,
          ),
        ],
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Deck löschen'),
                            content: Text(
                              'Möchtest du das Deck "${deck['title']}" und alle dazugehörigen Fragen wirklich löschen?',
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
                          await _dbHelper.deleteDeck(deck['id'] as int);
                          if (!context.mounted) return;
                          setState(_reloadDecks);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Deck gelöscht')),
                          );
                        }
                      },
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
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

