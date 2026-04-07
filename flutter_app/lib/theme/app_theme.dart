import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeData {
  final bool isDark;
  final bool isPremium;
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
    this.isPremium = false,
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
      isPremium: false,
      background: Color(0xFFFFFFFF),
      surfaceCard: Color(0xFFF9F9F9),
      borderCard: Color(0xFFF0F0F0),
      invertedCard: Color(0xFF111111),
      accent: Color(0xFFC5A028), // Antique Gold/Champagne
      accent2: Color(0xFF8E731F), // Muted Bronze
      overlay: Color(0x0A000000),
      textMain: Color(0xFF111111),
      textMuted: Color(0xFF757575),
    );
  }

  factory AppThemeData.dark() {
    return const AppThemeData(
      isDark: true,
      isPremium: false,
      background: Color(0xFF131416),
      surfaceCard: Color(0xFF1B1C1F),
      borderCard: Color(0x26FFFFFF),
      invertedCard: Color(0xFF26272B),
      accent: Color(0xFFD00231),
      accent2: Color(0xFFE3123C),
      overlay: Color(0x1AFFFFFF),
      textMain: Color(0xFFF5F7FA),
      textMuted: Color(0xFFB5BDCB),
    );
  }

  factory AppThemeData.premium() {
    return const AppThemeData(
      isDark: true,
      isPremium: true,
      background: Color(0xFF000000),
      surfaceCard: Color(0xE6080808),
      borderCard: Color(0x1AD4AF37), // Very subtle gold border
      invertedCard: Color(0xFF1A1B1F),
      accent: Color(0xFFC5A028), // Antique Gold/Champagne
      accent2: Color(0xFF8E731F), // Deep Muted Bronze
      overlay: Color(0x1AFFFFFF),
      textMain: Color(0xFFF8F9FA),
      textMuted: Color(0xFF8E8E93),
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
