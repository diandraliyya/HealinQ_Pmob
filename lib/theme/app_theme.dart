import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFE91E8C);
  static const Color primaryLight = Color(0xFFF8BBD9);
  static const Color primarySoft = Color(0xFFFCE4EC);
  static const Color secondary = Color(0xFF80DEEA);
  static const Color secondaryLight = Color(0xFFE0F7FA);
  static const Color accent = Color(0xFF4FC3F7);
  static const Color teal = Color(0xFF4DB6AC);
  static const Color tealLight = Color(0xFFB2DFDB);
  static const Color bgGradientStart = Color(0xFFB2EBF2);
  static const Color bgGradientEnd = Color(0xFFF8BBD9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color cardBg = Color(0xFFFFF0F5);
  static const Color pinkCard = Color(0xFFFCE4EC);
  static const Color mintCard = Color(0xFFE0F2F1);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color starYellow = Color(0xFFFFC107);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.teal,
        background: AppColors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.teal, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14),
      ),
    );
  }
}
