import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/theme_provider.dart';

class StepperInput extends ConsumerWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool compact;

  const StepperInput({
    super.key,
    required this.value,
    this.min = 0,
    required this.max,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF0F1218) : Colors.white,
        borderRadius: BorderRadius.circular(999), // Pill shape
        border: Border.all(color: theme.isDark ? theme.borderCard : theme.borderCard),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 2 : 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: value > min ? () => onChanged(value - 1) : null,
            compact: compact,
          ),
          Container(
            width: compact ? 38 : 50,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w800,
                color: theme.textMain,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: value < max ? () => onChanged(value + 1) : null,
            compact: compact,
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

  const _StepperButton({required this.icon, this.onTap, this.compact = false});

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
            color: enabled ? (theme.isDark ? theme.surfaceCard : Colors.white) : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: enabled ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: theme.isDark ? 0.4 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 5),
              )
            ] : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? (theme.isDark ? Colors.white : theme.textMain) : theme.textMuted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
