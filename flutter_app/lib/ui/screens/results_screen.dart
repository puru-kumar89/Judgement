import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stepper_input.dart';
import '../../theme/app_theme.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final currentRound = state.rounds[state.currentRoundIdx];

    int totalActuals = 0;
    for (var p in state.players) {
      totalActuals += currentRound.actuals[p.id] ?? 0;
    }
    bool isValid = totalActuals == currentRound.cards;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Round ${state.currentRoundIdx + 1} Results',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isValid ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$totalActuals / ${currentRound.cards} Tricks Accounted',
              style: TextStyle(
                color: isValid ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actual Tricks Won', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...state.players.map((p) {
                  int bid = currentRound.bids[p.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text('Bid: $bid', style: const TextStyle(fontSize: 12, color: AppTheme.accent)),
                          ],
                        ),
                        StepperInput(
                          value: currentRound.actuals[p.id] ?? 0,
                          max: currentRound.cards,
                          onChanged: (val) => notifier.setActual(p.id, val),
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
            onPressed: isValid ? () => notifier.calculateScores() : null,
            child: const Text('Calculate Scores'),
          ),
        ],
      ),
    );
  }
}
