// core/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF007BFF), // Electric Blue
        secondary: Color(0xFFFFD700), // Deep Navy
        surface: Color(0xFF1E2A38), // Dark Gray
        error: Color(0xFFFFA500), // Amber
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white70,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A192F),
      cardColor: const Color(0xFF1E2A38),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    );
  }
}
