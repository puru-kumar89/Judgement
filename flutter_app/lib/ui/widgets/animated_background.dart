import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../state/game_provider.dart';
import 'art_deco_pattern.dart';

class AnimatedBackground extends ConsumerWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final phase = ref.watch(gameProvider.select((s) => s.phase));

    final Gradient gradient = theme.isPremium
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF0C0C0C),
            ],
          )
        : theme.isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF13151B),
                  Color(0xFF0F1014),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF9F9FB),
                ],
              );

    // Visibility settings for the Art Deco pattern
    final bool showPattern = theme.isPremium || !theme.isDark;
    final double patternOpacity = theme.isPremium ? 0.12 : 0.07;
    final Color patternColor = theme.accent;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          _buildBackgroundElements(theme),
          if (showPattern)
            ArtDecoPattern(
              color: patternColor, 
              opacity: patternOpacity,
              transitionKey: ValueKey(phase), // Trigger animation on phase change
            ),
          child,
        ],
      ),
    );
  }

  Widget _buildBackgroundElements(AppThemeData theme) {
    if (theme.isPremium) {
      return Stack(
        children: [
            Positioned(top: -160, left: -160, child: _orb(theme.accent.withValues(alpha: 0.15), 480)),
            Positioned(bottom: -180, right: -180, child: _orb(theme.accent2.withValues(alpha: 0.10), 540)),
        ],
      );
    }
    if (theme.isDark) {
      return Stack(
        children: [
          Positioned(top: -140, left: -140, child: _orb(theme.accent.withValues(alpha: 0.20), 420)),
          Positioned(bottom: -120, right: -160, child: _orb(const Color(0xFF0C0D11).withValues(alpha: 0.30), 520)),
          Positioned(top: 160, right: -60, child: _orb(Colors.black.withValues(alpha: 0.20), 260)),
        ],
      );
    } else {
      return Stack(
        children: [
          Positioned(top: -120, left: -120, child: _orb(theme.accent.withValues(alpha: 0.18), 360)),
          Positioned(bottom: -140, right: -140, child: _orb(theme.accent2.withValues(alpha: 0.12), 460)),
          Positioned(top: 180, right: -80, child: _orb(Colors.black.withValues(alpha: 0.04), 240)),
        ],
      );
    }
  }

  Widget _orb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
