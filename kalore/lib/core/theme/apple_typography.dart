import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'apple_colors.dart';

/// Apple HIG inspired typography styles.
/// Uses Plus Jakarta Sans (with Apple San Francisco optical proportions)
/// and Outfit for Apple Health/Fitness metric numbers.
class AppleTypography {
  static TextStyle largeTitle({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color:
            color ??
            (isDark
                ? AppleColors.textPrimaryDark
                : AppleColors.textPrimaryLight),
      );

  static TextStyle title1({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color:
            color ??
            (isDark
                ? AppleColors.textPrimaryDark
                : AppleColors.textPrimaryLight),
      );

  static TextStyle title2({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color:
            color ??
            (isDark
                ? AppleColors.textPrimaryDark
                : AppleColors.textPrimaryLight),
      );

  static TextStyle title3({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color:
            color ??
            (isDark
                ? AppleColors.textPrimaryDark
                : AppleColors.textPrimaryLight),
      );

  static TextStyle headline({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color:
            color ??
            (isDark
                ? AppleColors.textPrimaryDark
                : AppleColors.textPrimaryLight),
      );

  static TextStyle body({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.35,
        color:
            color ??
            (isDark
                ? AppleColors.textPrimaryDark
                : AppleColors.textPrimaryLight),
      );

  static TextStyle subheadline({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color:
            color ??
            (isDark
                ? AppleColors.textSecondaryDark
                : AppleColors.textSecondaryLight),
      );

  static TextStyle callout({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.15,
        color:
            color ??
            (isDark
                ? AppleColors.textSecondaryDark
                : AppleColors.textSecondaryLight),
      );

  static TextStyle footnote({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color:
            color ??
            (isDark
                ? AppleColors.textSecondaryDark
                : AppleColors.textSecondaryLight),
      );

  static TextStyle caption({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        color:
            color ??
            (isDark
                ? AppleColors.textSecondaryDark
                : AppleColors.textSecondaryLight),
      );

  static TextStyle caption2({bool isDark = false, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color:
            color ??
            (isDark
                ? AppleColors.textSecondaryDark
                : AppleColors.textSecondaryLight),
      );

  // Big Rounded Numbers (Apple Health & Fitness rings style)
  static TextStyle metricNumber({
    double size = 32,
    bool isDark = false,
    Color? color,
  }) => GoogleFonts.outfit(
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color:
        color ??
        (isDark ? AppleColors.textPrimaryDark : AppleColors.textPrimaryLight),
  );
}
