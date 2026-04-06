import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0b1024), Color(0xFF0c1636)],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.1 - (sin(_controller.value * pi) * 40),
                  left: MediaQuery.of(context).size.width * 0.2 + (cos(_controller.value * pi) * 60),
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x387bd4ff), // rgba(123, 212, 255, 0.22)
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.05 + (cos(_controller.value * pi) * 50),
                  right: MediaQuery.of(context).size.width * 0.1 - (sin(_controller.value * pi) * 40),
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x33b18bff), // rgba(177, 139, 255, 0.2)
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Blur layer to diffuse the blobs
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: Container(color: Colors.transparent),
        ),
        // Foreground content
        widget.child,
      ],
    );
  }
}
