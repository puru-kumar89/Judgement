import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../state/game_provider.dart';
import '../../state/game_state.dart';
import '../widgets/animated_background.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/start_intro_overlay.dart';
import 'setup_screen.dart';
import 'bidding_screen.dart';
import 'results_screen.dart';
import 'leaderboard_screen.dart';
import 'podium_screen.dart';
import '../../theme/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    // Load saved preferences once.
    ref.read(gameProvider.notifier).init();

    // Auto-dismiss intro splash in case animation callback is missed.
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _showIntro) {
        setState(() => _showIntro = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

    final contentBlocked = _showIntro && phase == GamePhase.setup;

    return Scaffold(
      body: AnimatedBackground(
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: contentBlocked,
              child: AnimatedOpacity(
                opacity: contentBlocked ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
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
                            GestureDetector(
                              onTap: () {
                                final notifier = ref.read(gameProvider.notifier);
                                if (phase != GamePhase.setup) {
                                  notifier.navigateHome();
                                }
                              },
                              child: RichText(
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
            ),
            if (_showIntro && phase == GamePhase.setup)
              StartIntroOverlay(
                onFinished: () {
                  if (mounted) setState(() => _showIntro = false);
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }
}
