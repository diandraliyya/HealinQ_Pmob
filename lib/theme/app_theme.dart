import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFE91E8F);
  static const Color primaryLight = Color(0xFFF8BBD9);
  static const Color primarySoft = Color(0xFFFCE4EC);

  static const Color secondary = Color(0xFF9BDAF8);
  static const Color secondaryLight = Color(0xFFE0F7FA);
  static const Color accent = Color(0xFF4FC3F7);

  static const Color teal = Color(0xFF4AA7A2);
  static const Color tealLight = Color(0xFFB2DFDB);

  static const Color bgGradientStart = Color(0xFFD4EFFC);
  static const Color bgGradientEnd = Color(0xFFFCE4EC);

  static const Color white = Color(0xFFFFFFFF);

  static const Color textDark = Color(0xFF2C3E50);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);

  static const Color cardBg = Color(0xFFFFF0F5);
  static const Color pinkCard = Color(0xFFFCE4EC);
  static const Color mintCard = Color(0xFFC6F1ED);

  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color starYellow = Color(0xFFFFC107);

  // Tambahan warna template biar screen-screen yang lain bisa konsisten
  static const Color brandTeal = Color(0xFF4AA7A2);
  static const Color brandBlue = Color(0xFF0C72A6);
  static const Color brandGreen = Color(0xFF2E7D5F);

  static const Color blobPink = Color(0xFFFFE5F4);
  static const Color blobTeal = Color(0xFF53BAB3);
  static const Color blobBlue = Color(0xFF9BDAF8);

  static const Color surfaceBorder = Color(0xFFE0E0E0);
  static const Color surfaceMuted = Color(0xFFF6F9FC);
}

class AppTheme {
  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.teal,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.white,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.poppins(
          color: AppColors.textDark,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.poppins(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.poppins(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: AppColors.textMedium,
        ),
        bodyMedium: GoogleFonts.poppins(
          color: AppColors.textMedium,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.brandTeal.withOpacity(0.55),
          disabledForegroundColor: AppColors.white,
          elevation: 0,
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.surfaceBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.brandTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textLight,
          fontSize: 14,
        ),
      ),
      dividerColor: AppColors.surfaceBorder,
    );
  }
}
