import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game_models.dart';
import '../../state/game_controller.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final nameCtrl = useTextEditingController(text: 'Player ${DateTime.now().millisecond}');
    final baseUrlCtrl = useTextEditingController(text: ref.watch(baseUrlProvider));
    final role = useState('player');
    final startingCardsCtrl = useTextEditingController(text: '10');
    final roundStyle = useState('countdown');
    final lenient = useState(true);
    final preset = useState('standard');
    final successCtrl = useTextEditingController(text: '10');
    final penaltyCtrl = useTextEditingController(text: '10');
    final bonusCtrl = useTextEditingController(text: '1');
    final bidCtrl = useTextEditingController();
    final actualCtrl = useTextEditingController();

    useEffect(() {
      baseUrlCtrl.addListener(() => controller.updateBaseUrl(baseUrlCtrl.text.trim()));
      return null;
    }, const []);

    void applyPreset(String value) {
      preset.value = value;
      if (value == 'standard') {
        successCtrl.text = '10';
        penaltyCtrl.text = '10';
        bonusCtrl.text = '1';
        lenient.value = true;
      } else if (value == 'strict') {
        successCtrl.text = '10';
        penaltyCtrl.text = '10';
        bonusCtrl.text = '0';
        lenient.value = false;
      }
      // custom leaves current values untouched
    }

    final game = state.game;
    final currentRound = game?.currentRound;
    final me = game?.players.firstWhere(
          (p) => p.id == state.playerId,
          orElse: () => Player(id: state.playerId ?? '', name: nameCtrl.text, role: state.role, totalScore: 0, roundChange: 0),
        ) ??
        (state.playerId != null
            ? Player(id: state.playerId!, name: nameCtrl.text, role: state.role, totalScore: 0, roundChange: 0)
            : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaat LAN Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync state',
            onPressed: controller.refreshState,
          ),
          if (state.sseConnected)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.wifi, color: Colors.green),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.wifi_off, color: Colors.redAccent),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Card(
                  title: 'Connection',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: baseUrlCtrl,
                        decoration: const InputDecoration(labelText: 'Server base URL', hintText: 'http://127.0.0.1:4000'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(labelText: 'Display name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: role.value,
                            items: const [
                              DropdownMenuItem(value: 'player', child: Text('Player')),
                              DropdownMenuItem(value: 'host', child: Text('Host')),
                            ],
                            onChanged: state.playerId == null ? (v) => role.value = v ?? 'player' : null,
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: state.connecting
                                ? null
                                : () {
                                    controller.register(name: nameCtrl.text.trim(), role: role.value);
                                  },
                            icon: Icon(state.playerId == null ? Icons.login : Icons.refresh),
                            label: Text(state.playerId == null ? 'Join lobby' : 'Reconnect'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Text('Player ID: ${state.playerId ?? '-'}')),
                          if (state.playerId != null)
                            TextButton.icon(
                              onPressed: controller.leaveLobby,
                              icon: const Icon(Icons.logout),
                              label: const Text('Leave'),
                            ),
                        ],
                      ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
                if (game != null)
                _Card(
                  title: 'Table',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 12, runSpacing: 8, children: [
                        _Pill('Phase: ${game.phase.name}'),
                        _Pill('Round ${game.currentRoundIdx + 1}/${game.rounds.length}'),
                        _Pill('Trump: ${currentRound?.trump ?? '-'}'),
                        if (game.currentTurnPlayerId != null)
                          _Pill('Turn: ${game.players.firstWhere((p) => p.id == game.currentTurnPlayerId, orElse: () => me!).name}')
                        else
                          _Pill('Waiting for bids'),
                        if (_scoringSummary(game.settings).isNotEmpty)
                          _Pill('Scoring: ${_scoringSummary(game.settings)}'),
                      ]),
                      const SizedBox(height: 12),
                      _PlayersList(
                        players: game.players,
                        meId: state.playerId,
                        isHost: game.hostId == state.playerId,
                        onKick: game.hostId == state.playerId ? controller.kickPlayer : null,
                      ),
                    ],
                  ),
                ),
                if (game != null && state.playerId != null)
                  _PhasePanel(
                    wide: wide,
                    game: game,
                    currentRound: currentRound,
                    me: me,
                    controller: controller,
                    startingCardsCtrl: startingCardsCtrl,
                    roundStyle: roundStyle,
                    lenient: lenient,
                    preset: preset,
                    applyPreset: applyPreset,
                    successCtrl: successCtrl,
                    penaltyCtrl: penaltyCtrl,
                    bonusCtrl: bonusCtrl,
                    bidCtrl: bidCtrl,
                    actualCtrl: actualCtrl,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PhasePanel extends StatelessWidget {
  const _PhasePanel({
    required this.wide,
    required this.game,
    required this.currentRound,
    required this.me,
    required this.controller,
    required this.startingCardsCtrl,
    required this.roundStyle,
    required this.lenient,
    required this.preset,
    required this.applyPreset,
    required this.successCtrl,
    required this.penaltyCtrl,
    required this.bonusCtrl,
    required this.bidCtrl,
    required this.actualCtrl,
  });

  final bool wide;
  final GameStateData game;
  final RoundState? currentRound;
  final Player? me;
  final GameController controller;
  final TextEditingController startingCardsCtrl;
  final ValueNotifier<String> roundStyle;
  final ValueNotifier<bool> lenient;
  final ValueNotifier<String> preset;
  final void Function(String) applyPreset;
  final TextEditingController successCtrl;
  final TextEditingController penaltyCtrl;
  final TextEditingController bonusCtrl;
  final TextEditingController bidCtrl;
  final TextEditingController actualCtrl;

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (game.phase) {
      case GamePhase.lobby:
        content = _Lobby(
          host: game.hostId == me?.id,
          controller: controller,
          startingCardsCtrl: startingCardsCtrl,
          roundStyle: roundStyle,
          lenient: lenient,
          preset: preset,
          applyPreset: applyPreset,
          successCtrl: successCtrl,
          penaltyCtrl: penaltyCtrl,
          bonusCtrl: bonusCtrl,
          onRefresh: controller.refreshState,
        );
        break;
      case GamePhase.bidding:
        content = _Bidding(currentRound: currentRound, bidCtrl: bidCtrl, controller: controller, hasBid: currentRound?.bids.containsKey(me?.id) ?? false);
        break;
      case GamePhase.playing:
        content = _Playing(game: game, me: me, controller: controller);
        break;
      case GamePhase.leaderboard:
        content = _Leaderboard(controller: controller, host: game.hostId == me?.id, round: currentRound);
        break;
      case GamePhase.finished:
        content = const Text('Game finished. Restart from server to play again.');
        break;
    }

    return _Card(title: 'Actions', child: content);
  }
}

