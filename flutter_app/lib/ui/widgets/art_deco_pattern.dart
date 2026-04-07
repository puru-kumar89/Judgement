import 'dart:math';
import 'package:flutter/material.dart';

class ArtDecoPattern extends StatelessWidget {
  final Color color;
  final double opacity;

  const ArtDecoPattern({
    super.key,
    required this.color,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArtDecoPainter(color: color.withValues(alpha: opacity)),
      size: Size.infinite,
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
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    
    // 1. Central Diamond
    final diamondPath = Path();
    double dSize = min(size.width, size.height) * 0.4;
    diamondPath.moveTo(center.dx, center.dy - dSize);
    diamondPath.lineTo(center.dx + dSize, center.dy);
    diamondPath.lineTo(center.dx, center.dy + dSize);
    diamondPath.lineTo(center.dx - dSize, center.dy);
    diamondPath.close();
    canvas.drawPath(diamondPath, paint);

    // Smaller inner diamond
    final innerDiamondPath = Path();
    double idSize = dSize * 0.85;
    innerDiamondPath.moveTo(center.dx, center.dy - idSize);
    innerDiamondPath.lineTo(center.dx + idSize, center.dy);
    innerDiamondPath.lineTo(center.dx, center.dy + idSize);
    innerDiamondPath.lineTo(center.dx - idSize, center.dy);
    innerDiamondPath.close();
    canvas.drawPath(innerDiamondPath, paint);

    // 2. Concentric Circles
    for (double r = 0.1; r < 0.5; r += 0.08) {
      canvas.drawCircle(center, min(size.width, size.height) * r, paint);
    }

    // 3. Radiating Lines (Sunburst)
    const int rayCount = 48;
    for (int i = 0; i < rayCount; i++) {
      double angle = (i * 2 * pi) / rayCount;
      double startR = dSize * 0.1;
      double endR = dSize * 0.75;
      canvas.drawLine(
        Offset(center.dx + cos(angle) * startR, center.dy + sin(angle) * startR),
        Offset(center.dx + cos(angle) * endR, center.dy + sin(angle) * endR),
        paint,
      );
    }

    // 4. Corner Circular Elements
    double cornerOffset = min(size.width, size.height) * 0.35;
    final corners = [
      Offset(center.dx - cornerOffset, center.dy - cornerOffset),
      Offset(center.dx + cornerOffset, center.dy - cornerOffset),
      Offset(center.dx - cornerOffset, center.dy + cornerOffset),
      Offset(center.dx + cornerOffset, center.dy + cornerOffset),
    ];

    for (var corner in corners) {
      canvas.drawCircle(corner, cornerOffset * 0.25, paint);
      canvas.drawCircle(corner, cornerOffset * 0.15, paint);
      
      // Lines connecting corners to center or outer frame
      canvas.drawLine(corner, center, paint..strokeWidth = 0.5);
    }

    // 5. Outer Frame Lines
    final margin = 20.0;
    final frameRect = Rect.fromLTRB(margin, margin, size.width - margin, size.height - margin);
    canvas.drawRect(frameRect, paint..strokeWidth = 2.0);
    
    // Inset frame
    canvas.drawRect(frameRect.deflate(8), paint..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
