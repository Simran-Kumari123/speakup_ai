import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand
  static const Color primary   = Color(0xFF00C896); // emerald green
  static const Color secondary = Color(0xFF0A84FF); // electric blue
  static const Color accent    = Color(0xFFFFB800); // gold
  static const Color success   = Color(0xFF00C896);
  static const Color danger    = Color(0xFFFF4757);

  // Dark Colors
  static const Color darkBg      = Color(0xFF0A0A0F);
  static const Color darkCard    = Color(0xFF13131A);
  static const Color darkSurface = Color(0xFF1C1C27);
  static const Color darkBorder  = Color(0xFF2A2A38);

  // Light Colors
  static const Color lightBg      = Color(0xFFF8F9FA);
  static const Color lightCard    = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF1F3F5);
  static const Color lightBorder  = Color(0xFFE9ECEF);

  // Earthy Light Palette
  static const Color earthyBg      = Color(0xFFF7F4E9); // Warm Cream
  static const Color earthyCard    = Color(0xFFB7C2A9); // Muted Sage
  static const Color earthyAccent  = Color(0xFFBD6448); // Terracotta
  static const Color earthyText    = Color(0xFF3A3631); // Dark Charcoal
  static const Color earthySurface = Color(0xFFE8E5D5); // Slightly darker cream for depth

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);


  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: earthyBg,
    primaryColor: earthyAccent,
    colorScheme: ColorScheme.light(
      primary: earthyAccent,
      secondary: earthyCard,
      tertiary: earthyAccent.withValues(alpha: 0.8), // Darker Terracotta for high-contrast details
      surface: earthyCard,
      error: danger,
      onPrimary: Colors.white,
      onSurface: earthyText,
    ),
    cardColor: earthyCard,
    dividerColor: earthyText.withValues(alpha: 0.1),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w900, color: earthyText),
      displayMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w800, color: earthyText),
      displaySmall: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: earthyText),
      headlineLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w800, color: earthyText),
      headlineMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: earthyText),
      headlineSmall: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, color: earthyText),
      titleLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: earthyText),
      bodyLarge: GoogleFonts.dmSans(color: earthyText.withOpacity(0.9), fontSize: 16),
      bodyMedium: GoogleFonts.dmSans(color: earthyText.withOpacity(0.8), fontSize: 14),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: earthyBg,
      elevation: 0,
      titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w800, color: earthyText),
      iconTheme: const IconThemeData(color: earthyText),
    ),
    cardTheme: CardThemeData(
      color: earthyCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: earthyText.withOpacity(0.05), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: earthyAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: earthySurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: earthyAccent, width: 2)),
      hintStyle: TextStyle(color: earthyText.withOpacity(0.3)),
    ),
  );

  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: darkCard,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      titleTextStyle: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
      hintStyle: const TextStyle(color: Colors.white30),
    ),
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
