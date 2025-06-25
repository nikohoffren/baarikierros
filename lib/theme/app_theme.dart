import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color secondaryBlack = Color(0xFF2D2D2D);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentYellow = Color(0xFFFFEB3B);
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color lightPurple = Color(0xFF9C27B0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFE0E0E0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: deepPurple,
        surface: secondaryBlack,
        onPrimary: primaryBlack,
        onSecondary: white,
        onSurface: white,
      ),
      scaffoldBackgroundColor: primaryBlack,
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryBlack,
        foregroundColor: accentGold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: accentGold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryBlack,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      cardTheme: const CardThemeData(
        color: secondaryBlack,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.all(8),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: accentGold,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightGrey,
        ),
      ),
    );
  }

  // Custom gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [accentGold, accentYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [deepPurple, lightPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [primaryBlack, secondaryBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
