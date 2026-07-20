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

  // ── Menu tile icons (Wishlist / Produits aimés / Historique) ──
  // Historique n'a pas besoin de couleurs dédiées : primary() +
  // accent20() reproduisent déjà exactement ce look (teal sur fond
  // teal translucide), donc on les réutilise tel quel plus bas.

  static const Color wishlistIcon = Color(0xFFC0182B);
  static const Color wishlistIconBg = Color(0xFFFBE3E6);
  static const Color wishlistIconDark = Color(0xFFFF6B81);
  static final Color wishlistIconBgDark = const Color(0xFFFF6B81).withValues(alpha: 0.20);

  static const Color likedProductsIcon = Color(0xFF9A5B23);
  static const Color likedProductsIconBg = Color(0xFFF6E3C7);
  static const Color likedProductsIconDark = Color(0xFFE0A868);
  static final Color likedProductsIconBgDark = const Color(0xFFE0A868).withValues(alpha: 0.20);

  static const Color securityIcon = Color(0xFF6B4232);
  static const Color securityIconBg = Color(0xFFF0E1D6);
  static const Color securityIconDark = Color(0xFFC98B6C);
  static final Color securityIconBgDark = const Color(0xFFC98B6C).withValues(alpha: 0.20);

  static const Color notificationsIcon = Color(0xFF3D3A2E);
  static const Color notificationsIconBg = Color(0xFFE8E3DC);
  static const Color notificationsIconDark = Color(0xFFCBB894);
  static final Color notificationsIconBgDark = const Color(0xFFCBB894).withValues(alpha: 0.20);

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

  // ── Menu tile getters ──────────────────────────────────────────
  static Color wishlist(BuildContext context) =>
      _isDark(context) ? wishlistIconDark : wishlistIcon;

  static Color wishlistBg(BuildContext context) =>
      _isDark(context) ? wishlistIconBgDark : wishlistIconBg;

  /// "Se déconnecter" utilise le même rouge/rose que wishlist() ->
  /// alias sémantique plutôt que couleur dupliquée.
  static Color logout(BuildContext context) => wishlist(context);

  static Color logoutBg(BuildContext context) => wishlistBg(context);

  static Color likedProducts(BuildContext context) =>
      _isDark(context) ? likedProductsIconDark : likedProductsIcon;

  static Color likedProductsBg(BuildContext context) =>
      _isDark(context) ? likedProductsIconBgDark : likedProductsIconBg;

  /// Historique réutilise primary()/accent20() -> pas de couleur dédiée.
  static Color history(BuildContext context) => primary(context);

  static Color historyBg(BuildContext context) => accent20(context);

  static Color security(BuildContext context) =>
      _isDark(context) ? securityIconDark : securityIcon;

  static Color securityBg(BuildContext context) =>
      _isDark(context) ? securityIconBgDark : securityIconBg;

  static Color notifications(BuildContext context) =>
      _isDark(context) ? notificationsIconDark : notificationsIcon;

  static Color notificationsBg(BuildContext context) =>
      _isDark(context) ? notificationsIconBgDark : notificationsIconBg;

  /// Icônes "neutres" de type paramètres (Informations personnelles,
  /// Gestion des adresses...) -> même look gris/teal que primary()/accent20(),
  /// exposé sous un nom sémantique dédié plutôt que dupliqué.
  static Color neutral(BuildContext context) => primary(context);

  static Color neutralBg(BuildContext context) => accent20(context);
}