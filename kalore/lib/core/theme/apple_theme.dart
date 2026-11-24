import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'apple_colors.dart';

/// Apple HIG (Human Interface Guidelines) Theme for Light and Dark modes.
class AppleTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppleColors.backgroundLight,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppleColors.primaryGreen,
        onPrimary: Colors.white,
        secondary: AppleColors.primaryGreen,
        onSecondary: Colors.white,
        error: CupertinoColors.destructiveRed,
        onError: Colors.white,
        surface: AppleColors.surfaceLight,
        onSurface: AppleColors.textPrimaryLight,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppleColors.textPrimaryLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: AppleColors.textPrimaryLight),
      ),
      dividerTheme: const DividerThemeData(
        color: AppleColors.separatorLight,
        thickness: 0.5,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppleColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        minLeadingWidth: 28,
        dense: false,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppleColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppleColors.primaryGreen,
        scaffoldBackgroundColor: AppleColors.backgroundLight,
        barBackgroundColor: AppleColors.frostedGlassLight,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppleColors.backgroundDark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppleColors.primaryGreenDark,
        onPrimary: Colors.black,
        secondary: AppleColors.primaryGreenDark,
        onSecondary: Colors.black,
        error: CupertinoColors.destructiveRed,
        onError: Colors.white,
        surface: AppleColors.surfaceDark,
        onSurface: AppleColors.textPrimaryDark,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppleColors.textPrimaryDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: AppleColors.textPrimaryDark),
      ),
      dividerTheme: const DividerThemeData(
        color: AppleColors.separatorDark,
        thickness: 0.5,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppleColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        minLeadingWidth: 28,
        dense: false,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppleColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppleColors.primaryGreenDark,
        scaffoldBackgroundColor: AppleColors.backgroundDark,
        barBackgroundColor: AppleColors.frostedGlassDark,
      ),
    );
  }
}
