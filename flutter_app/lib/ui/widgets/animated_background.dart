import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/theme_provider.dart';

class AnimatedBackground extends ConsumerWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    final Gradient gradient = theme.isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1116),
              Color(0xFF0B0C11),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FBFF),
              Color(0xFFF2F6FB),
            ],
          );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          // Crimson orb (top-left)
          Positioned(
            top: -120,
            left: -120,
            child: _orb(theme.accent.withValues(alpha: 0.18), 360),
          ),
          // Teal/silver orb (bottom-right)
          Positioned(
            bottom: -140,
            right: -140,
            child: _orb(
              (theme.isDark ? Colors.white : theme.accent2).withValues(alpha: 0.12),
              460,
            ),
          ),
          // Secondary soft orb
          Positioned(
            top: 180,
            right: -80,
            child: _orb(Colors.black.withValues(alpha: 0.04), 240),
          ),
          child,
        ],
      ),
    );
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
