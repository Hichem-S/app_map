import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware color helpers.
/// Usage: context.bgPage, context.cardColor, context.textPrimary, etc.
extension AppTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get bgPage  => isDark ? AppColors.darkBg      : AppColors.bgPage;
  Color get bgCard  => isDark ? AppColors.darkSurface  : Colors.white;
  Color get bgMuted => isDark ? const Color(0xFF263148) : AppColors.bgMuted;

  // Text
  Color get textPrimary => isDark ? Colors.white                : AppColors.textH;
  Color get textSecondary => isDark ? const Color(0xFFCBD5E1)   : AppColors.textBody;
  Color get textHint    => isDark ? const Color(0xFF64748B)     : AppColors.textMuted;

  // Borders / dividers
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.border;

  // Convenience: scaffold & card from theme (respects ThemeProvider)
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get cardBg     => Theme.of(this).cardColor;
}
