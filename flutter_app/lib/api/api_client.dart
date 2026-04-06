import 'dart:async';
import 'dart:html' as html show window;
import 'package:dio/dio.dart';
import 'package:eventsource/eventsource.dart';
import '../models/game_models.dart';

class ApiClient {
  ApiClient({required this.baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final String baseUrl;
  final Dio _dio;
  String? _cachedPlayerId;

  void setCachedPlayerId(String? id) {
    _cachedPlayerId = id;
    try {
      if (id == null) {
        html.window.localStorage.remove('kaat_player_id');
      } else {
        html.window.localStorage['kaat_player_id'] = id;
      }
    } catch (_) {}
  }

  String? get persistedPlayerId {
    if (_cachedPlayerId != null) return _cachedPlayerId;
    try {
      _cachedPlayerId = html.window.localStorage['kaat_player_id'];
    } catch (_) {}
    return _cachedPlayerId;
  }

  Future<RegisterResponse> register({required String name, required String role}) async {
    final res = await _dio.post('/api/register', data: {
      'name': name,
      'role': role,
      'playerId': persistedPlayerId,
    });
    final parsed = RegisterResponse.fromJson(res.data as Map<String, dynamic>);
    _cachedPlayerId = parsed.playerId;
    return parsed;
  }

  Future<void> startGame({required String playerId, required SettingsPayload settings}) async {
    await _dio.post('/api/start', data: {
      'playerId': playerId,
      'settings': settings.toJson(),
      'mode': settings.mode,
    });
  }

  Future<void> submitBid({required String playerId, required int bid}) async {
    await _dio.post('/api/bid', data: {'playerId': playerId, 'bid': bid});
  }

  Future<void> submitActual({required String playerId, required int actual}) async {
    await _dio.post('/api/actual', data: {'playerId': playerId, 'actual': actual});
  }

  Future<void> playCard({required String playerId, required String card}) async {
    await _dio.post('/api/play-card', data: {'playerId': playerId, 'card': card});
  }

  Future<void> nextRound({required String playerId}) async {
    await _dio.post('/api/next-round', data: {'playerId': playerId});
  }

  Future<void> resetLobby({required String playerId}) async {
    await _dio.post('/api/reset', data: {'playerId': playerId});
  }

  Future<void> leave({required String playerId}) async {
    await _dio.post('/api/leave', data: {'playerId': playerId});
    setCachedPlayerId(null);
  }

  Future<void> kick({required String playerId, required String targetId}) async {
    await _dio.post('/api/kick', data: {'playerId': playerId, 'targetId': targetId});
  }

  Future<Map<String, dynamic>> health() async {
    final res = await _dio.get('/health');
    return (res.data as Map<String, dynamic>);
  }

  Future<GameStateData> fetchState() async {
    final res = await _dio.get('/health');
    final body = res.data as Map<String, dynamic>;
    return GameStateData.fromJson(body);
  }

  /// Opens an SSE connection and yields parsed game events.
  /// Caller is responsible for cancelling the subscription.
  Stream<GameEvent> subscribeToEvents(String playerId) async* {
    final uri = Uri.parse('$baseUrl/events?playerId=$playerId');
    final source = await EventSource.connect(uri.toString(), headers: {'Accept': 'text/event-stream'});
    await for (final event in source) {
      final name = event.event;
      final data = event.data;
      if (name == null || data == null) continue;
      try {
        yield GameEvent.fromSse(name, data);
      } catch (_) {
        // ignore malformed events
      }
    }
  }
}
