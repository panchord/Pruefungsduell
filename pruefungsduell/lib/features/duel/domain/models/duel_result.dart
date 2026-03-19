import 'package:pruefungsduell/features/duel/domain/models/duel_difficulty.dart';

class DuelResult {
  const DuelResult({
    required this.deckId,
    required this.deckTitle,
    required this.difficulty,
    required this.playedRounds,
    required this.userScore,
    required this.botScore,
  });

  final int deckId;
  final String deckTitle;
  final DuelDifficulty difficulty;
  final int playedRounds;
  final int userScore;
  final int botScore;

  String get outcomeText {
    if (userScore > botScore) return 'Du gewinnst!';
    if (userScore < botScore) return 'Prüfi gewinnt!';
    return 'Unentschieden!';
  }
}

