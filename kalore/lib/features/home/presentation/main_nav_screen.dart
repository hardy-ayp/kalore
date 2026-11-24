import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/apple_colors.dart';
import '../../diet_plan/presentation/diet_plan_screen.dart';
import '../../food_logging/presentation/scan_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'home_screen.dart';

/// Main Navigation Screen with Apple Fluid Gesture Navigation.
/// Supports smooth horizontal swipe/drag between 5 pages with iOS rubber-band physics,
/// seamless tab bar synchronization, Riverpod tab index integration, and haptic feedback.
class MainNavScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    ref.read(mainNavIndexProvider.notifier).setIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<int>(mainNavIndexProvider, (prev, next) {
      if (next != _currentIndex && _pageController.hasClients) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppleColors.backgroundDark
          : AppleColors.backgroundLight,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        onPageChanged: (index) {
          if (_currentIndex != index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
            ref.read(mainNavIndexProvider.notifier).setIndex(index);
          }
        },
        children: const [
          HomeScreen(),
          HistoryScreen(),
          ScanScreen(),
          DietPlanScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppleColors.frostedGlassDark
                  : AppleColors.frostedGlassLight,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppleColors.separatorDark
                      : AppleColors.separatorLight,
                  width: 0.5,
                ),
              ),
            ),
            child: CupertinoTabBar(
              backgroundColor: Colors.transparent,
              activeColor: isDark
                  ? AppleColors.primaryGreenDark
                  : AppleColors.primaryGreen,
              inactiveColor: isDark
                  ? AppleColors.textSecondaryDark
                  : AppleColors.textSecondaryLight,
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              iconSize: 22,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.circle_grid_hex),
                  activeIcon: Icon(CupertinoIcons.circle_grid_hex_fill),
                  label: 'Ringkasan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.chart_bar_alt_fill),
                  activeIcon: Icon(CupertinoIcons.chart_bar_square_fill),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.camera_viewfinder),
                  label: 'Scan AI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.sparkles),
                  label: 'Rencana AI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.gear),
                  activeIcon: Icon(CupertinoIcons.gear_solid),
                  label: 'Pengaturan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
