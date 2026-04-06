import '../models/player.dart';
import '../models/round.dart';

enum GamePhase {
  setup, bidding, results, leaderboard, finished
}

class GameState {
  final GamePhase phase;
  final List<Player> players;
  final List<GameRound> rounds;
  final int currentRoundIdx;
  
  // Settings
  final int startingCards;
  final String roundStyle; // countdown, constant
  final bool lenientOvertrick;
  final int successMultiplier;
  final int penaltyMultiplier;
  final int overtrickBonus;
  
  GameState({
    this.phase = GamePhase.setup,
    this.players = const [],
    this.rounds = const [],
    this.currentRoundIdx = 0,
    this.startingCards = 10,
    this.roundStyle = 'countdown',
    this.lenientOvertrick = false,
    this.successMultiplier = 10,
    this.penaltyMultiplier = 10,
    this.overtrickBonus = 1,
  });

  GameState copyWith({
    GamePhase? phase,
    List<Player>? players,
    List<GameRound>? rounds,
    int? currentRoundIdx,
    int? startingCards,
    String? roundStyle,
    bool? lenientOvertrick,
    int? successMultiplier,
    int? penaltyMultiplier,
    int? overtrickBonus,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      rounds: rounds ?? this.rounds,
      currentRoundIdx: currentRoundIdx ?? this.currentRoundIdx,
      startingCards: startingCards ?? this.startingCards,
      roundStyle: roundStyle ?? this.roundStyle,
      lenientOvertrick: lenientOvertrick ?? this.lenientOvertrick,
      successMultiplier: successMultiplier ?? this.successMultiplier,
      penaltyMultiplier: penaltyMultiplier ?? this.penaltyMultiplier,
      overtrickBonus: overtrickBonus ?? this.overtrickBonus,
    );
  }
}
