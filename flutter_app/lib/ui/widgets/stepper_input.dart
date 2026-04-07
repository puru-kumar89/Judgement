import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/theme_provider.dart';

class StepperInput extends ConsumerWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool compact;
  final bool lightStyle;

  const StepperInput({
    super.key,
    required this.value,
    this.min = 0,
    required this.max,
    required this.onChanged,
    this.compact = false,
    this.lightStyle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final bool light = lightStyle && !theme.isDark;
    
    return Container(
      decoration: BoxDecoration(
        color: light
            ? const Color(0xFFF7F5F5)
            : (theme.isDark ? const Color(0xFF12151C) : const Color(0xFFF5F6F8)),
        borderRadius: BorderRadius.circular(999), // Pill shape
        border: Border.all(
          color: light ? Colors.transparent : (theme.isDark ? Colors.transparent : const Color(0xFFE4E6EC)),
        ),
        boxShadow: light
            ? [
                BoxShadow(
                  color: const Color(0xFFE0C8C8).withValues(alpha: 0.32),
                  blurRadius: 26,
                  spreadRadius: -6,
                  offset: const Offset(0, 14),
                )
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 2 : 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: value > min ? () => onChanged(value - 1) : null,
            compact: compact,
            light: light,
          ),
          Container(
            width: compact ? 38 : 50,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w900,
                color: light ? Colors.black : theme.textMain,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: value < max ? () => onChanged(value + 1) : null,
            compact: compact,
            light: light,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends ConsumerWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;
  final bool light;

  const _StepperButton({required this.icon, this.onTap, this.compact = false, this.light = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
          child: Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: enabled
                ? (light ? Colors.white : (theme.isDark ? theme.surfaceCard : Colors.white))
                : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: enabled ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: light ? 0.06 : (theme.isDark ? 0.4 : 0.06)),
                blurRadius: 14,
                offset: const Offset(0, 6),
              )
            ] : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? theme.accent
                : theme.textMuted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
