import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeData {
  final bool isDark;
  final Color background;
  final Color surfaceCard;
  final Color borderCard;
  final Color invertedCard;
  final Color accent;
  final Color accent2;
  final Color overlay;
  final Color textMain;
  final Color textMuted;
  
  final Color success = const Color(0xFF34C759); 
  final Color danger = const Color(0xFFE63946);
  final Color warning = const Color(0xFFFF9500);

  const AppThemeData({
    required this.isDark,
    required this.background,
    required this.surfaceCard,
    required this.borderCard,
    required this.invertedCard,
    required this.accent,
    required this.accent2,
    required this.overlay,
    required this.textMain,
    required this.textMuted,
  });

  factory AppThemeData.light() {
    return const AppThemeData(
      isDark: false,
      background: Color(0xFFF5F8FA),
      surfaceCard: Color(0xFFFFFFFF),
      borderCard: Color(0xFFE9EDF2),
      invertedCard: Color(0xFF1B1F2A),
      accent: Color(0xFFB1002C),
      accent2: Color(0xFFDC143C),
      overlay: Color(0x0D000000),
      textMain: Color(0xFF0F172A),
      textMuted: Color(0xFF6B7280),
    );
  }

  factory AppThemeData.dark() {
    return const AppThemeData(
      isDark: true,
      background: Color(0xFF0F1116),
      surfaceCard: Color(0xFF16191F),
      borderCard: Color(0x33242A33),
      invertedCard: Color(0xFF0E1016),
      accent: Color(0xFFD00231),
      accent2: Color(0xFFE3123C),
      overlay: Color(0x1AFFFFFF),
      textMain: Color(0xFFF5F7FA),
      textMuted: Color(0xFFA7B0C0),
    );
  }

  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent2,
        onSecondary: Colors.white,
        error: danger,
        onError: Colors.white,
        surface: background,
        onSurface: textMain,
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -1.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textMain,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          elevation: 10,
          shadowColor: accent.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }
}

// Legacy compatibility shim for original screens
class AppTheme {
  static const Color bgDeep = Color(0xFF0b1024);
  static const Color bgInk = Color(0xFF0c1636);
  static const Color accent = Color(0xFFE63946);
  static const Color accentStrong = Color(0xFF55b0ff);
  static const Color accent2 = Color(0xFFb18bff);
  static const Color success = Color(0xFF34C759);
  static const Color danger = Color(0xFFE63946);
  static const Color textMain = Color(0xFFe9eeff);
  static const Color textMuted = Color(0xFF9fb0d2);
  static const Color cardBorder = Color(0x24FFFFFF);
  static const Color panel = Color(0x0AFFFFFF);
}