class _Lobby extends StatelessWidget {
  const _Lobby({
    required this.host,
    required this.controller,
    required this.startingCardsCtrl,
    required this.roundStyle,
    required this.lenient,
    required this.preset,
    required this.applyPreset,
    required this.successCtrl,
    required this.penaltyCtrl,
    required this.bonusCtrl,
    required this.onRefresh,
  });

  final bool host;
  final GameController controller;
  final TextEditingController startingCardsCtrl;
  final ValueNotifier<String> roundStyle;
  final ValueNotifier<bool> lenient;
  final ValueNotifier<String> preset;
  final void Function(String) applyPreset;
  final TextEditingController successCtrl;
  final TextEditingController penaltyCtrl;
  final TextEditingController bonusCtrl;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!host) {
      return const Text('Waiting for host to start the game...');
    }
    final isCustom = preset.value == 'custom';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: startingCardsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Starting cards per player'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: roundStyle.value,
                decoration: const InputDecoration(labelText: 'Round style'),
                items: const [
                  DropdownMenuItem(value: 'countdown', child: Text('Countdown (10→1)')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed count each round')),
                ],
                onChanged: (v) => roundStyle.value = v ?? 'countdown',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: preset.value,
          decoration: const InputDecoration(labelText: 'Scoring preset'),
          items: const [
            DropdownMenuItem(value: 'standard', child: Text('Standard: 30/-30, +1 over')),
            DropdownMenuItem(value: 'strict', child: Text('Strict: 30/-30, over = -30')),
            DropdownMenuItem(value: 'custom', child: Text('Custom')),
          ],
          onChanged: (v) {
            if (v != null) applyPreset(v);
          },
        ),
        if (isCustom) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: successCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Points per bid trick'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: penaltyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Penalty per missed trick'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: bonusCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bonus per overtrick'),
                ),
              ),
            ],
          ),
        ],
        SwitchListTile(
          title: const Text('Lenient overtricks'),
          subtitle: const Text('If off, going over your bid is penalized like missing.'),
          value: lenient.value,
          onChanged: (v) {
            lenient.value = v;
            if (preset.value != 'custom') applyPreset('custom');
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final settings = SettingsPayload(
                    startingCards: int.tryParse(startingCardsCtrl.text) ?? 10,
                    roundStyle: roundStyle.value,
                    lenientOvertrick: lenient.value,
                    mode: 'virtual',
                    successMultiplier: int.tryParse(successCtrl.text) ?? 10,
                    penaltyMultiplier: int.tryParse(penaltyCtrl.text) ?? 10,
                    overtrickBonus: int.tryParse(bonusCtrl.text) ?? 1,
                  );
                  controller.startGame(settings);
                },
                child: const Text('Start game'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: controller.resetLobby,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset lobby'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.sync),
              label: const Text('Sync state'),
            ),
          ],
        )
      ],
    );
  }
}

