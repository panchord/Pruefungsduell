import 'dart:convert';

/// Austauschformat für Decks (inkl. Fragen/Antworten) beim Import/Export.
///
/// Format ist versioniert, damit du später das Schema erweitern kannst.
class DeckPackage {
  static const String type = 'pruefungsduell.deck_package';
  static const int schemaVersion = 1;

  DeckPackage({
    required this.decks,
    this.generatedAt,
  });

  final List<DeckDto> decks;
  final String? generatedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'schemaVersion': schemaVersion,
        if (generatedAt != null) 'generatedAt': generatedAt,
        'decks': decks.map((d) => d.toJson()).toList(growable: false),
      };

  static DeckPackage fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw DeckPackageFormatException(
        'Deck-Paket muss ein JSON-Objekt sein.',
      );
    }

    return fromJsonMap(decoded.cast<String, dynamic>());
  }

  static DeckPackage fromJsonMap(Map<String, dynamic> map) {
    final typeRaw = map['type'];
    if (typeRaw is! String) {
      throw DeckPackageFormatException('Feld `type` muss ein String sein.');
    }
    if (typeRaw != type) {
      throw DeckPackageFormatException(
        'Ungültiger `type` Wert: `$typeRaw`.',
      );
    }

    final schemaVersionRaw = map['schemaVersion'];
    if (schemaVersionRaw is! int) {
      throw DeckPackageFormatException(
        'Feld `schemaVersion` muss eine Integer-Zahl sein.',
      );
    }
    if (schemaVersionRaw != schemaVersion) {
      throw DeckPackageFormatException(
        'Unsupported schemaVersion `$schemaVersionRaw` (erwartet `$schemaVersion`).',
      );
    }

    final decksRaw = map['decks'];
    if (decksRaw is! List) {
      throw DeckPackageFormatException('Feld `decks` muss ein Array sein.');
    }

    final decks = <DeckDto>[];
    for (final deckRaw in decksRaw) {
      if (deckRaw is! Map) {
        throw DeckPackageFormatException(
          'Jedes `deck`-Element muss ein JSON-Objekt sein.',
        );
      }
      decks.add(DeckDto.fromJsonMap(deckRaw.cast<String, dynamic>()));
    }

    if (decks.isEmpty) {
      throw DeckPackageFormatException('Mindestens ein Deck ist erforderlich.');
    }

    final generatedAtRaw = map['generatedAt'];
    final generatedAt = generatedAtRaw is String ? generatedAtRaw : null;

    return DeckPackage(
      decks: decks,
      generatedAt: generatedAt,
    );
  }
}

class DeckDto {
  DeckDto({
    required this.title,
    required this.cards,
  });

  final String title;
  final List<DeckCardDto> cards;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'cards': cards.map((c) => c.toJson()).toList(growable: false),
      };

  static DeckDto fromJsonMap(Map<String, dynamic> map) {
    final titleRaw = map['title'];
    if (titleRaw is! String) {
      throw DeckPackageFormatException('Feld `title` muss ein String sein.');
    }
    final title = titleRaw.trim();
    if (title.isEmpty) {
      throw DeckPackageFormatException('Deck `title` darf nicht leer sein.');
    }

    final cardsRaw = map['cards'];
    if (cardsRaw is! List) {
      throw DeckPackageFormatException('Feld `cards` muss ein Array sein.');
    }
    if (cardsRaw.isEmpty) {
      throw DeckPackageFormatException('Deck `${title}` muss mindestens eine Karte enthalten.');
    }

    final cards = <DeckCardDto>[];
    for (final cardRaw in cardsRaw) {
      if (cardRaw is! Map) {
        throw DeckPackageFormatException(
          'Jede Karte muss ein JSON-Objekt sein.',
        );
      }
      cards.add(DeckCardDto.fromJsonMap(cardRaw.cast<String, dynamic>()));
    }

    return DeckDto(title: title, cards: cards);
  }
}

class DeckCardDto {
  DeckCardDto({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'question': question,
        'answer': answer,
      };

  static DeckCardDto fromJsonMap(Map<String, dynamic> map) {
    final questionRaw = map['question'];
    if (questionRaw is! String) {
      throw DeckPackageFormatException(
        'Feld `question` muss ein String sein.',
      );
    }
    final question = questionRaw.trim();
    if (question.isEmpty) {
      throw DeckPackageFormatException('Feld `question` darf nicht leer sein.');
    }

    final answerRaw = map['answer'];
    if (answerRaw is! String) {
      throw DeckPackageFormatException('Feld `answer` muss ein String sein.');
    }
    final answer = answerRaw.trim();
    if (answer.isEmpty) {
      throw DeckPackageFormatException('Feld `answer` darf nicht leer sein.');
    }

    return DeckCardDto(question: question, answer: answer);
  }
}

class DeckPackageFormatException extends FormatException {
  DeckPackageFormatException(super.message);
}

