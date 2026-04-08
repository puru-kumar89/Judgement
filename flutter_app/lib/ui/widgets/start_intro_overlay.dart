import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// Conditional import for PWA detection
import 'dart:js' as js;
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'ios_install_assistant.dart';

/// Startup intro that features a spinning 3D card and a vertical name roll
/// that lands on the brand name "KAAT" with a cinematic, fluid transition.
enum SuitType { spade, heart, club, diamond }

class _Suit {
  final SuitType type;
  final Color color;
  const _Suit({required this.type, required this.color});
}

class StartIntroOverlay extends ConsumerStatefulWidget {
  final VoidCallback onFinished;

  const StartIntroOverlay({super.key, required this.onFinished});

  @override
  ConsumerState<StartIntroOverlay> createState() => _StartIntroOverlayState();
}

class _StartIntroOverlayState extends ConsumerState<StartIntroOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl; // Overall timeline (2 seconds)
  late final AnimationController _suitCtrl; // Spin loop
  late final AnimationController _fadeCtrl; // Final screen fade out
  bool _finished = false;
  bool _showAssistant = false;
  bool _isIOSUninstalled = false;

  final List<String> _nameVariants = const [
    'Kaat Judgement',
    'Court Piece',
    'Rang',
    'Coat Piece',
    'Jut Patti',
    'Call Break',
    'Hand of Fate',
    'Kaat',
  ];

  final List<_Suit> _suits = const [
    _Suit(type: SuitType.spade, color: Colors.white),
    _Suit(type: SuitType.heart, color: Color(0xFFC5A028)),
    _Suit(type: SuitType.club, color: Colors.white),
    _Suit(type: SuitType.diamond, color: Color(0xFFC5A028)),
  ];

  @override
  void initState() {
    super.initState();
    // Total duration for a premium, grounded feel.
    _mainCtrl = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 2400),
    )..forward();

    // Smart PWA detection
    try {
      final isios = js.context['isios'] ?? false;
      final isStandalone = js.context['isStandalone'] ?? false;
      _isIOSUninstalled = isios && !isStandalone;
    } catch (_) {
      _isIOSUninstalled = false;
    }

    _suitCtrl = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 700),
    )..repeat();

    _fadeCtrl = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 320),
    );

    // Coordination: wait for settle, then finish.
    _mainCtrl.addStatusListener((status) {
       if (status == AnimationStatus.completed) {
         if (!_isIOSUninstalled) {
           Future.delayed(const Duration(milliseconds: 250), _finish);
         }
       }
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    if (mounted) {
      _fadeCtrl.forward().whenComplete(widget.onFinished);
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
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
          onTap: () {
            if (!_isIOSUninstalled) _finish();
          },
          child: Container(
            color: Colors.black, // Dark cinematic backdrop
            child: AnimatedBuilder(
              animation: _mainCtrl,
              builder: (context, _) {
                final t = _mainCtrl.value;
                // Timeline: 
                // 0.0 to 0.70: Generic Name Roll + Spinning Card
                // 0.70 to 1.0: Outro (Card fades, KAAT moves in)
                
                final double outroStart = 0.70;
                final double outroT = ((t - outroStart) / (1.0 - outroStart)).clamp(0.0, 1.0);
                
                // Curve for translation/scaling (easeInOutCubic for professional fluidity)
                final double easeT = Curves.easeInOutCubic.transform(outroT);
                
                // Card fades out as outro starts.
                final cardOpacity = (1.0 - (outroT * 1.8)).clamp(0.0, 1.0);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Spinning card on top
                        Opacity(
                          opacity: cardOpacity,
                          child: AnimatedBuilder(
                            animation: _suitCtrl,
                            builder: (context, _) {
                              final double turns = _suitCtrl.value * 2 * pi;
                              final idx = ((_suitCtrl.value * _suits.length).floor()) % _suits.length;
                              final suit = _suits[idx];
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0014)
                                  ..rotateY(turns)
                                  ..scale(1.0),
                                child: _CardWidget(suit: suit, theme: theme),
                              );
                            },
                          ),
                        ),
                        
                        // We use a fixed Spacer to maintain consistent layout during the move.
                        const SizedBox(height: 38),

                        // The name roll (fades as landing starts)
                        _StackedNameRoll(
                          names: _nameVariants,
                          t: t,
                          outroT: easeT, // Use the ease-in-out curve
                          color: Colors.white,
                        ),
                      ],
                    ),

                    // iOS Install Assistant Overlay
                    if (_showAssistant)
                      IosInstallAssistant(
                        onDismiss: () => setState(() => _showAssistant = false),
                      ),

                    // Premium Install Button (only for uninstalled iOS users)
                    if (_isIOSUninstalled && !_showAssistant && outroT > 0.1)
                      Positioned(
                        bottom: 48 + (MediaQuery.of(context).padding.bottom),
                        child: FadeTransition(
                          opacity: Tween(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.1, 0.4)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () => setState(() => _showAssistant = true),
                                icon: const Icon(Icons.add_box_outlined, color: Color(0xFFC5A028)),
                                label: const Text(
                                  'INSTALL FOR BEST EXPERIENCE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _finish,
                                child: Text(
                                  'CONTINUE TO GAME',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final _Suit suit;
  final AppThemeData theme;

  const _CardWidget({required this.suit, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black, // Dark fill
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          radius: 1.2,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.03),
            blurRadius: 40,
            spreadRadius: 2,
          )
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(60, 60),
          painter: SuitPainter(
            type: suit.type,
            color: suit.color,
          ),
        ),
      ),
    );
  }
}

class SuitPainter extends CustomPainter {
  final SuitType type;
  final Color color;

  SuitPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    switch (type) {
      case SuitType.heart:
        path.moveTo(w * 0.5, h * 0.25);
        path.cubicTo(w * 0.5, h * 0.2, w * 0.25, h * 0, w * 0.05, h * 0.3);
        path.cubicTo(w * -0.15, h * 0.6, w * 0.5, h * 1, w * 0.5, h * 1);
        path.cubicTo(w * 0.5, h * 1, w * 1.15, h * 0.6, w * 0.95, h * 0.3);
        path.cubicTo(w * 0.75, h * 0, w * 0.5, h * 0.2, w * 0.5, h * 0.25);
        break;
      case SuitType.diamond:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.5);
        path.close();
        break;
      case SuitType.spade:
        path.reset();
        path.moveTo(w * 0.5, 0);
        path.cubicTo(w * 0.05, h * 0.35, w * 0, h * 0.8, w * 0.45, h * 0.8);
        path.lineTo(w * 0.35, h);
        path.lineTo(w * 0.65, h);
        path.lineTo(w * 0.55, h * 0.8);
        path.cubicTo(w * 1, h * 0.8, w * 0.95, h * 0.35, w * 0.5, 0);
        break;
      case SuitType.club:
        path.addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.3), radius: w * 0.22));
        path.addOval(Rect.fromCircle(center: Offset(w * 0.28, h * 0.6), radius: w * 0.22));
        path.addOval(Rect.fromCircle(center: Offset(w * 0.72, h * 0.6), radius: w * 0.22));
        path.moveTo(w * 0.5, h * 0.55);
        path.lineTo(w * 0.35, h);
        path.lineTo(w * 0.65, h);
        path.close();
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StackedNameRoll extends StatelessWidget {
  final List<String> names;
  final double t; // Linear 0-1
  final double outroT; // Eased 0-1
  final Color color;

  const _StackedNameRoll({
    required this.names,
    required this.t,
    required this.outroT,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 45;
    
    // Performance Optimization: Use eased internal timing for scrolling.
    final double scrollCurve = Curves.easeOutQuad.transform((t / 0.72).clamp(0.0, 1.0));
    final double travel = spacing * (names.length - 1);
    final double currentOffset = lerpDouble(spacing * 1.5, -travel, scrollCurve) ?? 0;

    final String landingText = 'KAAT';
    
    // Cinematic movement: Move UP ~218px and scale from 1.0 to 1.45.
    final double verticalMove = outroT * -218;
    final double scaleUp = 1.0 + (outroT * 0.45);
    final double brandOpacity = (outroT * 2.0).clamp(0.0, 1.0);
    final double listOpacity = (1.0 - (outroT * 4.0)).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(0, verticalMove),
      child: Transform.scale(
        scale: scaleUp,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rolling Name List (Fade-out during outro)
            if (listOpacity > 0.0)
              Opacity(
                opacity: listOpacity,
                child: ClipRect(
                  child: SizedBox(
                    height: spacing * 2.2,
                    child: Stack(
                      alignment: Alignment.center,
                      children: List.generate(names.length, (i) {
                        final dy = currentOffset + i * spacing;
                        // Avoid ImageFiltered for performance — distance-based transparency only.
                        final dist = (dy.abs() / (spacing * 1.25)).clamp(0.0, 1.0);
                        final opacity = (1.0 - (dist * 0.85)).clamp(0.0, 1.0);
                        
                        return Transform.translate(
                          offset: Offset(0, dy),
                          child: Opacity(
                            opacity: opacity,
                            child: Text(
                              names[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

            // Fluid Brand Name "KAAT" Fade-in.
            if (brandOpacity > 0.0)
              Opacity(
                opacity: brandOpacity,
                child: Text(
                  landingText,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
