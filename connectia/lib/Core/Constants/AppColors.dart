import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevents instantiation

  // ── Light mode ──────────────────────────────────────────────
  static const Color primaryBrand = Color(0xFF375260);
  static const Color defaultBase = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFAAB9C2);
  static const Color softBackground = Color(0xFFF3F5F6);
  static final Color accentDecorative20 = const Color(0xFF4A6B7A).withValues(alpha: 0.20);
  static final Color accentDecorative30 = const Color(0xFF4A6B7A).withValues(alpha: 0.30);
  static const Color buttonSurface = Color(0xFFFFFFFF);
  static const Color buttonSurfaceAlt = Color(0xFFF5F5F5);

  // ── Dark mode ───────────────────────────────────────────────
  static const Color primaryBrandDark = Color(0xFF6C93A6);
  static const Color defaultBaseDark = Color(0xFF10171B);
  static const Color softBackgroundDark = Color(0xFF1B252B);
  static const Color secondaryTextDark = Color(0xFF8FA3AC);
  static final Color accentDecorative20Dark = const Color(0xFF6C93A6).withValues(alpha: 0.20);
  static final Color accentDecorative30Dark = const Color(0xFF6C93A6).withValues(alpha: 0.30);
  static const Color buttonSurfaceDark = Color(0xFF223038);
  static const Color buttonSurfaceAltDark = Color(0xFF2A3A43);

  // ── Context-aware getters ─────────────────────────────────────
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primary(BuildContext context) =>
      _isDark(context) ? primaryBrandDark : primaryBrand;

  static Color background(BuildContext context) =>
      _isDark(context) ? defaultBaseDark : defaultBase;

  static Color softBg(BuildContext context) =>
      _isDark(context) ? softBackgroundDark : softBackground;

  static Color secondary(BuildContext context) =>
      _isDark(context) ? secondaryTextDark : secondaryText;

  static Color accent20(BuildContext context) =>
      _isDark(context) ? accentDecorative20Dark : accentDecorative20;

  static Color accent30(BuildContext context) =>
      _isDark(context) ? accentDecorative30Dark : accentDecorative30;

  static Color surface(BuildContext context) =>
      _isDark(context) ? buttonSurfaceDark : buttonSurface;

  static Color surfaceAlt(BuildContext context) =>
      _isDark(context) ? buttonSurfaceAltDark : buttonSurfaceAlt;

  /// Text/icon color that always contrasts correctly against `primary()`
  static Color onPrimary(BuildContext context) =>
      _isDark(context) ? defaultBaseDark : defaultBase;

  /// Neutral text color that flips black/white depending on mode
  static Color primaryText(BuildContext context) =>
      _isDark(context) ? defaultBase : Colors.black;
}