import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stepper_input.dart';
import '../../theme/theme_provider.dart';
import '../widgets/player_avatar.dart';
import '../widgets/primary_button.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final currentRound = state.rounds[state.currentRoundIdx];
    final theme = ref.watch(themeProvider);

    int totalActuals = 0;
    for (var p in state.players) {
      totalActuals += currentRound.actuals[p.id] ?? 0;
    }
    bool isValid = totalActuals == currentRound.cards;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryCard(
            title: 'RESULTS',
            heroValue: 'Rnd ${state.currentRoundIdx + 1}',
            badgeWidget: Transform.scale(
              scale: 1.15,
              child: SummaryCard.buildTrumpBadge(currentRound.trump),
            ),
            background: LinearGradient(
              colors: [
                const Color(0xFF2A2C33),
                const Color(0xFF1D1F26),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            bottomContent: Row(
              children: [
                Icon(isValid ? Icons.check_circle : Icons.error_outline, 
                    color: isValid ? theme.success : theme.danger, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$totalActuals / ${currentRound.cards} Tricks',
                  style: TextStyle(color: isValid ? theme.success : theme.danger, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Text('ACTUAL TRICKS WON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.textMuted, letterSpacing: 1.4)),
          const SizedBox(height: 10),
          
          ...state.players.map((p) {
            int bid = currentRound.bids[p.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PremiumRowCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                backgroundColor: theme.isDark ? theme.surfaceCard : Colors.white,
                borderColor: theme.borderCard,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: theme.textMain)),
                            Text('Bid: $bid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    StepperInput(
                      value: currentRound.actuals[p.id] ?? 0,
                      max: currentRound.cards,
                      compact: true,
                      lightStyle: true,
                      onChanged: (val) => notifier.setActual(p.id, val),
                    ),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Calculate Scores',
            icon: Icons.calculate,
            onPressed: isValid ? () => notifier.calculateScores() : null,
          ),
        ],
      ),
    );
  }
}
