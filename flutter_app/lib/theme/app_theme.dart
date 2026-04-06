import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgDeep = Color(0xFF0b1024);
  static const Color bgInk = Color(0xFF0c1636);
  static const Color accent = Color(0xFF7bd4ff);
  static const Color accentStrong = Color(0xFF55b0ff);
  static const Color accent2 = Color(0xFFb18bff);
  static const Color success = Color(0xFF3dd598);
  static const Color danger = Color(0xFFff6b6b);
  static const Color textMain = Color(0xFFe9eeff);
  static const Color textMuted = Color(0xFF9fb0d2);
  static const Color cardBorder = Color(0x24FFFFFF); // rgba(255, 255, 255, 0.14)
  static const Color panel = Color(0x0AFFFFFF); // rgba(255, 255, 255, 0.04)

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent2,
        surface: bgInk,
        error: danger,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: textMain,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: textMain,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textMain,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF031029),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 8,
          shadowColor: accent.withOpacity(0.45),
        ),
      ),
    );
  }
}
