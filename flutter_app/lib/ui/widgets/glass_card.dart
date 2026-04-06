import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/theme_provider.dart';

// Top level header block (Dark background)
class SummaryCard extends ConsumerWidget {
  final String title;
  final String heroValue;
  final Widget badgeWidget;
  final Widget? bottomContent;
  final Gradient? background;
  final EdgeInsetsGeometry padding;
  final bool denseTop;

  const SummaryCard({
    super.key,
    required this.title,
    required this.heroValue,
    required this.badgeWidget,
    this.bottomContent,
    this.background,
    this.padding = const EdgeInsets.all(24),
    this.denseTop = false,
  });

  static Widget buildTrumpBadge(String trump) {
    Color trumpColor = Colors.white;
    if (trump == '♥️' || trump == '♦️') trumpColor = const Color(0xFFFF4B4B);
    else if (trump == '♠️' || trump == '♣️') trumpColor = const Color(0xFFE2E8F0);
    else if (trump == 'NT') trumpColor = const Color(0xFFFFD700);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: trump, style: TextStyle(color: trumpColor, fontSize: 22)),
          const TextSpan(text: ' Trump', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: background ??
            LinearGradient(
              colors: [
                theme.invertedCard,
                theme.invertedCard.withValues(alpha: theme.isDark ? 0.92 : 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.45 : 0.18),
            blurRadius: 50,
            spreadRadius: -12,
            offset: const Offset(0, 26),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!denseTop) ...[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                heroValue,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              if (bottomContent != null) ...[
                const SizedBox(height: 16),
                bottomContent!,
              ]
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: badgeWidget,
            ),
          )
        ],
      ),
    );
  }
}

// Crisp White/Frosted Rows for Player lines
class PremiumRowCard extends ConsumerWidget {
  final Widget child;
  final bool isActive;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const PremiumRowCard({
    super.key,
    required this.child,
    this.isActive = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.06 : 0.06),
            blurRadius: theme.isDark ? 18 : 24,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? theme.surfaceCard.withValues(alpha: theme.isDark ? 0.8 : 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor ?? (isActive ? theme.accent.withValues(alpha: 0.45) : theme.borderCard),
                width: isActive ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                if (isActive)
                  Container(
                    width: 4,
                    height: 48,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: theme.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
