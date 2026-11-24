import 'package:flutter/material.dart';

/// Screen breakpoint helpers for responsive layouts across phone and tablet dimensions.
class ScreenBreakpoints {
  /// Extra small phones (e.g. iPhone SE 1st gen, small Androids < 360px)
  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  /// Compact phone width (< 400px)
  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 400;

  /// Tablet or Wide viewport (>= 600px)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  /// Large tablet or desktop (>= 900px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  /// Adaptive horizontal padding based on screen size
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12.0;
    if (width < 400) return 16.0;
    return 20.0;
  }

  /// Adaptive activity rings diameter
  static double activityRingDiameter(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 110.0;
    if (width < 400) return 125.0;
    if (width >= 600) return 160.0;
    return 135.0;
  }
}

/// A responsive container that centers content on tablets/wide screens
/// with an optimal Apple reading width constraint (maxWidth: 640).
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 640.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: ScreenBreakpoints.horizontalPadding(context),
              ),
          child: child,
        ),
      ),
    );
  }
}
