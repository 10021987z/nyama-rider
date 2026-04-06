import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Montserrat',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.background,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),

      // ── ElevatedButton — CTA vert par défaut ──────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ctaGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // ── OutlinedButton — contour orange ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Text ──────────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 15,
            color: AppColors.textPrimary),
        bodySmall: TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 13,
            color: AppColors.textSecondary),
        titleLarge: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 22,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800),
        titleMedium: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700),
        titleSmall: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600),
        // Montants FCFA — Space Mono
        displaySmall: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 28,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700),
      ),

      // ── Input ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(fontFamily: 'NunitoSans', fontSize: 16),
        hintStyle:
            const TextStyle(fontFamily: 'NunitoSans', fontSize: 15, color: AppColors.textSecondary),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      // ── BottomNav ──────────────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle:
            TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontFamily: 'NunitoSans', fontSize: 12),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
