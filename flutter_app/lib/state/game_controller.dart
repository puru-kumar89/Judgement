import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../api/api_client.dart';
import '../models/game_models.dart';

// Default to LAN IP so phones on same Wi‑Fi can connect without editing.
final baseUrlProvider = StateProvider<String>((_) => 'http://192.168.1.58:4000');

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  return ApiClient(baseUrl: baseUrl);
});

final gameControllerProvider =
    AutoDisposeNotifierProvider<GameController, GameViewState>(GameController.new);

class GameViewState {
  final GameStateData? game;
  final HandPayload? hand;
  final String? playerId;
  final String role;
  final bool connecting;
  final String? error;
  final bool sseConnected;

  const GameViewState({
    required this.game,
    required this.hand,
    required this.playerId,
    required this.role,
    required this.connecting,
    required this.error,
    required this.sseConnected,
  });

  factory GameViewState.initial() => const GameViewState(
        game: null,
        hand: null,
        playerId: null,
        role: 'player',
        connecting: false,
        error: null,
        sseConnected: false,
      );

  GameViewState copyWith({
    GameStateData? game,
    HandPayload? hand,
    String? playerId,
    String? role,
    bool? connecting,
    String? error,
    bool? sseConnected,
  }) {
    return GameViewState(
      game: game ?? this.game,
      hand: hand ?? this.hand,
      playerId: playerId ?? this.playerId,
      role: role ?? this.role,
      connecting: connecting ?? this.connecting,
      error: error,
      sseConnected: sseConnected ?? this.sseConnected,
    );
  }
}

class GameController extends AutoDisposeNotifier<GameViewState> {
  StreamSubscription<GameEvent>? _eventsSub;
  Timer? _retryTimer;

  ApiClient get _api => ref.read(apiClientProvider);

  @override
  GameViewState build() {
    ref.onDispose(() {
      _eventsSub?.cancel();
      _retryTimer?.cancel();
    });
    // Preload cached playerId if any (helps prevent duplicate seats per device).
    final cached = _api.persistedPlayerId;
    return GameViewState.initial().copyWith(playerId: cached);
  }

  Future<void> register({required String name, required String role}) async {
    state = state.copyWith(connecting: true, error: null, role: role);
    try {
      final res = await _api.register(name: name, role: role);
      _api.setCachedPlayerId(res.playerId);
      state = state.copyWith(playerId: res.playerId, role: res.role, connecting: false);
      _listenToEvents(res.playerId);
    } catch (e) {
      state = state.copyWith(connecting: false, error: 'Register failed: $e');
    }
  }

  Future<void> startGame(SettingsPayload settings) async {
    final pid = state.playerId;
    if (pid == null) {
      state = state.copyWith(error: 'Register first');
      return;
    }
    try {
      await _api.startGame(playerId: pid, settings: settings);
      // Immediately pull state in case SSE reconnect lags.
      await refreshState();
    } catch (e) {
      state = state.copyWith(error: 'Start failed: $e');
    }
  }

  Future<void> submitBid(int bid) async {
    final pid = state.playerId;
    if (pid == null) return;
    await _api.submitBid(playerId: pid, bid: bid);
  }

  Future<void> submitActual(int actual) async {
    final pid = state.playerId;
    if (pid == null) return;
    await _api.submitActual(playerId: pid, actual: actual);
  }

  Future<void> playCard(String card) async {
    final pid = state.playerId;
    if (pid == null) return;
    await _api.playCard(playerId: pid, card: card);
  }

  Future<void> nextRound() async {
    final pid = state.playerId;
    if (pid == null) return;
    await _api.nextRound(playerId: pid);
  }

  Future<void> leaveLobby() async {
    final pid = state.playerId;
    if (pid == null) return;
    try {
      await _api.leave(playerId: pid);
      _api.setCachedPlayerId(null);
      _eventsSub?.cancel();
      state = GameViewState.initial();
    } catch (e) {
      state = state.copyWith(error: 'Leave failed: $e');
    }
  }

  Future<void> kickPlayer(String targetId) async {
    final pid = state.playerId;
    if (pid == null) return;
    try {
      await _api.kick(playerId: pid, targetId: targetId);
    } catch (e) {
      state = state.copyWith(error: 'Kick failed: $e');
    }
  }

  Future<void> refreshState() async {
    try {
      final fresh = await _api.fetchState();
      state = state.copyWith(game: fresh, connecting: false, sseConnected: state.sseConnected, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Refresh failed: $e');
    }
  }

  Future<void> resetLobby() async {
    final pid = state.playerId;
    if (pid == null) return;
    try {
      await _api.resetLobby(playerId: pid);
    } catch (e) {
      state = state.copyWith(error: 'Reset failed: $e');
    }
  }

  void _listenToEvents(String playerId) {
    _eventsSub?.cancel();
    _retryTimer?.cancel();
    state = state.copyWith(connecting: true, sseConnected: false, error: null);

    _eventsSub = _api.subscribeToEvents(playerId).listen(
      (event) {
        if (event.event == 'state') {
          state = state.copyWith(
            game: GameStateData.fromJson(event.data),
            connecting: false,
            sseConnected: true,
            error: null,
          );
        } else if (event.event == 'hand') {
          state = state.copyWith(
            hand: HandPayload.fromJson(event.data),
            connecting: false,
            sseConnected: true,
          );
        } else if (event.event == 'error') {
          state = state.copyWith(error: event.data['message']?.toString());
        }
      },
      onError: (err, stack) {
        state = state.copyWith(error: 'Stream error: $err', sseConnected: false);
        _scheduleReconnect(playerId);
      },
      onDone: () {
        state = state.copyWith(sseConnected: false, connecting: false);
        _scheduleReconnect(playerId);
      },
      cancelOnError: false,
    );
  }

  void _scheduleReconnect(String playerId) {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 2), () {
      _listenToEvents(playerId);
    });
  }

  void updateBaseUrl(String url) {
    ref.read(baseUrlProvider.notifier).state = url;
  }
}
