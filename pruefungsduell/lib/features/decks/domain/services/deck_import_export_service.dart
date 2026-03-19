import 'package:pruefungsduell/core/services/database_helper.dart';
import 'package:pruefungsduell/features/decks/domain/models/deck_package.dart';

class DeckImportExportService {
  DeckImportExportService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<DeckPackage> exportDecks({required List<int> deckIds}) async {
    if (deckIds.isEmpty) {
      throw ArgumentError.value(deckIds, 'deckIds', 'Muss mindestens ein Deck enthalten.');
    }

    final decksRaw = await _dbHelper.getDecks();
    final titlesById = <int, String>{};
    for (final row in decksRaw) {
      final id = row['id'];
      final title = row['title'];
      if (id is int && title is String && deckIds.contains(id)) {
        titlesById[id] = title;
      }
    }

    // Wenn ein deckId unbekannt ist, ist das ein Programmierfehler (keine Magie).
    for (final id in deckIds) {
      if (!titlesById.containsKey(id)) {
        throw StateError('Deck mit id=$id nicht gefunden.');
      }
    }

    final decks = <DeckDto>[];
    for (final deckId in deckIds) {
      final deckTitle = titlesById[deckId]!;
      final cardsRaw = await _dbHelper.getCardsForDeck(deckId);

      final cards = cardsRaw.map((m) {
        final question = m['question'];
        final answer = m['answer'];
        if (question is! String || answer is! String) {
          throw StateError('Ungültige Card-Daten in DB für deckId=$deckId.');
        }
        return DeckCardDto(question: question, answer: answer);
      }).toList(growable: false);

      // Ein Deck ohne Karten hat keinen praktischen Nutzen für Import/Export.
      if (cards.isNotEmpty) {
        decks.add(DeckDto(title: deckTitle, cards: cards));
      }
    }

    if (decks.isEmpty) {
      throw StateError('Keine Karten in den ausgewählten Decks gefunden.');
    }

    return DeckPackage(
      decks: decks,
      generatedAt: DateTime.now().toIso8601String(),
    );
  }

  Future<DeckImportResult> importDeckPackage({required String json}) async {
    final package = DeckPackage.fromJsonString(json);
    return importDeckPackageFromModel(package);
  }

  Future<DeckImportResult> importDeckPackageFromModel(DeckPackage package) async {
    final db = await _dbHelper.database;
    final existingTitlesLower = await _dbHelper.getDeckTitlesLowercased();

    var cardsImported = 0;
    final createdDeckTitles = <String>[];

    await db.transaction((txn) async {
      for (final deckDto in package.decks) {
        final uniqueTitle = makeUniqueTitle(
          baseTitle: deckDto.title,
          existingTitlesLower: existingTitlesLower,
        );

        // Für die nachfolgenden Decktitel innerhalb derselben Import-Datei.
        existingTitlesLower.add(uniqueTitle.toLowerCase());

        final deckId = await _dbHelper.insertDeckOnDb(txn, uniqueTitle);
        createdDeckTitles.add(uniqueTitle);

        for (final cardDto in deckDto.cards) {
          await _dbHelper.insertCardOnDb(
            db: txn,
            deckId: deckId,
            question: cardDto.question,
            answer: cardDto.answer,
          );
          cardsImported++;
        }
      }
    });

    return DeckImportResult(
      decksImported: package.decks.length,
      cardsImported: cardsImported,
      createdDeckTitles: createdDeckTitles,
    );
  }

  /// Erzeugt einen eindeutigen Titel (case-insensitive) durch Suffixe wie `"(2)"`.
  static String makeUniqueTitle({
    required String baseTitle,
    required Set<String> existingTitlesLower,
  }) {
    final base = baseTitle.trim();
    if (base.isEmpty) {
      throw ArgumentError.value(baseTitle, 'baseTitle', 'Darf nicht leer sein.');
    }

    final baseLower = base.toLowerCase();
    if (!existingTitlesLower.contains(baseLower)) {
      return base;
    }

    var counter = 2;
    while (true) {
      final candidate = '$base ($counter)';
      final candidateLower = candidate.toLowerCase();
      if (!existingTitlesLower.contains(candidateLower)) {
        return candidate;
      }
      counter++;
    }
  }
}

class DeckImportResult {
  DeckImportResult({
    required this.decksImported,
    required this.cardsImported,
    required this.createdDeckTitles,
  });

  final int decksImported;
  final int cardsImported;
  final List<String> createdDeckTitles;
}

