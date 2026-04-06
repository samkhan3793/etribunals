
import 'package:flutter/material.dart';

class AppTheme {
  // Define colors as private constants for internal use
  static const _primaryColor = Color(0xFF1976D2);
  static const _secondaryColor = Color(0xFF00C6AE);
  static const _errorColor = Color(0xFFD32F2F);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: Colors.white,
      error: _errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryColor),
      titleTextStyle: TextStyle(
        color: _primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 22,
        letterSpacing: 1.2,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _primaryColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
      hintStyle: const TextStyle(color: Colors.black38),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),
    iconTheme: const IconThemeData(color: _primaryColor),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _secondaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(color: Colors.black),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dividerColor: Colors.black12,
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primaryColor,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
