# Kaat Flutter Client

This folder contains a lightweight, production-ready Flutter client for the LAN Kaat tracker server in the repository root (`server.js`). It focuses on stability, clear layering, and resilience when the SSE connection drops.

## Quick start
1. Ensure Flutter 3.19+ is installed (we vendored the SDK in `/tmp/flutter`).
2. From this folder run `flutter pub get` (we already ran `flutter create --overwrite .` to generate platforms).
3. Start the Node server in the repo root: `npm install && npm run start`.
4. Launch the app: `flutter run -d chrome` (or an emulator/device). The default base URL is `http://localhost:3000` (adjust if running on an Android emulator to `http://10.0.2.2:3000`). Change it in the Connection card for desktop or iOS.

## Architecture
- **State management**: Riverpod (`hooks_riverpod`) via `GameController` (`lib/state/game_controller.dart`). It handles registration, game actions, and auto-reconnecting SSE.
- **Networking**: `dio` for REST calls to `/api/register`, `/api/start`, `/api/bid`, `/api/actual`, `/api/play-card`, `/api/next-round`; `eventsource` for Server-Sent Events on `/events?playerId=...`.
- **Models**: `lib/models/game_models.dart` mirrors server payloads (players, rounds, tricks, hand updates).
- **UI**: `lib/ui/screens/home_screen.dart` renders connection, lobby/start controls (host only), bidding, play area with hand chips, trick view, and leaderboard/next-round controls. Responsive layout keeps cards readable on mobile and wide screens.

## Production-minded notes
- SSE stream auto-reconnects with a backoff timer if the connection drops.
- Base URL is a state provider; change it per environment without code changes.
- The code avoids codegen to stay portable (no build_runner needed).

## Next steps
- Add persistence for `playerId` (e.g., `shared_preferences`) to auto-rejoin after app restarts.
- Harden validation (max bids, following suit hints) and add animations for trick wins.
- Add integration tests with `flutter_test` once Flutter is installed.
