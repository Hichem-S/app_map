import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  // ── Light ───────────────────────────────────────────────────────────────────
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary:                 AppColors.primary,
      secondary:               AppColors.primaryLight,
      surface:                 AppColors.bgCard,
      surfaceContainerHighest: AppColors.bgMuted,
      onSurface:               AppColors.textH,
      onSurfaceVariant:        AppColors.textBody,
      outline:                 AppColors.border,
      error:                   AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.bgPage,
    cardColor: AppColors.bgCard,
    dividerColor: AppColors.border,

    // ── AppBar ────────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgCard,
      foregroundColor: AppColors.textH,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textH,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),

    // ── Input ─────────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgMuted,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Buttons ───────────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // ── Card ─────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // ── Snack bar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: const TextStyle(
        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Dialog ───────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: AppColors.textH, fontSize: 18, fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.textBody, fontSize: 14,
      ),
    ),

    // ── Bottom sheet ──────────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 0,
    ),

    // ── Checkbox ─────────────────────────────────────────────────────────────
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColors.border, width: 1.5),
    ),

    // ── List tile ────────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        color: AppColors.textH, fontSize: 14, fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),

    // ── Divider ──────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    // ── Text ─────────────────────────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge:  TextStyle(color: AppColors.textH, fontWeight: FontWeight.w800),
      displayMedium: TextStyle(color: AppColors.textH, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: AppColors.textH, fontWeight: FontWeight.w700, fontSize: 28),
      headlineMedium:TextStyle(color: AppColors.textH, fontWeight: FontWeight.w700, fontSize: 22),
      headlineSmall: TextStyle(color: AppColors.textH, fontWeight: FontWeight.w700, fontSize: 18),
      titleLarge:    TextStyle(color: AppColors.textH, fontWeight: FontWeight.w600, fontSize: 17),
      titleMedium:   TextStyle(color: AppColors.textH, fontWeight: FontWeight.w600, fontSize: 15),
      titleSmall:    TextStyle(color: AppColors.textH, fontWeight: FontWeight.w600, fontSize: 13),
      bodyLarge:     TextStyle(color: AppColors.textBody, fontSize: 15),
      bodyMedium:    TextStyle(color: AppColors.textBody, fontSize: 14),
      bodySmall:     TextStyle(color: AppColors.textMuted, fontSize: 12),
      labelLarge:    TextStyle(color: AppColors.textH, fontWeight: FontWeight.w600, fontSize: 14),
      labelSmall:    TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500, fontSize: 11),
    ),
  );

  // ── Dark ────────────────────────────────────────────────────────────────────
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',
    primaryColor: AppColors.primaryLight,
    colorScheme: const ColorScheme.dark(
      primary:                 AppColors.primaryLight,
      secondary:               AppColors.accent,
      surface:                 AppColors.darkSurface,
      surfaceContainerHighest: Color(0xFF263148),
      onSurface:               Colors.white,
      onSurfaceVariant:        Color(0xFFCBD5E1),
      outline:                 AppColors.darkBorder,
      error:                   AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.darkBg,
    cardColor: AppColors.darkSurface,
    dividerColor: AppColors.darkBorder,

    // ── AppBar ────────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),

    // ── Input ─────────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF263148),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Buttons ───────────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.darkBorder),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    // ── Card ─────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),

    // ── Snack bar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF334155),
      contentTextStyle: const TextStyle(
        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Dialog ───────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        color: Color(0xFFCBD5E1), fontSize: 14,
      ),
    ),

    // ── Bottom sheet ──────────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 0,
    ),

    // ── Checkbox ─────────────────────────────────────────────────────────────
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
    ),

    // ── List tile ────────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),

    // ── Divider ──────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),

    // ── Text ─────────────────────────────────────────────────────────────────
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28),
      headlineMedium:TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
      headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
      titleLarge:    TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
      titleMedium:   TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge:     TextStyle(color: Color(0xFFCBD5E1), fontSize: 15),
      bodyMedium:    TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      bodySmall:     TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),
  );
}
