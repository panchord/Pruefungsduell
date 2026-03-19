import 'dart:math';

import 'package:pruefungsduell/features/duel/domain/models/duel_difficulty.dart';

class PruefiBot {
  PruefiBot({Random? random}) : _random = random ?? Random();

  final Random _random;

  bool answerCorrect(DuelDifficulty difficulty) {
    return _random.nextDouble() < difficulty.hitRate;
  }
}

