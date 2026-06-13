import 'package:flutter/material.dart';

/// Single source of truth for every color in the app.
/// Import this file instead of hardcoding hex values in widgets.
class AppColors {
  AppColors._();

  // ── Primary — Indigo ──────────────────────────────────────────────────────
  static const primary      = Color(0xFF4F46E5);
  static const primaryDark  = Color(0xFF3730A3);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryGlow  = Color(0x334F46E5);

  // ── Accent — Sky ─────────────────────────────────────────────────────────
  static const accent     = Color(0xFF0EA5E9);
  static const accentDark = Color(0xFF0284C7);

  // ── Neutral backgrounds ───────────────────────────────────────────────────
  static const bgPage  = Color(0xFFF8FAFC); // Slate 50
  static const bgMuted = Color(0xFFF1F5F9); // Slate 100
  static const bgCard  = Color(0xFFFFFFFF);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const border      = Color(0xFFE2E8F0); // Slate 200
  static const borderFocus = primary;

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textH     = Color(0xFF0F172A); // Slate 900
  static const textBody  = Color(0xFF475569); // Slate 600
  static const textMuted = Color(0xFF94A3B8); // Slate 400

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const success   = Color(0xFF10B981);
  static const successBg = Color(0xFFD1FAE5);
  static const warning   = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);
  static const error     = Color(0xFFEF4444);
  static const errorBg   = Color(0xFFFEE2E2);
  static const info      = Color(0xFF3B82F6);
  static const infoBg    = Color(0xFFDBEAFE);

  // ── Dark mode ────────────────────────────────────────────────────────────
  static const darkBg      = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkBorder  = Color(0xFF334155);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const gradPrimary = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradScan = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradAdd = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradTracker = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradList = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradMap2D = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradMap3D = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradHeader = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradInstitut = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6D28D9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => const [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 1)),
  ];
  static List<BoxShadow> get shadowMd => const [
    BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x05000000), blurRadius: 4),
  ];
  static List<BoxShadow> get shadowLg => const [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x08000000), blurRadius: 8),
  ];
  static List<BoxShadow> shadowColored(Color c) => [
    BoxShadow(color: c.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 4)),
  ];

  // ── Context-aware helpers (dark mode) ─────────────────────────────────────
  static bool _dark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color bg(BuildContext ctx)     => _dark(ctx) ? darkBg      : bgPage;
  static Color card(BuildContext ctx)   => _dark(ctx) ? darkSurface  : bgCard;
  static Color muted(BuildContext ctx)  => _dark(ctx) ? const Color(0xFF263148) : bgMuted;
  static Color divider(BuildContext ctx)=> _dark(ctx) ? darkBorder   : border;
  static Color tH(BuildContext ctx)     => _dark(ctx) ? Colors.white                : textH;
  static Color tBody(BuildContext ctx)  => _dark(ctx) ? const Color(0xFFCBD5E1)     : textBody;
  static Color tMuted(BuildContext ctx) => _dark(ctx) ? const Color(0xFF64748B)     : textMuted;
}
