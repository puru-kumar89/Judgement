class GameRound {
  final int cards;
  final String trump;
  final Map<String, int> bids;
  final Map<String, int> actuals;

  GameRound({
    required this.cards,
    required this.trump,
    this.bids = const {},
    this.actuals = const {},
  });

  GameRound copyWith({
    int? cards,
    String? trump,
    Map<String, int>? bids,
    Map<String, int>? actuals,
  }) {
    return GameRound(
      cards: cards ?? this.cards,
      trump: trump ?? this.trump,
      bids: bids ?? this.bids,
      actuals: actuals ?? this.actuals,
    );
  }
}
