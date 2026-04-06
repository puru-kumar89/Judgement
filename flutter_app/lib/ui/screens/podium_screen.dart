import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../state/game_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/player.dart';
import '../widgets/primary_button.dart';
import '../../models/round.dart';
import '../widgets/responsive.dart';

class PodiumScreen extends ConsumerStatefulWidget {
  const PodiumScreen({super.key});

  @override
  ConsumerState<PodiumScreen> createState() => _PodiumScreenState();
}

class _PodiumScreenState extends ConsumerState<PodiumScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 10));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final theme = ref.watch(themeProvider);
    final notifier = ref.read(gameProvider.notifier);

    // Get strictly sorted players
    final sortedPlayers = List<Player>.from(state.players)..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    
    final Player first = sortedPlayers.isNotEmpty ? sortedPlayers[0] : Player(id: '', name: '?');
    final Player? second = sortedPlayers.length > 1 ? sortedPlayers[1] : null;
    final Player? third = sortedPlayers.length > 2 ? sortedPlayers[2] : null;
    final rest = sortedPlayers.length > 3 ? sortedPlayers.sublist(3) : <Player>[];

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'FINAL SCORES',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: titleSize(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  color: theme.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Game Over!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.textMuted),
              ),
              const SizedBox(height: 24),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (second != null)
                    _PodiumCard(
                      player: second,
                      rank: 2,
                      height: 140,
                      borderColor: const Color(0xFFC0C0C0),
                      theme: theme,
                    ),
                  _PodiumCard(
                    player: first,
                    rank: 1,
                    height: 190,
                    borderColor: const Color(0xFFFFD700),
                    theme: theme,
                    highlight: true,
                  ),
                  if (third != null)
                    _PodiumCard(
                      player: third,
                      rank: 3,
                      height: 110,
                      borderColor: const Color(0xFFCD7F32),
                      theme: theme,
                    ),
                ],
              ),

              if (rest.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Other ranks', style: TextStyle(fontWeight: FontWeight.w800, color: theme.textMain)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: theme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.borderCard),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rest.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: theme.borderCard),
                    itemBuilder: (_, idx) {
                      final player = rest[idx];
                      final rank = idx + 4;
                      return ListTile(
                        dense: true,
                        leading: Text('#$rank', style: TextStyle(fontWeight: FontWeight.w800, color: theme.textMuted)),
                        title: Text(player.name, style: TextStyle(fontWeight: FontWeight.w800, color: theme.textMain)),
                        trailing: Text(
                          '${player.totalScore}',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: theme.textMain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'New Game',
                onPressed: () => notifier.restartGame(),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _showAnalysis(context, sortedPlayers, state.rounds, theme),
                  child: Text(
                    'View Match Analysis',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),

        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final Player player;
  final int rank;
  final double height;
  final Color borderColor;
  final AppThemeData theme;
  final bool highlight;

  const _PodiumCard({
    required this.player,
    required this.rank,
    required this.height,
    required this.borderColor,
    required this.theme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: highlight ? 18 : 16,
              fontWeight: FontWeight.w900,
              color: theme.textMain,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.surfaceCard.withValues(alpha: theme.isDark ? 0.8 : 0.92),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.22),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              children: [
                Text(
                  rank == 1
                      ? 'WINNER'
                      : (rank == 2 ? '2ND' : '3RD'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${player.totalScore}',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: highlight ? 26 : 22,
                    fontWeight: FontWeight.w900,
                    color: borderColor,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

void _showAnalysis(BuildContext context, List<Player> players, List<GameRound> rounds, AppThemeData theme) {
  showModalBottomSheet(
    context: context,
    backgroundColor: theme.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final stats = players.map((p) {
        int successes = 0;
        int totalTricks = 0;
        int roundsPlayed = 0;

        for (final r in rounds) {
          if (r.actuals.containsKey(p.id)) {
            totalTricks += r.actuals[p.id] ?? 0;
            roundsPlayed++;
          }
          if (r.actuals[p.id] != null && r.bids[p.id] != null && r.actuals[p.id] == r.bids[p.id]) {
            successes++;
          }
        }

        final successRate = roundsPlayed == 0 ? 0 : ((successes / roundsPlayed) * 100).round();

        return {
          'player': p,
          'successes': successes,
          'rounds': roundsPlayed,
          'tricks': totalTricks,
          'successRate': successRate,
        };
      }).toList();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                width: 60,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.borderCard,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text('Match Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.textMain)),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: theme.borderCard),
                itemBuilder: (_, idx) {
                  final data = stats[idx];
                  final player = data['player'] as Player;
                  return ListTile(
                    dense: true,
                    title: Text(player.name, style: TextStyle(fontWeight: FontWeight.w800, color: theme.textMain)),
                    subtitle: Text(
                      '${data['successes']} accurate bids • ${data['tricks']} tricks • ${data['successRate']}% accuracy',
                      style: TextStyle(color: theme.textMuted),
                    ),
                    trailing: Text(
                      '${player.totalScore}',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: theme.textMain,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
