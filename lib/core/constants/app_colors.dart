import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Palette principale ────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B4332);       // Vert actions
  static const Color primaryDark = Color(0xFF0F2B1F);
  static const Color primaryLight = Color(0xFF2D6A4F);
  static const Color secondary = Color(0xFFD4A017);     // Or gains
  static const Color error = Color(0xFFDC2626);         // Rouge refus
  static const Color navBlue = Color(0xFF1565C0);       // Bleu navigation

  // ── Statuts ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color newCourse = Color(0xFFDC2626);     // Alerte nouvelle course

  // ── Textes ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);   // Noir pur — contraste AAA
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textOnPrimary = Colors.white;

  // ── Surfaces — fond BLANC PUR pour lisibilité soleil ─────────────────────
  static const Color background = Color(0xFFFFFFFF);    // Blanc pur
  static const Color surface = Color(0xFFF3F4F6);
  static const Color cardBg = Colors.white;
  static const Color divider = Color(0xFFE5E7EB);

  // ── Ombres ────────────────────────────────────────────────────────────────
  static const Color cardShadow = Color(0x14000000);
}
