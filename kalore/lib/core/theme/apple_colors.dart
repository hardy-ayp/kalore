import 'package:flutter/material.dart';

/// Apple HIG (Human Interface Guidelines) Authentic Semantic Color Palette.
/// Perfectly tuned for iOS 17/18 light and OLED dark mode.
class AppleColors {
  // Brand & Accent Colors
  static const Color primaryGreen = Color(0xFF34C759); // Apple System Green
  static const Color primaryGreenDark = Color(0xFF30D158);

  // Macro & Activity Ring Colors (Apple Fitness Authentic Palette)
  static const Color calorieOrange = Color(0xFFFF9500); // Calories Ring (Move)
  static const Color calorieOrangeGlow = Color(
    0xFFFF3B30,
  ); // Move Gradient Glow

  static const Color proteinCoral = Color(0xFFFF2D55); // Protein Coral/Pink
  static const Color proteinCoralGlow = Color(0xFFFA114F);

  static const Color carbsYellow = Color(0xFFFFCC00); // Carbs Warm Yellow
  static const Color carbsYellowGlow = Color(0xFFFFD60A);

  static const Color fatCyan = Color(0xFF32ADE6); // Healthy Fats Cyan/Blue
  static const Color fatCyanGlow = Color(0xFF64D2FF);

  static const Color waterBlue = Color(0xFF007AFF); // Apple System Blue
  static const Color waterBlueDark = Color(0xFF0A84FF);

  // Light Mode Surfaces (Apple Grouped Tables & Insets)
  static const Color backgroundLight = Color(
    0xFFF2F2F7,
  ); // systemGroupedBackground
  static const Color surfaceLight = Color(
    0xFFFFFFFF,
  ); // secondarySystemGroupedBackground
  static const Color surfaceSecondaryLight = Color(
    0xFFE5E5EA,
  ); // tertiarySystemGroupedBackground
  static const Color textPrimaryLight = Color(0xFF000000); // label
  static const Color textSecondaryLight = Color(0xFF8E8E93); // secondaryLabel
  static const Color textTertiaryLight = Color(0xFFC7C7CC); // tertiaryLabel

  // Dark Mode Surfaces (OLED True Black & Apple Dark Insets)
  static const Color backgroundDark = Color(0xFF000000); // pure OLED black
  static const Color surfaceDark = Color(
    0xFF1C1C1E,
  ); // systemGray6 dark (cards)
  static const Color surfaceSecondaryDark = Color(
    0xFF2C2C2E,
  ); // systemGray5 dark
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // label
  static const Color textSecondaryDark = Color(0xFF8E8E93); // secondaryLabel
  static const Color textTertiaryDark = Color(0xFF48484A); // tertiaryLabel

  // Borders & Hairline Separators (Apple 0.5pt Hairline equivalent)
  static const Color separatorLight = Color(0x293C3C43); // 16% opacity
  static const Color separatorDark = Color(0x42545458); // 26% opacity
  static const Color cardBorderDark = Color(
    0x1FFFFFFF,
  ); // Subtle edge highlight on true black

  // Frosted Glass Tints with Real Blur
  static const Color frostedGlassLight = Color(0xD9F2F2F7); // 85% opacity
  static const Color frostedGlassDark = Color(0xD91C1C1E); // 85% opacity
  static const Color frostedGlassNavbarLight = Color(0xCCFFFFFF);
  static const Color frostedGlassNavbarDark = Color(0xCC000000);
}
