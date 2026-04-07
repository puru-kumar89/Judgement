import 'dart:math';
import 'package:flutter/material.dart';

/// An elite Art Deco background pattern that reacts to navigation.
/// Featuring high-density corner geometry and radial masking.
class ArtDecoPattern extends StatefulWidget {
  final Color color;
  final double opacity;
  final Key? transitionKey; // To trigger animation on rebuild

  const ArtDecoPattern({
    super.key,
    required this.color,
    this.opacity = 0.12,
    this.transitionKey,
  });

  @override
  State<ArtDecoPattern> createState() => _ArtDecoPatternState();
}

class _ArtDecoPatternState extends State<ArtDecoPattern> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Smooth entry "pulse" and "rotate"
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _rotate = Tween<double>(begin: -0.04, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );

    _ctrl.forward();
  }

  @override
  void didUpdateWidget(ArtDecoPattern oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transitionKey != oldWidget.transitionKey) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            Colors.transparent, 
            Colors.black.withValues(alpha: 0.12),
            Colors.black,
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: CustomPaint(
        painter: _ArtDecoPainter(color: widget.color.withValues(alpha: widget.opacity)),
        size: Size.infinite,
      ),
    );
  }
}

class _ArtDecoPainter extends CustomPainter {
  final Color color;

  _ArtDecoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);
    final double baseDim = min(size.width, size.height);
    
    // 1. Central Diamonds (Layered sunburst)
    for (double i = 1.0; i > 0.5; i -= 0.1) {
      final path = Path();
      double dSize = baseDim * 0.45 * i;
      path.moveTo(center.dx, center.dy - dSize);
      path.lineTo(center.dx + dSize, center.dy);
      path.lineTo(center.dx, center.dy + dSize);
      path.lineTo(center.dx - dSize, center.dy);
      path.close();
      canvas.drawPath(path, paint..strokeWidth = 0.4);
    }

    // 2. High-Density Geometric Rays
    const int rayCount = 72;
    for (int i = 0; i < rayCount; i++) {
       double angle = (i * 2 * pi) / rayCount;
       double startR = baseDim * 0.12;
       double endR = baseDim * 0.9;
       canvas.drawLine(
         Offset(center.dx + cos(angle) * startR, center.dy + sin(angle) * startR),
         Offset(center.dx + cos(angle) * endR, center.dy + sin(angle) * endR),
         paint..strokeWidth = 0.25,
       );
    }

    // 3. Complex Corner Gears (Improved detail from image)
    double cornerOffset = baseDim * 0.45;
    final corners = [
      Offset(center.dx - cornerOffset, center.dy - cornerOffset),
      Offset(center.dx + cornerOffset, center.dy - cornerOffset),
      Offset(center.dx - cornerOffset, center.dy + cornerOffset),
      Offset(center.dx + cornerOffset, center.dy + cornerOffset),
    ];

    for (var corner in corners) {
      // Nested concentric circles like gears
      for (double r = 0.14; r > 0.02; r -= 0.03) {
        canvas.drawCircle(corner, baseDim * r, paint..strokeWidth = 0.5);
      }
      
      // Secondary radiating lines from corner
      for (int i = 0; i < 12; i++) {
         double angle = (i * 2 * pi) / 12;
         canvas.drawLine(
           corner,
           Offset(corner.dx + cos(angle) * baseDim * 0.18, corner.dy + sin(angle) * baseDim * 0.18),
           paint..strokeWidth = 0.3,
         );
      }
      
      // Decorative squares/diamonds in corners
      final sqSize = baseDim * 0.06;
      canvas.drawRect(Rect.fromCenter(center: corner, width: sqSize, height: sqSize), paint);
    }

    // 4. Double Border Frame
    const margin = 10.0;
    canvas.drawRect(Rect.fromLTRB(margin, margin, size.width - margin, size.height - margin), paint..strokeWidth = 1.0);
    canvas.drawRect(Rect.fromLTRB(margin + 6, margin + 6, size.width - margin - 6, size.height - margin - 6), paint..strokeWidth = 0.4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
