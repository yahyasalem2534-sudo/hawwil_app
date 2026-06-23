import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── الألوان الأساسية ──────────────────────────────────────────────────────
  static const Color green      = Color(0xFF0A7C4E);
  static const Color greenDark  = Color(0xFF065C3A);
  static const Color greenLight = Color(0xFF1A3D2E);
  static const Color gold       = Color(0xFFD4A853);
  static const Color red        = Color(0xFFC0392B);

  // ── خلفيات ───────────────────────────────────────────────────────────────
  static const Color backgroundColor = Color(0xFF0F172A);
  static const Color surfaceColor    = Color(0xFF1E293B);
  static const Color surface2Color   = Color(0xFF263548);

  // ── أسماء بديلة ──────────────────────────────────────────────────────────
  static const Color primaryColor  = green;
  static const Color errorColor    = red;
  static const Color textPrimary   = Color(0xFFFDFDFD);
  static const Color textSecondary = Color(0xFF94A3B8);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: Brightness.dark,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge:   GoogleFonts.cairo(fontWeight: FontWeight.w800, color: textPrimary),
        bodyLarge:    GoogleFonts.cairo(color: textPrimary,   fontSize: 16),
        bodyMedium:   GoogleFonts.cairo(color: textSecondary, fontSize: 14),
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}