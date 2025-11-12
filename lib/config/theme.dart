import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Colors (Amber)
  static const Color lightPrimary = Color(0xFFF59E0B);
  static const Color lightPrimaryHover = Color(0xFFD97706);
  static const Color lightPrimaryLight = Color(0xFFFEF3C7);
  static const Color lightPrimaryDark = Color(0xFFB45309);
  
  static const Color lightBgPrimary = Color(0xFFFFFFFF);
  static const Color lightBgSecondary = Color(0xFFF9FAFB);
  static const Color lightBgTertiary = Color(0xFFF3F4F6);
  
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextTertiary = Color(0xFF6B7280);
  
  static const Color lightBorderPrimary = Color(0xFFE5E7EB);
  static const Color lightBorderSecondary = Color(0xFFD1D5DB);
  
  static const Color lightHoverBg = Color(0xFFF3F4F6);
  static const Color lightActiveBg = Color(0xFFE5E7EB);

  // Dark Mode Colors (VSCode Blue)
  static const Color darkPrimary = Color(0xFF569CD6);
  static const Color darkPrimaryHover = Color(0xFF4A8CC5);
  static const Color darkPrimaryLight = Color(0xFF6AADD7);
  static const Color darkPrimaryDark = Color(0xFF3D7AB8);
  
  static const Color darkBgPrimary = Color(0xFF1E1E1E);
  static const Color darkBgSecondary = Color(0xFF252526);
  static const Color darkBgTertiary = Color(0xFF2D2D30);
  
  static const Color darkTextPrimary = Color(0xFFCCCCCC);
  static const Color darkTextSecondary = Color(0xFF9D9D9D);
  static const Color darkTextTertiary = Color(0xFF808080);
  
  static const Color darkBorderPrimary = Color(0xFF3E3E42);
  static const Color darkBorderSecondary = Color(0xFF2D2D30);
  
  static const Color darkHoverBg = Color(0xFF2D2D30);
  static const Color darkActiveBg = Color(0xFF3E3E42);

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: lightPrimary,
        secondary: lightPrimaryHover,
        surface: lightBgPrimary,
        background: lightBgSecondary,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onBackground: lightTextPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBgPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBgPrimary,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: lightBgPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: lightBorderPrimary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      dividerColor: lightBorderPrimary,
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkPrimaryHover,
        surface: darkBgPrimary,
        background: darkBgSecondary,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBgPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBgPrimary,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkBgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBorderPrimary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      dividerColor: darkBorderPrimary,
    );
  }

  // Helper methods to get colors based on theme
  static Color getPrimaryColor(bool isDark) => isDark ? darkPrimary : lightPrimary;
  static Color getPrimaryHoverColor(bool isDark) => isDark ? darkPrimaryHover : lightPrimaryHover;
  static Color getBgPrimaryColor(bool isDark) => isDark ? darkBgPrimary : lightBgPrimary;
  static Color getBgSecondaryColor(bool isDark) => isDark ? darkBgSecondary : lightBgSecondary;
  static Color getBgTertiaryColor(bool isDark) => isDark ? darkBgTertiary : lightBgTertiary;
  static Color getTextPrimaryColor(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color getTextSecondaryColor(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color getTextTertiaryColor(bool isDark) => isDark ? darkTextTertiary : lightTextTertiary;
  static Color getBorderPrimaryColor(bool isDark) => isDark ? darkBorderPrimary : lightBorderPrimary;
  static Color getBorderSecondaryColor(bool isDark) => isDark ? darkBorderSecondary : lightBorderSecondary;
  static Color getHoverBgColor(bool isDark) => isDark ? darkHoverBg : lightHoverBg;
  static Color getActiveBgColor(bool isDark) => isDark ? darkActiveBg : lightActiveBg;
}

