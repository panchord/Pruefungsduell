/// Mögliche Schwierigkeitsstufen für das Duell.
enum DuelDifficulty {
  easy,
  medium,
  hard,
}

/// Erweiterungen für Labels und Trefferquoten je Schwierigkeit.
extension DuelDifficultyX on DuelDifficulty {
  String get label => switch (this) {
        DuelDifficulty.easy => 'Leicht',
        DuelDifficulty.medium => 'Mittel',
        DuelDifficulty.hard => 'Schwer',
      };

  double get hitRate => switch (this) {
        DuelDifficulty.easy => 0.50,
        DuelDifficulty.medium => 0.65,
        DuelDifficulty.hard => 0.80,
      };
}

