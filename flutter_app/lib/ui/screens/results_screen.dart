import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stepper_input.dart';
import '../../theme/theme_provider.dart';
import '../widgets/player_avatar.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final _scroll = ScrollController();
  double _shrink = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final next = (_scroll.offset / 80).clamp(0, 1).toDouble();
      if (next != _shrink) setState(() => _shrink = next);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final currentRound = state.rounds[state.currentRoundIdx];
    final theme = ref.watch(themeProvider);

    int totalActuals = 0;
    for (var p in state.players) {
      totalActuals += currentRound.actuals[p.id] ?? 0;
    }
    bool isValid = totalActuals == currentRound.cards;

    final tileScale = 1 - (_shrink * 0.18);
    final tilePadding = EdgeInsets.only(bottom: 16 - (_shrink * 8));

    return SingleChildScrollView(
      controller: _scroll,
      padding: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: tilePadding,
            child: Transform.scale(
              scale: tileScale,
              alignment: Alignment.topCenter,
              child: SummaryCard(
                title: 'RESULTS',
                heroValue: 'Rnd ${state.currentRoundIdx + 1}',
                badgeWidget: SummaryCard.buildTrumpBadge(currentRound.trump),
                background: const LinearGradient(
                  colors: [Color(0xFF25262b), Color(0xFF16171c)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                bottomContent: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Dealer: ${state.players.isNotEmpty && state.players.first.name.isNotEmpty ? state.players.first.name : 'Player 1'}',
                        style: TextStyle(color: theme.accent, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          Text('TRICKS WON THIS ROUND', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.textMuted, letterSpacing: 1.4)),
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
                            Text(p.name.isEmpty ? 'Player ${state.players.indexOf(p) + 1}' : p.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: theme.textMain)),
                            Text('Bid: $bid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    StepperInput(
                      value: currentRound.actuals[p.id] ?? 0,
                      max: currentRound.cards - (totalActuals - (currentRound.actuals[p.id] ?? 0)),
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
