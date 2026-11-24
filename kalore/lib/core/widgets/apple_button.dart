import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/apple_colors.dart';

/// Apple HIG + Emil Kowalski Design Engineering Button.
/// Provides zero-latency feedback (scales to 0.96 on press) with haptic feedback.
class AppleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isSecondary;
  final bool isDestructive;
  final double? width;
  final double height;

  const AppleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.borderRadius = 15.0,
    this.isSecondary = false,
    this.isDestructive = false,
    this.width,
    this.height = 50.0,
  });

  @override
  State<AppleButton> createState() => _AppleButtonState();
}

class _AppleButtonState extends State<AppleButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    HapticFeedback.selectionClick();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    if (widget.isDestructive) {
      bg = const Color(0xFFFF3B30).withValues(alpha: isDark ? 0.22 : 0.12);
      fg = const Color(0xFFFF3B30);
    } else if (widget.isSecondary) {
      bg = isDark
          ? AppleColors.surfaceSecondaryDark
          : AppleColors.surfaceSecondaryLight;
      fg = isDark ? Colors.white : Colors.black;
    } else {
      bg =
          widget.backgroundColor ??
          (isDark ? AppleColors.primaryGreenDark : AppleColors.primaryGreen);
      fg = widget.foregroundColor ?? Colors.white;
    }

    final isEnabled = widget.onPressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: isEnabled ? _handleTapDown : null,
      onTapUp: isEnabled ? _handleTapUp : null,
      onTapCancel: isEnabled ? _handleTapCancel : null,
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: isEnabled ? (_isPressed ? 0.88 : 1.0) : 0.4,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
