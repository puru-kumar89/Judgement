import 'dart:convert';
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
  static const _activeGameKey = 'kaat_active_game';

  // ─── Persistence ────────────────────────────────────────────────

  Future<void> _persistPlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_prefsPrefix}players', players.map((p) => p.name).toList());
  }

  /// Persist the full game state so a page refresh restores the active session.
  Future<void> _persistGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final s = state;

    // Only persist if there is an active / navigated-home game.
    if (s.rounds.isEmpty) {
      await prefs.remove(_activeGameKey);
      return;
    }

    final json = jsonEncode({
      'phase': s.phase.name,
      'currentRoundIdx': s.currentRoundIdx,
      'roundStep': s.roundStep,
      'trumpIndex': s.trumpIndex,
      'players': s.players.map((p) => {
        'id': p.id,
        'name': p.name,
        'totalScore': p.totalScore,
        'roundChange': p.roundChange,
      }).toList(),
      'rounds': s.rounds.map((r) => {
        'cards': r.cards,
        'trump': r.trump,
        'bids': r.bids,
        'actuals': r.actuals,
      }).toList(),
    });
    await prefs.setString(_activeGameKey, json);
  }

  Future<void> _clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeGameKey);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Try to restore an active game first ──
    final savedGame = prefs.getString(_activeGameKey);
    if (savedGame != null) {
      try {
        final m = jsonDecode(savedGame) as Map<String, dynamic>;

        final restoredPlayers = (m['players'] as List).map((p) => Player(
          id: p['id'] as String,
          name: p['name'] as String,
          totalScore: p['totalScore'] as int,
          roundChange: p['roundChange'] as int,
        )).toList();

        final restoredRounds = (m['rounds'] as List).map((r) {
          final rawBids = r['bids'] as Map<String, dynamic>;
          final rawActuals = r['actuals'] as Map<String, dynamic>;
          return GameRound(
            cards: r['cards'] as int,
            trump: r['trump'] as String,
            bids: rawBids.map((k, v) => MapEntry(k, v as int)),
            actuals: rawActuals.map((k, v) => MapEntry(k, v as int)),
          );
        }).toList();

        final phaseStr = m['phase'] as String;
        final restoredPhase = GamePhase.values.firstWhere(
          (e) => e.name == phaseStr,
          orElse: () => GamePhase.bidding,
        );

        // Also reload settings from prefs for the restored session.
        state = state.copyWith(
          phase: restoredPhase,
          players: restoredPlayers,
          rounds: restoredRounds,
          currentRoundIdx: m['currentRoundIdx'] as int,
          roundStep: m['roundStep'] as int,
          trumpIndex: m['trumpIndex'] as int,
          startingCards: prefs.getInt('${_prefsPrefix}startingCards') ?? state.startingCards,
          roundStyle: prefs.getString('${_prefsPrefix}roundStyle') ?? state.roundStyle,
          lenientOvertrick: prefs.getBool('${_prefsPrefix}lenientOvertrick') ?? state.lenientOvertrick,
          successMultiplier: prefs.getInt('${_prefsPrefix}successMultiplier') ?? state.successMultiplier,
          penaltyMultiplier: prefs.getInt('${_prefsPrefix}penaltyMultiplier') ?? state.penaltyMultiplier,
          overtrickBonus: prefs.getInt('${_prefsPrefix}overtrickBonus') ?? state.overtrickBonus,
          includeNoTrump: prefs.getBool('${_prefsPrefix}includeNoTrump') ?? state.includeNoTrump,
          prefsLoaded: true,
        );
        return;
      } catch (_) {
        // Corrupted save — fall through to normal prefs load.
        await prefs.remove(_activeGameKey);
      }
    }

    // ── Normal prefs load (no active game) ──
    final storedNames = prefs.getStringList('${_prefsPrefix}players') ?? [];
    List<Player> playersFromPrefs = storedNames.asMap().entries.map((e) {
      return Player(id: (e.key + 1).toString(), name: e.value);
    }).toList();

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

  // ─── Settings ───────────────────────────────────────────────────

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

  // ─── Player management ──────────────────────────────────────────

  void addPlayer() {
    if (state.players.length >= 10) return;
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
    var currentPlayers = List<Player>.from(state.players);
    while (currentPlayers.first.id != playerId) {
      var first = currentPlayers.removeAt(0);
      currentPlayers.add(first);
    }
    state = state.copyWith(players: currentPlayers);
    _persistPlayers(state.players);
  }

  // ─── Game lifecycle ─────────────────────────────────────────────

  /// Whether there is a game currently in progress (rounds played / scores exist).
  bool get hasActiveGame => state.rounds.isNotEmpty;

  /// Navigate to the setup screen WITHOUT losing game data.
  /// Called when the user taps the KAAT logo during a game.
  void navigateHome() {
    state = state.copyWith(phase: GamePhase.setup);
    _persistGameState(); // persist the setup-phase so refresh shows home, game data intact
  }

  /// Infer what phase the active game should return to based on current round data.
  /// Deliberately simple — always returns a valid in-game phase.
  GamePhase _inferActivePhase() {
    if (state.rounds.isEmpty) return GamePhase.setup;
    final round = state.rounds[state.currentRoundIdx];
    // Check if actuals are fully entered (scores calculated, go to leaderboard).
    final allHaveActuals = state.players.isNotEmpty &&
        state.players.every((p) => round.actuals.containsKey(p.id));
    if (allHaveActuals) return GamePhase.leaderboard;
    // Check if all bids are in (bidding done, go to results to enter actuals).
    final allHaveBids = state.players.isNotEmpty &&
        state.players.every((p) => round.bids.containsKey(p.id));
    if (allHaveBids) return GamePhase.results;
    // Default: go to bidding screen.
    return GamePhase.bidding;
  }

  /// Return to the active game from the setup screen (logo-tap scenario).
  void continueGame() {
    state = state.copyWith(phase: _inferActivePhase());
    _persistGameState();
  }

  /// Start a completely fresh game — clears all scores and rounds.
  void newGame() {
    final List<String> activeSuits = state.includeNoTrump
        ? ['♠️', '♥️', '♣️', '♦️', 'NT']
        : ['♠️', '♥️', '♣️', '♦️'];

    final firstRound = GameRound(
      cards: state.startingCards,
      trump: activeSuits[0],
    );

    final initialStep = state.roundStyle == 'countdown' ? -1 : 0;

    state = state.copyWith(
      rounds: [firstRound],
      currentRoundIdx: 0,
      phase: GamePhase.bidding,
      players: state.players
          .map((p) => p.copyWith(totalScore: 0, roundChange: 0))
          .toList(),
      roundStep: initialStep,
      trumpIndex: 0,
    );
    _persistGameState();
  }

  /// Apply current settings to the ongoing game and navigate back.
  /// Settings are already in state (updated reactively via updateSettings).
  /// Scoring rule changes take effect immediately; card count / round style
  /// changes only affect rounds created after this point.
  void applyNewRules() {
    if (state.rounds.isEmpty) return; // Nothing to apply to.
    final targetPhase = _inferActivePhase();
    state = state.copyWith(phase: targetPhase);
    _persistPrefs(state);
    _persistGameState();
  }

  void startGame() {
    if (state.players.length < 3) return;

    final List<String> activeSuits = state.includeNoTrump
        ? ['♠️', '♥️', '♣️', '♦️', 'NT']
        : ['♠️', '♥️', '♣️', '♦️'];

    final firstRound = GameRound(
      cards: state.startingCards,
      trump: activeSuits[0],
    );

    final initialStep = state.roundStyle == 'countdown' ? -1 : 0;

    state = state.copyWith(
      rounds: [firstRound],
      currentRoundIdx: 0,
      phase: GamePhase.bidding,
      players: state.players
          .map((p) => p.copyWith(totalScore: 0, roundChange: 0))
          .toList(),
      roundStep: initialStep,
      trumpIndex: 0,
    );
    _persistGameState();
  }

  void setBid(String playerId, int bid) {
    final currentRound = state.rounds[state.currentRoundIdx];
    final newBids = Map<String, int>.from(currentRound.bids);
    newBids[playerId] = bid;
    final newRounds = List<GameRound>.from(state.rounds);
    newRounds[state.currentRoundIdx] = currentRound.copyWith(bids: newBids);
    state = state.copyWith(rounds: newRounds);
    _persistGameState();
  }

  void startPlaying() {
    state = state.copyWith(phase: GamePhase.results);
    _persistGameState();
  }

  void setActual(String playerId, int actual) {
    final currentRound = state.rounds[state.currentRoundIdx];
    final newActuals = Map<String, int>.from(currentRound.actuals);
    newActuals[playerId] = actual;
    final newRounds = List<GameRound>.from(state.rounds);
    newRounds[state.currentRoundIdx] = currentRound.copyWith(actuals: newActuals);
    state = state.copyWith(rounds: newRounds);
    _persistGameState();
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
    _persistGameState();
  }

  void nextRound() {
    // Rotate Dealer
    final rotatedPlayers = List<Player>.from(state.players);
    final firstPlayer = rotatedPlayers.removeAt(0);
    rotatedPlayers.add(firstPlayer);

    final currentCards = state.rounds[state.currentRoundIdx].cards;
    int step = state.roundStep;
    int nextCards;

    if (step == 0) {
      // Constant mode: card count never changes.
      nextCards = currentCards;
    } else {
      // Countdown mode: sawtooth between 1 and startingCards (inclusive).
      nextCards = currentCards + step;
      if (nextCards < 1) {
        step = 1;
        nextCards = 1;
      } else if (nextCards > state.startingCards) {
        step = -1;
        nextCards = state.startingCards;
      }
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
    _persistGameState();
  }

  void forceEndGame() {
    state = state.copyWith(phase: GamePhase.finished);
    _persistGameState();
  }

  /// Fully reset — clear saved game and return to fresh setup.
  void restartGame() {
    final freshPlayers = state.players
        .map((p) => p.copyWith(totalScore: 0, roundChange: 0))
        .toList();
    state = state.copyWith(
      phase: GamePhase.setup,
      rounds: [],
      currentRoundIdx: 0,
      roundStep: -1,
      trumpIndex: 0,
      players: freshPlayers,
    );
    _clearGameState();
  }

  void goBack() {
    if (state.phase == GamePhase.setup) return;

    if (state.phase == GamePhase.bidding) {
      if (state.currentRoundIdx == 0) {
        state = state.copyWith(phase: GamePhase.setup);
      } else {
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
      final revertedPlayers = state.players.map((p) => p.copyWith(
        totalScore: p.totalScore - p.roundChange,
        roundChange: 0,
      )).toList();
      state = state.copyWith(
        players: revertedPlayers,
        phase: GamePhase.results,
      );
    } else if (state.phase == GamePhase.finished) {
      state = state.copyWith(phase: GamePhase.leaderboard);
    }
    _persistGameState();
  }
}
