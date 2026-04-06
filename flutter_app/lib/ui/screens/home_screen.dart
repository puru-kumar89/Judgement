import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../../state/game_state.dart';
import '../widgets/animated_background.dart';
import '../widgets/bottom_nav.dart';
import 'setup_screen.dart';
import 'bidding_screen.dart';
import 'results_screen.dart';
import 'leaderboard_screen.dart';
import 'podium_screen.dart';
import '../../theme/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(gameProvider.select((state) => state.phase));
    final theme = ref.watch(themeProvider);

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
        currentScreen = const LeaderboardScreen(key: ValueKey('leaderboard'));
        break;
      case GamePhase.finished:
        currentScreen = const PodiumScreen(key: ValueKey('podium'));
        break;
    }

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (phase == GamePhase.setup)
                      const SizedBox(width: 48)
                    else
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new, color: theme.textMain),
                        onPressed: () => ref.read(gameProvider.notifier).goBack(),
                      ),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                          color: theme.textMain,
                        ),
                        children: [
                          const TextSpan(text: 'Ka'),
                          TextSpan(
                            text: 'at',
                            style: TextStyle(color: theme.accent),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode, color: theme.textMuted),
                      onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: currentScreen,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: phase == GamePhase.setup
          ? null
          : BottomNav(
              active: switch (phase) {
                GamePhase.bidding => NavDestination.history,
                GamePhase.results => NavDestination.history,
                GamePhase.leaderboard => NavDestination.score,
                GamePhase.finished => NavDestination.score,
                GamePhase.setup => NavDestination.rules,
              },
            ),
    );
  }
}
