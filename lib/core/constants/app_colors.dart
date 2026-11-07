import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Twilight Dark Theme Palette (Matching AI Studio Slate-950 & Indigo-600 UI)
  static const Color backgroundDark = Color(0xFF020617); // slate-950
  static const Color surfaceDark = Color(0xFF0F172A); // slate-900
  static const Color surfaceVariantDark = Color(0xFF1E293B); // slate-800
  static const Color cardDark = Color(0xFF0F172A); // slate-900
  
  // Twilight Theme Palette (Matching AI Studio Slate-950 & Indigo-600 UI across all modes)
  static const Color backgroundLight = Color(0xFF020617); // slate-950 (never white)
  static const Color surfaceLight = Color(0xFF0F172A); // slate-900
  static const Color surfaceVariantLight = Color(0xFF1E293B); // slate-800
  static const Color cardLight = Color(0xFF0F172A); // slate-900

  // Brand Accents (Indigo / Purple / Rose matching AI Studio Web UI)
  static const Color primary = Color(0xFF4F46E5); // indigo-600
  static const Color primaryAccent = Color(0xFF818CF8); // indigo-400
  static const Color secondaryAccent = Color(0xFFA855F7); // purple-500

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8); // slate-400
  static const Color textTertiaryDark = Color(0xFF64748B); // slate-500

  static const Color textPrimaryLight = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF94A3B8);
  static const Color textTertiaryLight = Color(0xFF64748B);

  // Status & Actions
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color error = Color(0xFFF43F5E); // rose-500
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF6366F1);

  // Theme-aware dynamic helpers (Strictly returns Twilight Midnight Palette)
  static bool isDark(BuildContext context) => true;

  static Color textPrimary(BuildContext context) => textPrimaryDark;

  static Color textSecondary(BuildContext context) => textSecondaryDark;

  static Color textTertiary(BuildContext context) => textTertiaryDark;

  static Color background(BuildContext context) => backgroundDark;

  static Color surface(BuildContext context) => surfaceDark;

  static Color surfaceVariant(BuildContext context) => surfaceVariantDark;

  static Color card(BuildContext context) => cardDark;

  static Color icon(BuildContext context) => const Color(0xFFCBD5E1);

  static Color iconMuted(BuildContext context) => const Color(0xFF64748B);

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF020617)],
  );
}
