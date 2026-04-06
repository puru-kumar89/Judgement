import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/theme_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StartIntro extends ConsumerStatefulWidget {
  final VoidCallback onFinished;
  const StartIntro({super.key, required this.onFinished});

  @override
  ConsumerState<StartIntro> createState() => _StartIntroState();
}

class _StartIntroState extends ConsumerState<StartIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Timer _nameTimer;
  int _nameIdx = 0;
  bool _visible = true;

  final _names = const [
    'Court Piece',
    'Kaat',
    'Judgement',
    'Rang',
    'Call Break',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _nameTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      setState(() => _nameIdx = (_nameIdx + 1) % _names.length);
    });

    // Auto hide after ~2.5s
    Future.delayed(const Duration(milliseconds: 2600), _finish);
  }

  void _finish() {
    if (!_visible) return;
    setState(() => _visible = false);
    widget.onFinished();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    if (!_visible) return const SizedBox.shrink();

    const suits = [
      {'icon': '♠', 'color': Colors.black},
      {'icon': '♥', 'color': Colors.red},
      {'icon': '♦', 'color': Colors.red},
      {'icon': '♣', 'color': Colors.black},
      {'icon': 'NT', 'color': Colors.amber},
    ];

    return GestureDetector(
      onTap: _finish,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surfaceCard.withValues(alpha: theme.isDark ? 0.9 : 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 60,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  final t = (_ctrl.value * pi);
                  final tilt = sin(t) * 0.35;
                  final scale = 0.9 + (sin(t).abs() * 0.1);
                  final suit = suits[(_ctrl.value * suits.length).floor() % suits.length];
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(tilt)
                      ..scale(scale),
                    child: Text(
                      suit['icon'] as String,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: suit['color'] as Color,
                        letterSpacing: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to the table',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _names[_nameIdx],
                      key: ValueKey(_nameIdx),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to skip',
                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
