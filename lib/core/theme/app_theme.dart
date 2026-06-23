import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── الألوان الأساسية ──────────────────────────────────────────────────────
  static const Color green      = Color(0xFF0A7C4E);
  static const Color greenDark  = Color(0xFF065C3A);
  static const Color greenLight = Color(0xFF1A3D2E);
  static const Color gold       = Color(0xFFD4A853);
  static const Color red        = Color(0xFFC0392B);
  static const Color redLight   = Color(0xFF3D1A1A);

  // ── خلفيات ───────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFF0F172A);
  static const Color backgroundDark  = Color(0xFF0F172A);

  // ── أسماء بديلة تستخدمها الواجهات ────────────────────────────────────────
  static const Color primaryColor   = green;
  static const Color surfaceColor   = Color(0xFF1E293B);
  static const Color errorColor     = red;
  static const Color successColor   = green;
  static const Color backgroundColor = Color(0xFF0F172A);
  static const Color textPrimary    = Color(0xFFFDFDFD);
  static const Color textSecondary  = Color(0xFF94A3B8);

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.cairo(fontWeight: FontWeight.bold,  color: textPrimary),
        titleLarge:   GoogleFonts.cairo(fontWeight: FontWeight.w800,  color: textPrimary),
        bodyLarge:    GoogleFonts.cairo(color: textPrimary,    fontSize: 16),
        bodyMedium:   GoogleFonts.cairo(color: textSecondary,  fontSize: 14),
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
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: green, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontFamily: 'Cairo'),
        hintStyle:  const TextStyle(color: textSecondary, fontFamily: 'Cairo'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: green,
        unselectedItemColor: textSecondary,
      ),
    );
  }

  // ── Dark Theme (نفس الـ light لأن التطبيق dark بالكامل) ──────────────────
  static ThemeData get darkTheme => lightTheme;
}
