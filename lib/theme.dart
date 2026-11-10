import 'package:flutter/material.dart';

/// The colours used in the Figma design.
class AppColors {
  static const purple = Color(0xFF2E0F6B);
  static const lime = Color(0xFFC6FF3A);
  static const red = Color(0xFFFF1F57);
  static const green = Color(0xFF3A9D6B);
  static const cream = Color(0xFFFDEFD6);
  static const lavender = Color(0xFFF3EEFF);
  static const border = Color(0xFFB9AEDA);
  static const darkBg = Color(0xFF14091F);
  static const darkSurface = Color(0xFF211338);
}

/// Shortcuts so screens can ask for "the text colour" and get the right one
/// for light or dark mode: `context.ink`, `context.muted`, ...
extension ThemeShortcuts on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get ink => isDark ? Colors.white : AppColors.purple;
  Color get muted => isDark ? Colors.white60 : Colors.black54;
  Color get cardBorder => isDark ? Colors.white24 : AppColors.border;
  Color get surfaceTint => isDark ? AppColors.darkSurface : AppColors.lavender;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.purple;
    final border = dark ? Colors.white24 : AppColors.border;

    OutlineInputBorder outline(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: dark ? AppColors.darkBg : Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: brightness,
        primary: ink,
        surface: dark ? AppColors.darkBg : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.darkBg : Colors.white,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle:
            TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: outline(border),
        enabledBorder: outline(border),
        focusedBorder: outline(ink),
        errorBorder: outline(AppColors.red),
        focusedErrorBorder: outline(AppColors.red),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.purple,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: dark ? AppColors.darkBg : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        padding: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.purple,
        elevation: 0,
        shape: CircleBorder(),
      ),
    );
  }
}
