import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../../state/game_state.dart';
import '../widgets/glass_card.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    // Sort players by score
    final sortedPlayers = List.of(state.players)..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final isFinished = state.phase == GamePhase.finished;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isFinished ? 'Final Scores' : 'Round ${state.currentRoundIdx + 1} Scores',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...sortedPlayers.asMap().entries.map((entry) {
            int rank = entry.key + 1;
            var p = entry.value;
            bool isFirst = rank == 1;

            Color changeColor = p.roundChange > 0 ? AppTheme.success : (p.roundChange < 0 ? AppTheme.danger : AppTheme.textMuted);
            String sign = p.roundChange > 0 ? '+' : '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                borderGradient: isFirst,
                child: Row(
                  children: [
                    Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isFirst ? Colors.amberAccent : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '$sign${p.roundChange} this round',
                            style: TextStyle(color: changeColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${p.totalScore}',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          if (!isFinished)
            ElevatedButton(
              onPressed: () => notifier.nextRound(),
              child: const Text('Next Round'),
            )
          else
            ElevatedButton(
              onPressed: () => notifier.restartGame(),
              child: const Text('New Game'),
            ),
        ],
      ),
    );
  }
}
