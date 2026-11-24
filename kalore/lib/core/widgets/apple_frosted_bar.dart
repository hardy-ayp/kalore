import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/apple_colors.dart';

/// Authentic Apple Frosted Glass (Materials) Container with BackdropFilter blur.
class AppleFrostedBar extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final Border? border;
  final Color? backgroundColor;

  const AppleFrostedBar({
    super.key,
    required this.child,
    this.blurSigma = 20.0,
    this.border,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? AppleColors.frostedGlassDark
        : AppleColors.frostedGlassLight;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBg,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}
