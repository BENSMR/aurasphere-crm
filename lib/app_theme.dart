import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF007BFF);
  static const Color primaryDarkBlue = Color(0xFF0056CC);
  static const Color primaryDarkerBlue = Color(0xFF003D99);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Gradient for hero section
  static LinearGradient get primaryGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryBlue,
        primaryDarkBlue,
        primaryDarkerBlue,
      ],
    );
  }

  // Card shadow
  static List<BoxShadow> get cardShadow {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];
  }

  // Metric colors
  static const Map<String, Color> metricColors = {
    'revenue': Colors.green,
    'jobs': Colors.blue,
    'invoices': Colors.orange,
    'team': Colors.purple,
    'completion': Colors.teal,
    'average': Colors.indigo,
    'clients': Colors.pink,
    'upcoming': Colors.cyan,
    'expenses': Colors.deepOrange,
    'profit': Colors.lightGreen,
    'satisfaction': Colors.amber,
    'repeat': Colors.brown,
    'response': Colors.blueGrey,
    'projects': Colors.red,
    'utilization': Colors.lime,
    'yearlyRevenue': Colors.purple,
  };
}
