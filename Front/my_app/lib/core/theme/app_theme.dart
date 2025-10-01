import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: const Color(0xFFC7384D),
    scaffoldBackgroundColor: const Color(0xFF0A0A0B),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFC7384D),
      secondary: Color(0xFFB0B0B0), // Un gris un poco más claro
    ),
    textTheme: ThemeData.dark().textTheme.apply(fontFamily: "ProductSans"),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade900,
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
        borderSide: const BorderSide(color: Color(0xFFC7384D), width: 2),
      ),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
  );
}
