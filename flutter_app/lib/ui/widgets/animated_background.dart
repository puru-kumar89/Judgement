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
              Color(0xFF1B1E26),
              Color(0xFF161920),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7FAFD),
              Color(0xFFF2F6FA),
            ],
          );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          if (theme.isDark) ...[
            Positioned(top: -140, left: -140, child: _orb(theme.accent.withValues(alpha: 0.22), 420)),
            Positioned(bottom: -120, right: -160, child: _orb(const Color(0xFF0F3A3A).withValues(alpha: 0.25), 520)),
            Positioned(top: 160, right: -60, child: _orb(Colors.black.withValues(alpha: 0.18), 260)),
          ] else ...[
            Positioned(top: -120, left: -120, child: _orb(theme.accent.withValues(alpha: 0.18), 360)),
            Positioned(bottom: -140, right: -140, child: _orb((theme.isDark ? Colors.white : theme.accent2).withValues(alpha: 0.12), 460)),
            Positioned(top: 180, right: -80, child: _orb(Colors.black.withValues(alpha: 0.04), 240)),
          ],
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
