import 'dart:math';

import 'package:pruefungsduell/features/duel/domain/models/duel_difficulty.dart';

/// Simuliert den Bot im Duell und entscheidet,
/// ob er eine Frage richtig beantwortet.
class PruefiBot {
  PruefiBot({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Gibt zurück, ob der Bot bei der gegebenen Schwierigkeit
  /// die aktuelle Frage richtig beantwortet.
  bool answerCorrect(DuelDifficulty difficulty) {
    return _random.nextDouble() < difficulty.hitRate;
  }
}

