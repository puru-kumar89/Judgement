import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/theme_provider.dart';

/// Startup flourish that mimics the stacked, motion-blurred name roll
/// from the provided reference clip. Very quick, non-blocking, tap-to-skip.
class StartIntroOverlay extends ConsumerStatefulWidget {
  final VoidCallback onFinished;

  const StartIntroOverlay({super.key, required this.onFinished});

  @override
  ConsumerState<StartIntroOverlay> createState() => _StartIntroOverlayState();
}

class _StartIntroOverlayState extends ConsumerState<StartIntroOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scrollCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _suitCtrl;
  bool _finished = false;

  final List<String> _nameVariants = const [
    'Kaat Judgement',
    'Court Piece',
    'Rang',
    'Coat Piece',
    'Jut Patti',
    'Call Break',
    'Hand of Fate',
  ];

  final List<_Suit> _suits = const [
    _Suit(icon: '♠', color: Color(0xFF1E2330)),
    _Suit(icon: '♥', color: Color(0xFFD00231)),
    _Suit(icon: '♣', color: Color(0xFF0C9A3E)),
    _Suit(icon: '♦', color: Color(0xFFE3123C)),
  ];

  @override
  void initState() {
    super.initState();

    _scrollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _suitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    // Auto finish slightly after scroll completes.
    Future.delayed(const Duration(milliseconds: 1400), _finish);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _fadeCtrl.forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _suitCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return const SizedBox.shrink();
    final theme = ref.watch(themeProvider);

    return Positioned.fill(
      child: FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.0).animate(_fadeCtrl),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: Container(
            color: theme.isDark
                ? Colors.black.withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.62),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Suits fan in the background for a split-second flip.
                AnimatedBuilder(
                  animation: _suitCtrl,
                  builder: (context, _) {
                    final t = _suitCtrl.value;
                    return Transform.rotate(
                      angle: sin(t * pi * 2) * 0.08,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_suits.length, (i) {
                          final delay = i * 0.08;
                          final localT = ((t - delay) * 1.2).clamp(0.0, 1.0);
                          final flip = Tween(begin: pi, end: 0.0).transform(localT);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0013)
                                ..rotateY(flip),
                              child: Opacity(
                                opacity: localT,
                                child: Text(
                                  _suits[i].icon,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: _suits[i].color,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),

                // Scrolling names with motion blur + perspective.
                AnimatedBuilder(
                  animation: _scrollCtrl,
                  builder: (context, _) {
                    final t = Curves.easeOut.transform(_scrollCtrl.value);
                    return _StackedNameRoll(
                      names: _nameVariants,
                      t: t,
                      color: theme.isDark ? Colors.white : const Color(0xFF0E1628),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Suit {
  final String icon;
  final Color color;
  const _Suit({required this.icon, required this.color});
}

class _StackedNameRoll extends StatelessWidget {
  final List<String> names;
  final double t; // 0-1 scroll progress
  final Color color;

  const _StackedNameRoll({
    required this.names,
    required this.t,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 48;
    const double blurMax = 10;

    // Start with list slightly below center and slide up.
    final double travel = spacing * (names.length - 1);
    final double baseOffset = lerpDouble(spacing * 1.5, -spacing * 0.3, t)!;

    return ClipRect(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateY(-0.18)
          ..setEntry(0, 1, -0.08) // skew Y -> X (approximate)
          ..scale(1.06, 1.02),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft gradient mask to fade top/bottom edges.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            ...List.generate(names.length, (i) {
              final dy = baseOffset + i * spacing - travel * t;
              final centerWeight = 1 - (dy.abs() / (spacing * 2)).clamp(0.0, 1.0);
              final sigma = blurMax * (0.6 + (1 - centerWeight)) * (1 - t * 0.6);
              final opacity = (0.25 + centerWeight * 0.75).clamp(0.0, 1.0);

              return Transform.translate(
                offset: Offset(0, dy),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaY: sigma, sigmaX: sigma * 0.3),
                  child: Text(
                    names[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: color.withValues(alpha: opacity),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
