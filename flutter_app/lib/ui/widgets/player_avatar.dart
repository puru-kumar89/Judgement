import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/theme_provider.dart';

class PlayerAvatar extends ConsumerWidget {
  final String name;
  final double size;
  final bool solid;

  const PlayerAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final initials = _initials(name);
    final Color bg = solid ? theme.accent : theme.accent.withValues(alpha: 0.08);
    final Color fg = solid ? Colors.white : theme.accent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: theme.borderCard),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Space Grotesk',
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          color: fg,
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(' ');
    if (parts.length == 1) {
      return value.isNotEmpty ? value[0].toUpperCase() : '?';
    }
    return (parts[0].isNotEmpty ? parts[0][0] : '') + (parts[1].isNotEmpty ? parts[1][0] : '');
  }
}
