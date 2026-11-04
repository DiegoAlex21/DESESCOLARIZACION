import 'package:flutter/material.dart';

abstract final class CampusColors {
  static const indigo = Color(0xFF4053B5);
  static const blue = Color(0xFF4387F5);
  static const background = Color(0xFFF4F4F4);
  static const text = Color(0xFF28282C);
  static const muted = Color(0xFF777780);
  static const purple = Color(0xFFAD29BF);
  static const green = Color(0xFF4CAF64);
  static const orange = Color(0xFFF18A00);
}

abstract final class CampusTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: CampusColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CampusColors.indigo,
      primary: CampusColors.indigo,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CampusColors.indigo,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CampusColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CampusColors.indigo, width: 1.5),
      ),
    ),
  );
}
