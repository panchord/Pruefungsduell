import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pruefungsduell/features/duel/domain/models/duel_difficulty.dart';
import 'package:pruefungsduell/features/duel/domain/services/pruefi_bot.dart';

void main() {
  test('PruefiBot: Trefferquoten sind ungefähr passend', () {
    bool run(DuelDifficulty difficulty) {
      const trials = 2000;
      final bot = PruefiBot(random: Random(42));
      var correct = 0;
      for (var i = 0; i < trials; i++) {
        if (bot.answerCorrect(difficulty)) correct++;
      }
      final rate = correct / trials;
      final expected = difficulty.hitRate;
      return (rate - expected).abs() < 0.05;
    }

    expect(run(DuelDifficulty.easy), isTrue);
    expect(run(DuelDifficulty.medium), isTrue);
    expect(run(DuelDifficulty.hard), isTrue);
  });
}

