import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/apple_colors.dart';
import '../../../core/theme/apple_typography.dart';
import '../../../core/widgets/apple_button.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'onboarding_screen.dart';
import '../../settings/presentation/legal_document_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppleColors.backgroundDark
          : AppleColors.backgroundLight,
      body: SafeArea(
        child: ResponsiveContainer(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenBreakpoints.horizontalPadding(context),
            vertical: 16,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Official Kalore Apple-style App Icon with subtle glow
                Center(
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppleColors.primaryGreen.withValues(
                            alpha: isDark ? 0.32 : 0.28,
                          ),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/kalore_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
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
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(
                              CupertinoIcons.sparkles,
                              size: 52,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Kalore',
                  style: AppleTypography.largeTitle(isDark: isDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart AI Calorie & Nutrition Tracker.\nFoto piring makananmu, biarkan kecerdasan buatan Kalore menghitung kalori & nutrisinya secara otomatis.',
                  textAlign: TextAlign.center,
                  style: AppleTypography.body(isDark: isDark).copyWith(
                    color: isDark
                        ? AppleColors.textSecondaryDark
                        : AppleColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Feature highlights (Apple HIG style)
                _buildFeatureRow(
                  icon: CupertinoIcons.camera_viewfinder,
                  title: 'Scan Foto & Deskripsi AI',
                  subtitle:
                      'Analisis gramatur dan kalori instan dengan pemindai visual AI.',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  icon: CupertinoIcons.chart_pie_fill,
                  title: 'Modul Diet Terpersonalisasi',
                  subtitle:
                      'Target kalori cutting atau bulking yang disesuaikan profil tubuhmu.',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildFeatureRow(
                  icon: CupertinoIcons.tray_arrow_down,
                  title: '100% Offline-First & Bebas Login',
                  subtitle:
                      'Data tersimpan di perangkat, dilengkapi fitur Export/Import mandiri.',
                  isDark: isDark,
                ),
                const SizedBox(height: 32),

                // Action Buttons
                AppleButton(
                  backgroundColor: isDark
                      ? AppleColors.primaryGreenDark
                      : AppleColors.primaryGreen,
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Mulai Sebagai Tamu (Offline)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                AppleButton(
                  isSecondary: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const OnboardingScreen(isCloud: true),
                      ),
                    );
                  },
                  child: const Text('Masuk dengan Cloud Sync'),
                ),
                const SizedBox(height: 16),
                // Legal Footnote with clickable link
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) =>
                            const LegalDocumentScreen(initialTabIndex: 0),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Dengan melanjutkan, Anda menyetujui Ketentuan Layanan, Kebijakan Privasi, & Penafian Medis Kalore.',
                      textAlign: TextAlign.center,
                      style: AppleTypography.caption2(isDark: isDark).copyWith(
                        color: isDark
                            ? AppleColors.textSecondaryDark
                            : AppleColors.textSecondaryLight,
                        decoration: TextDecoration.underline,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? AppleColors.surfaceSecondaryDark
                : AppleColors.surfaceSecondaryLight,
            borderRadius: BorderRadius.circular(12),
            border: isDark
                ? Border.all(color: AppleColors.cardBorderDark, width: 0.5)
                : null,
          ),
          child: Icon(
            icon,
            color: isDark
                ? AppleColors.primaryGreenDark
                : AppleColors.primaryGreen,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppleTypography.headline(isDark: isDark)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppleTypography.caption(isDark: isDark)),
            ],
          ),
        ),
      ],
    );
  }
}
