import 'package:flutter/material.dart';

const kRed = Color(0xFFE63946);
const kBg = Color(0xFF0D0D0F);
const kSurface = Color(0xFF161619);
const kBorder = Color(0xFF1E1E22);
const kBorderDim = Color(0xFF252528);
const kText = Color(0xFFE2E2E2);
const kTextDim = Color(0xFF888888);
const kTextMuted = Color(0xFF444444);

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: kBg,
  colorScheme: const ColorScheme.dark(
    surface: kBg,
    primary: kRed,
    secondary: kRed,
    onSurface: kText,
  ),
  fontFamily: 'monospace',
  appBarTheme: const AppBarTheme(
    backgroundColor: kBg,
    foregroundColor: kText,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: kRed,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 4,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kBg,
    selectedItemColor: kRed,
    unselectedItemColor: kTextMuted,
    selectedLabelStyle: TextStyle(fontSize: 9, letterSpacing: 2),
    unselectedLabelStyle: TextStyle(fontSize: 9, letterSpacing: 2),
    type: BottomNavigationBarType.fixed,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: kBorderDim),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: kBorderDim),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: kRed),
    ),
    labelStyle: const TextStyle(color: kTextDim, fontSize: 12),
    hintStyle: const TextStyle(color: kTextMuted, fontSize: 12),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kRed,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(letterSpacing: 1.5, fontSize: 12),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: kRed),
  ),
  dividerColor: kBorder,
);
