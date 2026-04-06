class Player {
  final String id;
  final String name;
  final int totalScore;
  final int roundChange;

  Player({
    required this.id,
    required this.name,
    this.totalScore = 0,
    this.roundChange = 0,
  });

  Player copyWith({
    String? name,
    int? totalScore,
    int? roundChange,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      totalScore: totalScore ?? this.totalScore,
      roundChange: roundChange ?? this.roundChange,
    );
  }
}
