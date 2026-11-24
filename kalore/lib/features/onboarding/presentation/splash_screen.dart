import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/apple_colors.dart';
import '../../../core/theme/apple_typography.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../home/presentation/main_nav_screen.dart';
import 'welcome_screen.dart';

/// Luxurious Apple-style Preload & Splash Screen.
/// Replaces default flutter preload with a custom fluid spring animation,
/// subtle ambient glow, and seamless fade-transition into the app.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Emil Kowalski & Apple fluid spring: starts at 0.92, springs smoothly to 1.0
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Smooth navigation after preload animation completes
    _timer = Timer(const Duration(milliseconds: 2000), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    bool hasProfile = false;
    try {
      final storage = ref.read(storageServiceProvider);
      hasProfile = storage.getProfile() != null;
    } catch (_) {
      hasProfile = false;
    }

    final targetWidget = hasProfile
        ? const MainNavScreen()
        : const WelcomeScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) => targetWidget,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: fade, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppleColors.backgroundDark
          : AppleColors.backgroundLight,
      body: SafeArea(
        child: ResponsiveContainer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Luxurious Apple App Icon with ambient neon glow
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppleColors.primaryGreen.withValues(
                                  alpha: 0.35 * _glowAnimation.value,
                                ),
                                blurRadius: 40,
                                spreadRadius: 4,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: AppleColors.calorieOrange.withValues(
                                  alpha: 0.20 * _glowAnimation.value,
                                ),
                                blurRadius: 30,
                                offset: const Offset(-8, -8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(
                              'assets/images/kalore_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback elegant glass emblem if asset is loading
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppleColors.calorieOrange,
                                        AppleColors.primaryGreen,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      CupertinoIcons.sparkles,
                                      size: 64,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Typography
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            'Kalore',
                            style: AppleTypography.largeTitle(isDark: isDark)
                                .copyWith(
                                  fontSize: 36,
                                  letterSpacing: -1.0,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Smart AI Nutrition & Calorie Tracker',
                            style: AppleTypography.callout(isDark: isDark)
                                .copyWith(
                                  color: isDark
                                      ? AppleColors.textSecondaryDark
                                      : AppleColors.textSecondaryLight,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Minimal Apple Indicator at bottom
                    Opacity(
                      opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(
                              radius: 8,
                              color: isDark
                                  ? AppleColors.primaryGreenDark
                                  : AppleColors.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Menyiapkan data nutrisi...',
                              style: AppleTypography.caption(isDark: isDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
