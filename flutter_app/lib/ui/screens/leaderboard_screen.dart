import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../../state/game_state.dart';
import '../../theme/theme_provider.dart';
import '../widgets/primary_button.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final theme = ref.watch(themeProvider);
    
    final sortedPlayers = List.of(state.players)..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final isFinished = state.phase == GamePhase.finished;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isFinished ? 'FINAL SCORES' : 'LEADERBOARD',
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFinished ? 'Game Over' : 'Round ${state.currentRoundIdx + 1} Complete',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.textMuted),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 420,
            child: Stack(
              clipBehavior: Clip.none,
              children: sortedPlayers.asMap().entries.map((entry) {
                int index = entry.key;
                var p = entry.value;
                bool isFirst = index == 0;

                double topOffset = index * 85.0;
                double scale = 1.0 - (index * 0.05);
                double opacity = 1.0 - (index * 0.06);
                if (scale < 0.82) scale = 0.82;
                if (opacity < 0.55) opacity = 0.55;
                
                Color changeColor = p.roundChange > 0 ? theme.success : (p.roundChange < 0 ? theme.danger : theme.textMuted);
                String sign = p.roundChange > 0 ? '+' : '';

                return Positioned(
                  top: topOffset,
                  left: 0,
                  right: 0,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        height: 118,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                        decoration: BoxDecoration(
                          color: theme.surfaceCard,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: theme.borderCard),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: theme.isDark ? 0.2 : 0.1),
                              blurRadius: 30,
                              spreadRadius: -5,
                              offset: const Offset(0, 18),
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 34,
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isFirst ? theme.accent : theme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$sign${p.roundChange} this round',
                                    style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${p.totalScore}',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: theme.invertedCard,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 28),
          if (!isFinished) ...[
            PrimaryButton(
              label: 'Next Round',
              onPressed: () => notifier.nextRound(),
            ),
            if (state.roundStyle == 'constant')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () => notifier.forceEndGame(),
                  child: Text('End Game Early', style: TextStyle(color: theme.danger, fontWeight: FontWeight.bold)),
                ),
              ),
          ] else ...[
            PrimaryButton(
              label: 'New Game',
              onPressed: () => notifier.restartGame(),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
