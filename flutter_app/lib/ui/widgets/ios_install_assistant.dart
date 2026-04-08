import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';

class IosInstallAssistant extends StatefulWidget {
  final VoidCallback onDismiss;

  const IosInstallAssistant({super.key, required this.onDismiss});

  @override
  State<IosInstallAssistant> createState() => _IosInstallAssistantState();
}

class _IosInstallAssistantState extends State<IosInstallAssistant> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                'Install Kaat Pro',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFC5A028),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Experience full-screen, high-performance gameplay.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),

              // Steps
              _buildStep(
                index: 0,
                title: 'Tap the Share Button',
                description: 'Located at the bottom of your Safari window.',
                icon: Icons.ios_share,
                isActive: _currentStep == 0,
              ),
              const SizedBox(height: 32),
              _buildStep(
                index: 1,
                title: 'Add to Home Screen',
                description: 'Scroll down and select "Add to Home Screen".',
                icon: Icons.add_box_outlined,
                isActive: _currentStep == 1,
              ),

              const SizedBox(height: 64),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 1) {
                        setState(() => _currentStep++);
                      } else {
                        widget.onDismiss();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5A028),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_currentStep == 0 ? 'Next Step' : 'Got it!'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required int index,
    required String title,
    required String description,
    required IconData icon,
    required bool isActive,
  }) {
    final color = isActive ? const Color(0xFFC5A028) : Colors.white.withValues(alpha: 0.2);
    
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.4,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP ${index + 1}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
