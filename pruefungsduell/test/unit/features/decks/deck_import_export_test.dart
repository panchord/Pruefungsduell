import 'package:flutter_test/flutter_test.dart';
import 'package:pruefungsduell/features/decks/domain/models/deck_package.dart';
import 'package:pruefungsduell/features/decks/domain/services/deck_import_export_service.dart';

void main() {
  test('DeckPackage.fromJsonString: happy path', () {
    final jsonStr = '''
    {
      "type": "${DeckPackage.type}",
      "schemaVersion": ${DeckPackage.schemaVersion},
      "decks": [
        {
          "title": "Deck A",
          "cards": [
            { "question": "Q1", "answer": "A1" },
            { "question": "Q2", "answer": "A2" }
          ]
        }
      ]
    }
    ''';

    final pkg = DeckPackage.fromJsonString(jsonStr);
    expect(pkg.decks, hasLength(1));
    expect(pkg.decks.first.title, 'Deck A');
    expect(pkg.decks.first.cards, hasLength(2));
    expect(pkg.decks.first.cards.first.question, 'Q1');
  });

  test('DeckPackage.fromJsonString: schemaVersion mismatch', () {
    final jsonStr = '''
    {
      "type": "${DeckPackage.type}",
      "schemaVersion": ${DeckPackage.schemaVersion + 1},
      "decks": [
        { "title": "Deck A", "cards": [ { "question": "Q1", "answer": "A1" } ] }
      ]
    }
    ''';

    expect(() => DeckPackage.fromJsonString(jsonStr), throwsA(isA<DeckPackageFormatException>()));
  });

  test('DeckPackage.fromJsonString: fehlende answer wirft', () {
    final jsonStr = '''
    {
      "type": "${DeckPackage.type}",
      "schemaVersion": ${DeckPackage.schemaVersion},
      "decks": [
        { "title": "Deck A", "cards": [ { "question": "Q1" } ] }
      ]
    }
    ''';

    expect(() => DeckPackage.fromJsonString(jsonStr), throwsA(isA<DeckPackageFormatException>()));
  });

  test('DeckImportExportService.makeUniqueTitle: generiert Suffixe', () {
    final existing = <String>{
      'titel',
      'titel (2)',
      'titel (3)',
      'andere',
    };

    final unique = DeckImportExportService.makeUniqueTitle(
      baseTitle: 'Titel',
      existingTitlesLower: existing,
    );
    expect(unique, 'Titel (4)');

    final unique2 = DeckImportExportService.makeUniqueTitle(
      baseTitle: 'Neues Deck',
      existingTitlesLower: existing,
    );
    expect(unique2, 'Neues Deck');
  });
}

