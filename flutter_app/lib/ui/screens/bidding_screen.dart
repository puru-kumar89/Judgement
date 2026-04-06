import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stepper_input.dart';
import '../../theme/app_theme.dart';

class BiddingScreen extends ConsumerWidget {
  const BiddingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final currentRound = state.rounds[state.currentRoundIdx];

    int totalBids = 0;
    for (var p in state.players) {
      totalBids += currentRound.bids[p.id] ?? 0;
    }
    bool isHook = totalBids == currentRound.cards;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Round ${state.currentRoundIdx + 1}',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBox('Cards', currentRound.cards.toString()),
              const SizedBox(width: 16),
              _StatBox('Trump', currentRound.trump, isPremium: true),
            ],
          ),
          const SizedBox(height: 24),
          if (isHook)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hook: Dealer cannot bid ${currentRound.cards - (totalBids - (currentRound.bids[state.players.last.id] ?? 0))}',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter Bids', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...state.players.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var p = entry.value;
                  bool isDealer = idx == state.players.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${p.name}${isDealer ? " (Dealer)" : ""}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        StepperInput(
                          value: currentRound.bids[p.id] ?? 0,
                          max: currentRound.cards,
                          onChanged: (val) => notifier.setBid(p.id, val),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => notifier.startPlaying(),
            child: const Text('Start Playing'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isPremium;

  const _StatBox(this.label, this.value, {this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPremium ? AppTheme.accent.withOpacity(0.5) : AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: AppTheme.accent, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Space Grotesk')),
        ],
      ),
    );
  }
}
