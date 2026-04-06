import 'dart:convert';

enum GamePhase { lobby, bidding, playing, leaderboard, finished }

GamePhase phaseFromString(String? value) {
  switch (value) {
    case 'bidding':
      return GamePhase.bidding;
    case 'playing':
      return GamePhase.playing;
    case 'leaderboard':
      return GamePhase.leaderboard;
    case 'finished':
      return GamePhase.finished;
    case 'lobby':
    default:
      return GamePhase.lobby;
  }
}

class Player {
  final String id;
  final String name;
  final String role;
  final int totalScore;
  final int roundChange;

  const Player({
    required this.id,
    required this.name,
    required this.role,
    required this.totalScore,
    required this.roundChange,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'player',
      totalScore: (json['totalScore'] ?? 0) as int,
      roundChange: (json['roundChange'] ?? 0) as int,
    );
  }
}

class RoundState {
  final int cards;
  final String trump;
  final Map<String, int> bids;
  final Map<String, int> actuals;

  const RoundState({
    required this.cards,
    required this.trump,
    required this.bids,
    required this.actuals,
  });

  factory RoundState.fromJson(Map<String, dynamic> json) {
    final bids = <String, int>{};
    (json['bids'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      bids[k] = (v ?? 0) is int ? v as int : int.tryParse(v.toString()) ?? 0;
    });
    final actuals = <String, int>{};
    (json['actuals'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      actuals[k] = (v ?? 0) is int ? v as int : int.tryParse(v.toString()) ?? 0;
    });
    return RoundState(
      cards: (json['cards'] ?? 0) as int,
      trump: json['trump'] as String? ?? '♠️',
      bids: bids,
      actuals: actuals,
    );
  }
}

class TrickPlay {
  final String playerId;
  final String card;
  const TrickPlay({required this.playerId, required this.card});

  factory TrickPlay.fromJson(Map<String, dynamic> json) {
    return TrickPlay(
      playerId: json['playerId'] as String,
      card: json['card'] as String,
    );
  }
}

class GameStateData {
  final String mode;
  final String? hostId;
  final List<Player> players;
  final Map<String, dynamic> settings;
  final List<RoundState> rounds;
  final int currentRoundIdx;
  final GamePhase phase;
  final List<TrickPlay> currentTrick;
  final String? currentTurnPlayerId;
  final String? leadPlayerId;
  final int trickNumber;

  const GameStateData({
    required this.mode,
    required this.hostId,
    required this.players,
    required this.settings,
    required this.rounds,
    required this.currentRoundIdx,
    required this.phase,
    required this.currentTrick,
    required this.currentTurnPlayerId,
    required this.leadPlayerId,
    required this.trickNumber,
  });

  RoundState? get currentRound =>
      currentRoundIdx >= 0 && currentRoundIdx < rounds.length ? rounds[currentRoundIdx] : null;

  factory GameStateData.fromJson(Map<String, dynamic> json) {
    return GameStateData(
      mode: json['mode'] as String? ?? 'physical',
      hostId: json['hostId'] as String?,
      players: (json['players'] as List<dynamic>? ?? [])
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      settings: (json['settings'] as Map<String, dynamic>? ?? {}),
      rounds: (json['rounds'] as List<dynamic>? ?? [])
          .map((r) => RoundState.fromJson(r as Map<String, dynamic>))
          .toList(),
      currentRoundIdx: (json['currentRoundIdx'] ?? 0) as int,
      phase: phaseFromString(json['phase'] as String?),
      currentTrick: (json['currentTrick'] as List<dynamic>? ?? [])
          .map((t) => TrickPlay.fromJson(t as Map<String, dynamic>))
          .toList(),
      currentTurnPlayerId: json['currentTurnPlayerId'] as String?,
      leadPlayerId: json['leadPlayerId'] as String?,
      trickNumber: (json['trickNumber'] ?? 1) as int,
    );
  }
}

class HandPayload {
  final List<String> hand;
  final int round;
  const HandPayload({required this.hand, required this.round});

  factory HandPayload.fromJson(Map<String, dynamic> json) {
    return HandPayload(
      hand: (json['hand'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      round: (json['round'] ?? 0) as int,
    );
  }
}

class RegisterResponse {
  final String playerId;
  final String role;
  final String? hostId;
  const RegisterResponse({required this.playerId, required this.role, required this.hostId});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      playerId: json['playerId'] as String,
      role: json['role'] as String? ?? 'player',
      hostId: json['hostId'] as String?,
    );
  }
}

class SettingsPayload {
  final int startingCards;
  final String roundStyle;
  final bool lenientOvertrick;
  final String mode;
  final int successMultiplier;
  final int penaltyMultiplier;
  final int overtrickBonus;

  const SettingsPayload({
    required this.startingCards,
    required this.roundStyle,
    required this.lenientOvertrick,
    required this.mode,
    required this.successMultiplier,
    required this.penaltyMultiplier,
    required this.overtrickBonus,
  });

  Map<String, dynamic> toJson() => {
        'startingCards': startingCards,
        'roundStyle': roundStyle,
        'lenientOvertrick': lenientOvertrick,
        'successMultiplier': successMultiplier,
        'penaltyMultiplier': penaltyMultiplier,
        'overtrickBonus': overtrickBonus,
      };
}

class GameEvent {
  final String event;
  final Map<String, dynamic> data;
  GameEvent({required this.event, required this.data});

  factory GameEvent.fromSse(String event, String data) {
    return GameEvent(event: event, data: jsonDecode(data) as Map<String, dynamic>);
  }
}
