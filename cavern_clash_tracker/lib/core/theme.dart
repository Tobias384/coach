import 'package:flutter/material.dart';

class AppTheme {
  static const _accentColor = Color(0xFF8E8E93);

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accentColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF111111),
      background: const Color(0xFF0A0A0A),
      primary: _accentColor,
      onPrimary: Colors.white,
      secondary: _accentColor,
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111111),
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
    ),
  );
}
