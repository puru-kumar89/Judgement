import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stepper_input.dart';
import '../../theme/theme_provider.dart';
import '../widgets/player_avatar.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive.dart';

class BiddingScreen extends ConsumerStatefulWidget {
  const BiddingScreen({super.key});

  @override
  ConsumerState<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends ConsumerState<BiddingScreen> {
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

    int totalBids = 0;
    for (var p in state.players) {
      totalBids += currentRound.bids[p.id] ?? 0;
    }
    bool isHook = totalBids == currentRound.cards;

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
                title: 'BIDDING',
                heroValue: 'Rnd ${state.currentRoundIdx + 1}',
                badgeWidget: SummaryCard.buildTrumpBadge(currentRound.trump),
                background: const LinearGradient(
                  colors: [Color(0xFF1d222c), Color(0xFF13161d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                bottomContent: Row(
                  children: [
                    Icon(Icons.style, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${currentRound.cards} CARDS DEALT',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_outlined, size: 16, color: theme.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Dealer: ${state.players.isNotEmpty && state.players.first.name.isNotEmpty ? state.players.first.name : 'Player 1'}',
                    style: TextStyle(color: theme.accent, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Live bid counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ENTER BIDS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.textMuted, letterSpacing: 1.4)),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isHook
                      ? theme.danger.withValues(alpha: 0.15)
                      : (totalBids == currentRound.cards
                          ? theme.success.withValues(alpha: 0.15)
                          : theme.accent.withValues(alpha: 0.10)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHook
                        ? theme.danger.withValues(alpha: 0.5)
                        : (totalBids > 0
                            ? theme.accent.withValues(alpha: 0.35)
                            : theme.borderCard),
                  ),
                ),
                child: Text(
                  'Total bids: $totalBids',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isHook ? theme.danger : theme.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          ...state.players.asMap().entries.map((entry) {
            int idx = entry.key;
            var p = entry.value;
            bool isDealer = idx == 0;
            
            return Padding(
              key: ValueKey(p.id),
              padding: const EdgeInsets.only(bottom: 10),
              child: PremiumRowCard(
                isActive: isDealer,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                backgroundColor: isDealer && isHook
                    ? theme.danger.withValues(alpha: 0.08)
                    : (theme.isDark ? theme.surfaceCard : Colors.white),
                borderColor: isDealer && isHook
                    ? theme.danger.withValues(alpha: 0.5)
                    : (isDealer ? theme.accent.withValues(alpha: 0.4) : theme.borderCard),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name.isEmpty ? 'Player ${idx + 1}' : p.name,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: theme.textMain),
                        ),
                        if (isDealer)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('DEALER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.accent)),
                          ),
                      ],
                    ),
                    StepperInput(
                      value: currentRound.bids[p.id] ?? 0,
                      max: currentRound.cards,
                      compact: true,
                      lightStyle: true,
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
