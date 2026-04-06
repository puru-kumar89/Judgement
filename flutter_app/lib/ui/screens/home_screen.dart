import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../../state/game_state.dart';
import '../widgets/animated_background.dart';
import 'setup_screen.dart';
import 'bidding_screen.dart';
import 'results_screen.dart';
import 'leaderboard_screen.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(gameProvider.select((state) => state.phase));

    Widget currentScreen;
    switch (phase) {
      case GamePhase.setup:
        currentScreen = const SetupScreen(key: ValueKey('setup'));
        break;
      case GamePhase.bidding:
        currentScreen = const BiddingScreen(key: ValueKey('bidding'));
        break;
      case GamePhase.results:
        currentScreen = const ResultsScreen(key: ValueKey('results'));
        break;
      case GamePhase.leaderboard:
      case GamePhase.finished:
        currentScreen = const LeaderboardScreen(key: ValueKey('leaderboard'));
        break;
    }

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                        color: Colors.white,
                      ),
                      children: [
                        const TextSpan(text: 'Ka'),
                        TextSpan(
                          text: 'at',
                          style: TextStyle(color: AppTheme.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: currentScreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
