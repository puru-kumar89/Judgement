import 'dart:math';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_state.dart';
import '../models/player.dart';
import '../models/round.dart';

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState(
    players: [
      Player(id: '1', name: ''),
      Player(id: '2', name: ''),
      Player(id: '3', name: ''),
    ]
  ));

  final List<String> _suits = ['♠️', '♥️', '♦️', '♣️'];
  static const _prefsPrefix = 'kaat_settings_';
  bool _prefsLoaded = false;
  Future<void> _persistPlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_prefsPrefix}players', players.map((p) => p.name).toList());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedNames = prefs.getStringList('${_prefsPrefix}players') ?? [];

    List<Player> playersFromPrefs = storedNames.asMap().entries.map((e) {
      return Player(id: (e.key + 1).toString(), name: e.value);
    }).toList();

    // Ensure at least 3 empty slots
    while (playersFromPrefs.length < 3) {
      playersFromPrefs.add(Player(id: (playersFromPrefs.length + 1).toString(), name: ''));
    }

    state = state.copyWith(
      players: playersFromPrefs.isNotEmpty ? playersFromPrefs : state.players,
      startingCards: prefs.getInt('${_prefsPrefix}startingCards') ?? state.startingCards,
      roundStyle: prefs.getString('${_prefsPrefix}roundStyle') ?? state.roundStyle,
      lenientOvertrick: prefs.getBool('${_prefsPrefix}lenientOvertrick') ?? state.lenientOvertrick,
      successMultiplier: prefs.getInt('${_prefsPrefix}successMultiplier') ?? state.successMultiplier,
      penaltyMultiplier: prefs.getInt('${_prefsPrefix}penaltyMultiplier') ?? state.penaltyMultiplier,
      overtrickBonus: prefs.getInt('${_prefsPrefix}overtrickBonus') ?? state.overtrickBonus,
      includeNoTrump: prefs.getBool('${_prefsPrefix}includeNoTrump') ?? state.includeNoTrump,
      prefsLoaded: true,
    );
    _prefsLoaded = true;
  }

  Future<void> _persistPrefs(GameState next) async {
    final prefs = await SharedPreferences.getInstance();
    await _persistPlayers(next.players);
    await prefs.setInt('${_prefsPrefix}startingCards', next.startingCards);
    await prefs.setString('${_prefsPrefix}roundStyle', next.roundStyle);
    await prefs.setBool('${_prefsPrefix}lenientOvertrick', next.lenientOvertrick);
    await prefs.setInt('${_prefsPrefix}successMultiplier', next.successMultiplier);
    await prefs.setInt('${_prefsPrefix}penaltyMultiplier', next.penaltyMultiplier);
    await prefs.setInt('${_prefsPrefix}overtrickBonus', next.overtrickBonus);
    await prefs.setBool('${_prefsPrefix}includeNoTrump', next.includeNoTrump);
  }

  /// Load saved settings once when the notifier is created.
  void init() {
    _loadPrefs();
  }

  Future<void> saveCurrentSettings() async {
    await _persistPrefs(state);
  }

  Future<void> resetSettings() async {
    final reset = GameState();
    state = state.copyWith(
      startingCards: reset.startingCards,
      roundStyle: reset.roundStyle,
      lenientOvertrick: reset.lenientOvertrick,
      successMultiplier: reset.successMultiplier,
      penaltyMultiplier: reset.penaltyMultiplier,
      overtrickBonus: reset.overtrickBonus,
      includeNoTrump: reset.includeNoTrump,
      prefsLoaded: true,
    );
    await _persistPrefs(state);
  }

  void updateSettings({
    int? startingCards,
    String? roundStyle,
    bool? lenientOvertrick,
    int? successMultiplier,
    int? penaltyMultiplier,
    int? overtrickBonus,
    bool? includeNoTrump,
  }) {
    final next = state.copyWith(
      startingCards: startingCards,
      roundStyle: roundStyle,
      lenientOvertrick: lenientOvertrick,
      successMultiplier: successMultiplier,
      penaltyMultiplier: penaltyMultiplier,
      overtrickBonus: overtrickBonus,
      includeNoTrump: includeNoTrump,
    );
    state = next;
    _persistPrefs(next);
  }

  void addPlayer() {
    final newList = List<Player>.from(state.players);
    newList.add(Player(id: DateTime.now().millisecondsSinceEpoch.toString(), name: ''));
    state = state.copyWith(players: newList);
    _persistPlayers(state.players);
  }

  void removePlayer(String id) {
    if (state.players.length <= 3) return;
    final newList = state.players.where((p) => p.id != id).toList();
    state = state.copyWith(players: newList);
    _persistPlayers(state.players);
  }

  void updatePlayerName(String id, String newName) {
    final newList = state.players.map((p) {
      if (p.id == id) return p.copyWith(name: newName);
      return p;
    }).toList();
    state = state.copyWith(players: newList);
    _persistPlayers(state.players);
  }

  void reorderPlayers(int oldIndex, int newIndex) {
    final newList = List<Player>.from(state.players);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = state.copyWith(players: newList);
    _persistPlayers(state.players);
  }

  void setDealer(String playerId) {
    if (state.players.isEmpty) return;
    if (state.players.first.id == playerId) return;

    // Rotate so selected player is at the front (dealer)
    var currentPlayers = List<Player>.from(state.players);
    while (currentPlayers.first.id != playerId) {
      var first = currentPlayers.removeAt(0);
      currentPlayers.add(first);
    }
    state = state.copyWith(players: currentPlayers);
    _persistPlayers(state.players);
  }

  void startGame() {
    if (state.players.length < 3) return;

    final List<String> activeSuits = state.includeNoTrump 
        ? ['♠️', '♥️', '♣️', '♦️', 'NT'] 
        : ['♠️', '♥️', '♣️', '♦️'];

    // Start with first round only; subsequent rounds extend endlessly.
    final firstRound = GameRound(
      cards: state.startingCards,
      trump: activeSuits[0],
    );

    state = state.copyWith(
      rounds: [firstRound],
      currentRoundIdx: 0,
      phase: GamePhase.bidding,
      players: state.players.map((p) => p.copyWith(totalScore: 0, roundChange: 0)).toList(),
      roundStep: -1,
      trumpIndex: 0,
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
    // Rotate Dealer
    final rotatedPlayers = List<Player>.from(state.players);
    final firstPlayer = rotatedPlayers.removeAt(0);
    rotatedPlayers.add(firstPlayer);

    // Determine next cards using a sawtooth pattern between 1 and startingCards
    final currentCards = state.rounds[state.currentRoundIdx].cards;
    int step = state.roundStep;
    int nextCards = currentCards + step;
    if (nextCards < 1) {
      step = 1;
      nextCards = 2; // bounce up
    } else if (nextCards > state.startingCards) {
      step = -1;
      nextCards = state.startingCards - 1;
    }

    final activeSuits = state.includeNoTrump 
        ? ['♠️', '♥️', '♣️', '♦️', 'NT'] 
        : ['♠️', '♥️', '♣️', '♦️'];
    final nextTrumpIndex = (state.trumpIndex + 1) % activeSuits.length;

    final newRounds = List<GameRound>.from(state.rounds);
    newRounds.add(GameRound(
      cards: nextCards,
      trump: activeSuits[nextTrumpIndex],
    ));

    state = state.copyWith(
      currentRoundIdx: state.currentRoundIdx + 1,
      players: rotatedPlayers,
      rounds: newRounds,
      roundStep: step,
      trumpIndex: nextTrumpIndex,
      phase: GamePhase.bidding,
    );
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
