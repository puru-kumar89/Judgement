import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';

/// Premium-feel startup flourish: 3D spinning suits and cycling names.
/// Auto-dismisses quickly and can be tapped to skip.
class StartIntroOverlay extends ConsumerStatefulWidget {
  final VoidCallback onFinished;

  const StartIntroOverlay({super.key, required this.onFinished});

  @override
  ConsumerState<StartIntroOverlay> createState() => _StartIntroOverlayState();
}

class _StartIntroOverlayState extends ConsumerState<StartIntroOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _spinEase;
  late final Timer _nameTimer;
  bool _finished = false;
  int _nameIdx = 0;

  final List<String> _nameVariants = const [
    'Court Piece',
    'Kaat',
    'Judgement',
    'Rang',
    'Call Break',
    'Oh Hell',
    'Hand of Fate',
  ];

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _spinEase = CurvedAnimation(parent: _spinCtrl, curve: Curves.easeInOut);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _nameTimer = Timer.periodic(const Duration(milliseconds: 620), (_) {
      if (mounted) setState(() => _nameIdx = (_nameIdx + 1) % _nameVariants.length);
    });

    // Auto finish after ~2.5s
    Future.delayed(const Duration(milliseconds: 2500), _finish);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _fadeCtrl.forward().whenComplete(() => widget.onFinished());
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _fadeCtrl.dispose();
    _nameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return const SizedBox.shrink();
    final theme = ref.watch(themeProvider);

    final suits = [
      _Suit(icon: '♠', color: Colors.black),
      _Suit(icon: '♥', color: const Color(0xFFD00231)),
      _Suit(icon: '♦', color: const Color(0xFFE3123C)),
      _Suit(icon: '♣', color: Colors.black),
    ];

    return Positioned.fill(
      child: FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.0).animate(_fadeCtrl),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
            child: Container(
            color: const Color(0xFF0B0B0C).withValues(alpha: 0.82),
              child: Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _spinEase,
                        builder: (context, _) {
                          final double turns = _spinEase.value * 2 * pi;
                          final idx = ((_spinEase.value * suits.length).floor()) % suits.length;
                          final suit = suits[idx];
                          final scale = 0.98 + (sin(turns).abs() * 0.04);
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0015)
                              ..rotateY(turns)
                              ..scale(scale),
                            child: Container(
                              width: 140,
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.surfaceCard,
                                    theme.surfaceCard.withValues(alpha: 0.8)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: theme.borderCard),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  suit.icon,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    color: suit.color,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 50,
                        child: _RollingNames(
                          names: _nameVariants,
                          progress: _spinEase.value,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRays(AppThemeData theme) {
    // Rays disabled per design feedback.
    return const [];
  }
}

class _Suit {
  final String icon;
  final Color color;
  const _Suit({required this.icon, required this.color});
}

class _RollingNames extends StatelessWidget {
  final List<String> names;
  final double progress; // 0-1 looping
  final Color color;

  const _RollingNames({
    required this.names,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final total = names.length;
    // Scroll bottom -> top smoothly.
    final speed = 0.45;
    final pos = (progress * speed * total);
    final base = pos.floor() % total;
    final frac = pos - pos.floor();

    List<Widget> items = [];
    for (int offset = -1; offset <= 1; offset++) {
      final idx = (base + offset + total) % total;
      final dy = (offset - frac) * 18;
      final opacity = offset == 0 ? 1.0 : 0.25;
      items.add(Transform.translate(
        offset: Offset(0, dy),
        child: Opacity(
          opacity: opacity,
          child: Text(
            names[idx],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: offset == 0 ? 16 : 14,
              fontWeight: offset == 0 ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ),
      ));
    }

    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: items,
      ),
    );
  }
}
