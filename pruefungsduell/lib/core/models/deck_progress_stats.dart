class DeckProgressStats {
  final int totalCards;
  final int knownCards;
  final int dueCards;
  final double percentage;
  final int streak;

  DeckProgressStats({
    required this.totalCards,
    required this.knownCards,
    required this.dueCards,
    required this.percentage,
    required this.streak,
  });

  int get unknownCards => totalCards - knownCards;

  bool get isEmpty => totalCards == 0;

  @override
  String toString() => 
    'DeckProgressStats(total: $totalCards, known: $knownCards, due: $dueCards, percentage: $percentage%, streak: $streak)';
}
