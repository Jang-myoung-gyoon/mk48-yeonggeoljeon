import 'package:flutter/material.dart';

ThemeData buildNanseTheme() {
  const ivory = Color(0xFFF1E6C8);
  const ink = Color(0xFF19120F);
  const lacquer = Color(0xFF8C2F2F);
  const brass = Color(0xFFB99156);
  const pine = Color(0xFF214B40);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: lacquer,
    brightness: Brightness.dark,
  ).copyWith(
    primary: brass,
    secondary: pine,
    surface: const Color(0xFF211814),
    onSurface: ivory,
    onPrimary: ink,
  );

  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ink,
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: ivory,
      displayColor: ivory,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2A201B),
      elevation: 1,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: brass, width: 0.8),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2A201B),
      foregroundColor: ivory,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: pine.withValues(alpha: 0.32),
      labelStyle: const TextStyle(color: ivory),
    ),
  );
}
