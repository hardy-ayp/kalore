import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/apple_colors.dart';
import '../../../core/theme/apple_typography.dart';
import '../../../core/widgets/activity_rings.dart';
import '../../../core/widgets/apple_button.dart';
import '../../../core/widgets/apple_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../home/presentation/main_nav_screen.dart';
import '../models/user_profile.dart';

class DietRevealScreen extends ConsumerWidget {
  final UserProfile profile;

  const DietRevealScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringSize = ScreenBreakpoints.isSmallPhone(context) ? 130.0 : 155.0;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Blueprint Nutrisi Siap!',
                style: AppleTypography.largeTitle(isDark: isDark),
              ),
              const SizedBox(height: 4),
              Text(
                profile.strategyTitle,
                style: AppleTypography.body(isDark: isDark).copyWith(
                  color: isDark
                      ? AppleColors.primaryGreenDark
                      : AppleColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: profile.targetPace == 'aggressive'
                          ? AppleColors.calorieOrange.withValues(alpha: 0.18)
                          : (isDark
                              ? AppleColors.primaryGreenDark.withValues(alpha: 0.18)
                              : AppleColors.primaryGreen.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: profile.targetPace == 'aggressive'
                            ? AppleColors.calorieOrange.withValues(alpha: 0.5)
                            : (isDark
                                ? AppleColors.primaryGreenDark.withValues(alpha: 0.4)
                                : AppleColors.primaryGreen.withValues(alpha: 0.3)),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      profile.targetPace == 'aggressive'
                          ? '⚡ Fase Atlet Agresif'
                          : '🌱 Fase Terukur Sehat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: profile.targetPace == 'aggressive'
                            ? AppleColors.calorieOrange
                            : (isDark
                                ? AppleColors.primaryGreenDark
                                : AppleColors.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${profile.currentWeightKg.round()}kg ➔ ${profile.targetWeightKg.round()}kg • ${profile.targetWeeks} Minggu',
                    style: AppleTypography.caption(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Calorie & Macro Target Card
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    AppleCard(
                      child: Column(
                        children: [
                          Center(
                            child: ActivityRings(
                              calorieProgress: 1.0,
                              proteinProgress: 1.0,
                              carbsProgress: 1.0,
                              size: ringSize,
                              strokeWidth: 13,
                              animateOnMount: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '${profile.targetCalories}',
                            style: AppleTypography.metricNumber(
                              size: 40,
                              isDark: isDark,
                              color: AppleColors.calorieOrange,
                            ),
                          ),
                          Text(
                            'Kcal Target Harian',
                            style: AppleTypography.callout(isDark: isDark),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMacroCol(
                                'Protein',
                                '${profile.targetProteinG}g',
                                AppleColors.proteinCoral,
                                isDark,
                              ),
                              _buildMacroCol(
                                'Karbohidrat',
                                '${profile.targetCarbsG}g',
                                AppleColors.carbsYellow,
                                isDark,
                              ),
                              _buildMacroCol(
                                'Lemak',
                                '${profile.targetFatG}g',
                                AppleColors.fatCyan,
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI Guidelines
                    if (profile.guidelines.isNotEmpty) ...[
                      Text(
                        'Saran Strategis AI',
                        style: AppleTypography.headline(isDark: isDark),
                      ),
                      const SizedBox(height: 8),
                      AppleCard(
                        child: Column(
                          children: profile.guidelines.map((g) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_alt_circle_fill,
                                    color: isDark
                                        ? AppleColors.primaryGreenDark
                                        : AppleColors.primaryGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      g,
                                      style: AppleTypography.body(
                                        isDark: isDark,
                                      ).copyWith(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Recommended Foods
                    if (profile.recommendedFoods.isNotEmpty) ...[
                      Text(
                        'Rekomendasi Makanan',
                        style: AppleTypography.headline(isDark: isDark),
                      ),
                      const SizedBox(height: 8),
                      AppleCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.recommendedFoods.map((f) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppleColors.surfaceSecondaryDark
                                    : AppleColors.surfaceSecondaryLight,
                                borderRadius: BorderRadius.circular(12),
                                border: isDark
                                    ? Border.all(
                                        color: AppleColors.cardBorderDark,
                                        width: 0.5,
                                      )
                                    : null,
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),

              AppleButton(
                backgroundColor: isDark
                    ? AppleColors.primaryGreenDark
                    : AppleColors.primaryGreen,
                onPressed: () async {
                  await ref
                      .read(userProfileProvider.notifier)
                      .updateProfile(profile);
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      CupertinoPageRoute(builder: (_) => const MainNavScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  'Mulai Melacak Hari Ini',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCol(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(value, style: AppleTypography.headline(isDark: isDark)),
        Text(label, style: AppleTypography.caption(isDark: isDark)),
      ],
    );
  }
}