class _Bidding extends StatelessWidget {
  const _Bidding({
    required this.currentRound,
    required this.bidCtrl,
    required this.controller,
    required this.hasBid,
  });

  final RoundState? currentRound;
  final TextEditingController bidCtrl;
  final GameController controller;
  final bool hasBid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cards: ${currentRound?.cards ?? '-'} | Trump: ${currentRound?.trump ?? '-'}'),
        const SizedBox(height: 8),
        TextField(
          controller: bidCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Your bid'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: hasBid
              ? null
              : () {
                  final bid = int.tryParse(bidCtrl.text) ?? 0;
                  controller.submitBid(bid);
                },
          child: Text(hasBid ? 'Bid submitted' : 'Submit bid'),
        ),
      ],
    );
  }
}

class _Playing extends ConsumerWidget {
  const _Playing({required this.game, required this.me, required this.controller});
  final GameStateData game;
  final Player? me;
  final GameController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(gameControllerProvider);
    final handCards = view.hand?.hand ?? [];
    final isMyTurn = game.currentTurnPlayerId == me?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, children: [
          _Pill(isMyTurn ? 'Your turn' : 'Waiting'),
          _Pill('Trick ${game.trickNumber}')
        ]),
        const SizedBox(height: 8),
        if (handCards.isEmpty)
          const Text('Waiting for your hand...', style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: handCards
                .map(
                  (card) => ChoiceChip(
                    label: Text(card),
                    selected: false,
                    onSelected: isMyTurn ? (_) => controller.playCard(card) : null,
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 12),
        Text('Current trick:'),
        if (game.currentTrick.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('No cards played yet', style: TextStyle(color: Colors.grey)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: game.currentTrick
                .map(
                  (t) => Chip(
                    label: Text('${_nameFor(game, t.playerId)} • ${t.card}'),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  String _nameFor(GameStateData game, String id) {
    return game.players.firstWhere((p) => p.id == id, orElse: () => Player(id: id, name: 'P$id', role: 'player', totalScore: 0, roundChange: 0)).name;
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.controller, required this.host, required this.round});
  final GameController controller;
  final bool host;
  final RoundState? round;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Round bids: ${round?.bids ?? {}}'),
        Text('Actuals: ${round?.actuals ?? {}}'),
        const SizedBox(height: 8),
        if (host)
          ElevatedButton(
            onPressed: controller.nextRound,
            child: const Text('Next round'),
          )
        else
          const Text('Waiting for host to start next round...'),
      ],
    );
  }
}

class _PlayersList extends StatelessWidget {
  const _PlayersList({required this.players, required this.meId, this.onKick, this.isHost = false});
  final List<Player> players;
  final String? meId;
  final void Function(String playerId)? onKick;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Players'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: players
              .map(
                (p) => Chip(
                  avatar: meId == p.id ? const Icon(Icons.person, size: 18) : null,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${p.name} • ${p.totalScore} (${p.roundChange >= 0 ? '+' : ''}${p.roundChange})'),
                      if (isHost && onKick != null && meId != p.id) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => onKick!(p.id),
                          child: const Icon(Icons.close, size: 16),
                        )
                      ]
                    ],
                  ),
                  backgroundColor: meId == p.id ? Colors.blue.shade50 : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              child,
            ],
          ),
      ),
    );
  }
}

String _scoringSummary(Map<String, dynamic> settings) {
  final success = settings['successMultiplier'] ?? settings['success'] ?? 10;
  final penalty = settings['penaltyMultiplier'] ?? settings['penalty'] ?? 10;
  final bonus = settings['overtrickBonus'] ?? settings['bonus'] ?? 1;
  final lenient = settings['lenientOvertrick'] ?? true;
  if (lenient == true) return '$success / -$penalty, +$bonus over';
  return '$success / -$penalty, over = -$penalty';
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text),
    );
  }
}
