import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stepper_input.dart';
import '../../theme/theme_provider.dart';
import '../widgets/player_avatar.dart';
import '../widgets/primary_button.dart';

class BiddingScreen extends ConsumerWidget {
  const BiddingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final currentRound = state.rounds[state.currentRoundIdx];
    final theme = ref.watch(themeProvider);
    final positions = ['Sitting South', 'Sitting West', 'Sitting North', 'Sitting East'];

    int totalBids = 0;
    for (var p in state.players) {
      totalBids += currentRound.bids[p.id] ?? 0;
    }
    bool isHook = totalBids == currentRound.cards;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryCard(
            title: 'BIDDING',
            heroValue: 'Rnd ${state.currentRoundIdx + 1}',
            badgeWidget: SummaryCard.buildTrumpBadge(currentRound.trump),
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
                Icon(Icons.style, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${currentRound.cards} CARDS DEALT',
                  style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
            
          const SizedBox(height: 24),
          Text('ENTER BIDS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.textMuted, letterSpacing: 1.4)),
          const SizedBox(height: 10),
          
          ...state.players.asMap().entries.map((entry) {
            int idx = entry.key;
            var p = entry.value;
            bool isDealer = idx == state.players.length - 1;
            
            return Padding(
              key: ValueKey(p.id),
              padding: const EdgeInsets.only(bottom: 10),
              child: PremiumRowCard(
                isActive: isDealer,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                backgroundColor: theme.isDark ? theme.surfaceCard : Colors.white,
                borderColor: isDealer ? theme.accent.withValues(alpha: 0.4) : theme.borderCard,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: theme.textMain)),
                        Text(
                          positions[idx % positions.length],
                          style: TextStyle(fontSize: 12, color: theme.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    StepperInput(
                      value: currentRound.bids[p.id] ?? 0,
                      max: currentRound.cards,
                      compact: true,
                      onChanged: (val) => notifier.setBid(p.id, val),
                    ),
                  ],
                ),
              ),
            );
          }),
          
          if (isHook)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF650D1C),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.accent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: theme.accent.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hook Warning', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          'Sum of bids cannot equal ${currentRound.cards}. Dealer must adjust.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Start Playing',
            icon: Icons.play_arrow,
            onPressed: () => notifier.startPlaying(),
          ),
        ],
      ),
    );
  }
}
