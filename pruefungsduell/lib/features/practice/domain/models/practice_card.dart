class PracticeCard {
  const PracticeCard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    required this.lastKnown,
    required this.lastAnsweredAt,
  });

  final int id;
  final int deckId;
  final String question;
  final String answer;
  final bool? lastKnown;
  final DateTime? lastAnsweredAt;

  factory PracticeCard.fromMap(Map<String, dynamic> map) {
    final lastKnownRaw = map['last_known'] as int?;
    final lastAnsweredAtRaw = map['last_answered_at'] as int?;

    return PracticeCard(
      id: map['id'] as int,
      deckId: map['deck_id'] as int,
      question: map['question'] as String,
      answer: map['answer'] as String,
      lastKnown: lastKnownRaw == null ? null : lastKnownRaw == 1,
      lastAnsweredAt: lastAnsweredAtRaw == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastAnsweredAtRaw),
    );
  }
}

