import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/theme_provider.dart';

enum NavDestination { score, history, rules, profile }

class BottomNav extends ConsumerWidget {
  final NavDestination active;
  const BottomNav({super.key, required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceCard.withValues(alpha: theme.isDark ? 0.65 : 0.92),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(color: theme.borderCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.isDark ? 0.35 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: NavDestination.values.map((dest) {
          final bool selected = dest == active;
          final icon = switch (dest) {
            NavDestination.score => Icons.leaderboard,
            NavDestination.history => Icons.history,
            NavDestination.rules => Icons.menu_book,
            NavDestination.profile => Icons.person,
          };
          return _NavItem(
            icon: icon,
            label: dest.name,
            selected: selected,
            accent: theme.accent,
            textColor: theme.textMuted,
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final Color textColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
            border: selected ? null : Border.all(color: textColor.withValues(alpha: 0.25)),
          ),
          child: Icon(
            icon,
            color: selected ? Colors.white : textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: selected ? accent : textColor,
          ),
        )
      ],
    );
  }
}
