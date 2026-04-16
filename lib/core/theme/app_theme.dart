import "package:flutter/material.dart";

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7FAFC),
    );
  }
}
