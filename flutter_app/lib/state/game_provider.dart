import 'dart:math';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'game_state.dart';
import '../models/player.dart';
import '../models/round.dart';

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState(
    players: [
      Player(id: '1', name: 'Alice'),
      Player(id: '2', name: 'Bob'),
      Player(id: '3', name: 'Charlie'),
    ]
  ));

  final List<String> _suits = ['♠️', '♥️', '♦️', '♣️'];

  void updateSettings({
    int? startingCards,
    String? roundStyle,
    bool? lenientOvertrick,
    int? successMultiplier,
    int? penaltyMultiplier,
    int? overtrickBonus,
    bool? includeNoTrump,
  }) {
    state = state.copyWith(
      startingCards: startingCards,
      roundStyle: roundStyle,
      lenientOvertrick: lenientOvertrick,
      successMultiplier: successMultiplier,
      penaltyMultiplier: penaltyMultiplier,
      overtrickBonus: overtrickBonus,
      includeNoTrump: includeNoTrump,
    );
  }

  void addPlayer() {
    final newList = List<Player>.from(state.players);
    newList.add(Player(id: DateTime.now().millisecondsSinceEpoch.toString(), name: 'Player ${newList.length + 1}'));
    state = state.copyWith(players: newList);
  }

  void removePlayer(String id) {
    if (state.players.length <= 3) return;
    final newList = state.players.where((p) => p.id != id).toList();
    state = state.copyWith(players: newList);
  }

  void updatePlayerName(String id, String newName) {
    final newList = state.players.map((p) {
      if (p.id == id) return p.copyWith(name: newName);
      return p;
    }).toList();
    state = state.copyWith(players: newList);
  }

  void setDealer(String playerId) {
    if (state.players.isEmpty) return;
    if (state.players.last.id == playerId) return;
    
    // Rotate the table order relative to the selected dealer
    var currentPlayers = List<Player>.from(state.players);
    while (currentPlayers.last.id != playerId) {
      var first = currentPlayers.removeAt(0);
      currentPlayers.add(first);
    }
    state = state.copyWith(players: currentPlayers);
  }

  void startGame() {
    if (state.players.length < 3) return;
    
    // Generate rounds
    List<int> cardsSequence = [];
    if (state.roundStyle == 'countdown') {
      for (var c = state.startingCards; c >= 1; c--) {
        cardsSequence.add(c);
      }
    } else {
      for (var c = 0; c < state.startingCards; c++) {
         cardsSequence.add(state.startingCards);
      }
    }

    final List<String> activeSuits = state.includeNoTrump 
        ? ['♠️', '♥️', '♣️', '♦️', 'NT'] 
        : ['♠️', '♥️', '♣️', '♦️'];
        
    List<GameRound> generatedRounds = [];
    for (int i = 0; i < cardsSequence.length; i++) {
      generatedRounds.add(GameRound(
        cards: cardsSequence[i],
        trump: activeSuits[i % activeSuits.length],
      ));
    }

    state = state.copyWith(
      rounds: generatedRounds,
      currentRoundIdx: 0,
      phase: GamePhase.bidding,
      players: state.players.map((p) => p.copyWith(totalScore: 0, roundChange: 0)).toList()
    );
  }

  void setBid(String playerId, int bid) {
    final currentRound = state.rounds[state.currentRoundIdx];
    final newBids = Map<String, int>.from(currentRound.bids);
    newBids[playerId] = bid;
    
    final newRounds = List<GameRound>.from(state.rounds);
    newRounds[state.currentRoundIdx] = currentRound.copyWith(bids: newBids);
    state = state.copyWith(rounds: newRounds);
  }

  void startPlaying() {
    state = state.copyWith(phase: GamePhase.results);
  }
  
  void setActual(String playerId, int actual) {
    final currentRound = state.rounds[state.currentRoundIdx];
    final newActuals = Map<String, int>.from(currentRound.actuals);
    newActuals[playerId] = actual;
    
    final newRounds = List<GameRound>.from(state.rounds);
    newRounds[state.currentRoundIdx] = currentRound.copyWith(actuals: newActuals);
    state = state.copyWith(rounds: newRounds);
  }

  void calculateScores() {
    final currentRound = state.rounds[state.currentRoundIdx];
    
    int totalActuals = currentRound.actuals.values.fold(0, (sum, val) => sum + val);
    if (totalActuals != currentRound.cards) {
      throw Exception("Total tricks ($totalActuals) must equal cards dealt (${currentRound.cards}).");
    }

    final updatedPlayers = state.players.map((p) {
      final bid = currentRound.bids[p.id] ?? 0;
      final actual = currentRound.actuals[p.id] ?? 0;
      int points = 0;

      if (bid == actual) {
        points = bid * state.successMultiplier;
      } else if (actual > bid) {
        if (state.lenientOvertrick) {
          points = bid * state.successMultiplier + (actual - bid) * state.overtrickBonus;
        } else {
          points = -bid * state.penaltyMultiplier;
        }
      } else {
        points = -bid * state.penaltyMultiplier;
      }

      return p.copyWith(
        roundChange: points,
        totalScore: p.totalScore + points,
      );
    }).toList();

    state = state.copyWith(
      players: updatedPlayers,
      phase: GamePhase.leaderboard,
    );
  }

  void nextRound() {
    if (state.currentRoundIdx >= state.rounds.length - 1) {
      state = state.copyWith(phase: GamePhase.finished);
    } else {
      // Rotate Dealer
      final rotatedPlayers = List<Player>.from(state.players);
      final firstPlayer = rotatedPlayers.removeAt(0);
      rotatedPlayers.add(firstPlayer);

      state = state.copyWith(
        currentRoundIdx: state.currentRoundIdx + 1,
        players: rotatedPlayers,
        phase: GamePhase.bidding,
      );
    }
  }

  void forceEndGame() {
    state = state.copyWith(phase: GamePhase.finished);
  }

  void restartGame() {
    state = state.copyWith(phase: GamePhase.setup);
  }

  void goBack() {
    if (state.phase == GamePhase.setup) return;

    if (state.phase == GamePhase.bidding) {
      if (state.currentRoundIdx == 0) {
        state = state.copyWith(phase: GamePhase.setup);
      } else {
        // We came from the leaderboard of the previous round. Un-rotate players.
        final unrotatedPlayers = List<Player>.from(state.players);
        final lastPlayer = unrotatedPlayers.removeLast();
        unrotatedPlayers.insert(0, lastPlayer);
        
        state = state.copyWith(
          currentRoundIdx: state.currentRoundIdx - 1,
          players: unrotatedPlayers,
          phase: GamePhase.leaderboard,
        );
      }
    } else if (state.phase == GamePhase.results) {
      state = state.copyWith(phase: GamePhase.bidding);
    } else if (state.phase == GamePhase.leaderboard) {
      // Revert the scores calculating and go to results
      final revertedPlayers = state.players.map((p) => p.copyWith(
        totalScore: p.totalScore - p.roundChange,
        roundChange: 0,
      )).toList();
      
      state = state.copyWith(
        players: revertedPlayers,
        phase: GamePhase.results,
      );
    } else if (state.phase == GamePhase.finished) {
      // Finished comes from leaderboard of current index
      state = state.copyWith(phase: GamePhase.leaderboard);
    }
  }
}
