import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/apple_colors.dart';
import '../../../core/theme/apple_typography.dart';
import '../../../core/widgets/apple_button.dart';
import '../../../core/widgets/apple_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../onboarding/models/user_profile.dart';

class DietPlanScreen extends ConsumerStatefulWidget {
  const DietPlanScreen({super.key});

  @override
  ConsumerState<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends ConsumerState<DietPlanScreen> {
  bool _isRecalculating = false;

  Future<void> _recalculatePlan(UserProfile profile) async {
    HapticFeedback.lightImpact();
    setState(() => _isRecalculating = true);
    try {
      final gemini = ref.read(geminiServiceProvider);
      final updated = await gemini.generateDietPlan(profile);
      await ref.read(userProfileProvider.notifier).updateProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rencana diet berhasil dioptimalkan oleh AI!'),
            backgroundColor: AppleColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: CupertinoColors.destructiveRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRecalculating = false);
    }
  }

  void _showEditGoalModal(UserProfile profile) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double tempTargetWeight = profile.targetWeightKg;
    int tempTargetWeeks = profile.targetWeeks;
    String tempGoal = profile.goal;

    final goals = [
      {'key': 'cutting_aggressive', 'title': '⚡ Cutting Agresif Atlet'},
      {'key': 'cutting', 'title': '📉 Cutting Bertahap Sehat'},
      {'key': 'maintenance', 'title': '⚖️ Maintenance Seimbang'},
      {'key': 'bulking', 'title': '📈 Lean Bulking Terukur'},
      {'key': 'bulking_aggressive', 'title': '💥 Bulking Agresif Atlet'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final delta = tempTargetWeight - profile.currentWeightKg;
          final rate = delta.abs() / (tempTargetWeeks > 0 ? tempTargetWeeks : 1);
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 16,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppleColors.surfaceSecondaryDark
                  : AppleColors.surfaceSecondaryLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ubah Target & Durasi',
                        style: AppleTypography.title2(isDark: isDark),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(CupertinoIcons.xmark_circle_fill,
                            size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Target Berat: ${tempTargetWeight.round()} kg',
                    style: AppleTypography.headline(isDark: isDark),
                  ),
                  CupertinoSlider(
                    value: tempTargetWeight,
                    min: 35,
                    max: 180,
                    activeColor: isDark
                        ? AppleColors.primaryGreenDark
                        : AppleColors.primaryGreen,
                    onChanged: (v) =>
                        setModalState(() => tempTargetWeight = v),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Target Waktu: $tempTargetWeeks Minggu (${(tempTargetWeeks / 4).toStringAsFixed(1)} Bulan)',
                    style: AppleTypography.headline(isDark: isDark),
                  ),
                  Text(
                    'Estimasi Kecepatan: ${delta < 0 ? '-' : '+'}${rate.toStringAsFixed(1)} kg / minggu',
                    style: AppleTypography.caption(isDark: isDark).copyWith(
                      color: rate >= 1.2
                          ? AppleColors.calorieOrange
                          : (isDark
                              ? AppleColors.primaryGreenDark
                              : AppleColors.primaryGreen),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoSlider(
                    value: tempTargetWeeks.toDouble(),
                    min: 1,
                    max: 24,
                    divisions: 23,
                    activeColor: isDark
                        ? AppleColors.primaryGreenDark
                        : AppleColors.primaryGreen,
                    onChanged: (v) =>
                        setModalState(() => tempTargetWeeks = v.round()),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Pilihan Fase & Strategi:',
                    style: AppleTypography.caption(isDark: isDark),
                  ),
                  const SizedBox(height: 8),
                  ...goals.map((g) {
                    final isSel = tempGoal == g['key'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: AppleCard(
                        backgroundColor: isSel
                            ? AppleColors.primaryGreen.withValues(
                                alpha: isDark ? 0.25 : 0.15,
                              )
                            : null,
                        border: isSel
                            ? Border.all(
                                color: isDark
                                    ? AppleColors.primaryGreenDark
                                    : AppleColors.primaryGreen,
                                width: 1.5,
                              )
                            : null,
                        onTap: () =>
                            setModalState(() => tempGoal = g['key']!),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                g['title']!,
                                style: AppleTypography.headline(isDark: isDark)
                                    .copyWith(fontSize: 14),
                              ),
                            ),
                            if (isSel)
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: isDark
                                    ? AppleColors.primaryGreenDark
                                    : AppleColors.primaryGreen,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  AppleButton(
                    backgroundColor: isDark
                        ? AppleColors.primaryGreenDark
                        : AppleColors.primaryGreen,
                    onPressed: () {
                      Navigator.pop(context);
                      final updated = profile.copyWith(
                        targetWeightKg: tempTargetWeight,
                        targetWeeks: tempTargetWeeks,
                        goal: tempGoal,
                        targetPace: (tempGoal.contains('aggressive') ||
                                (delta.abs() / tempTargetWeeks) >= 1.2)
                            ? 'aggressive'
                            : 'moderate',
                      );
                      _recalculatePlan(updated);
                    },
                    child: const Text(
                      'Terapkan & Hitung Ulang Blueprint',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final isSmall = ScreenBreakpoints.isSmallPhone(context);

    if (profile == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppleColors.backgroundDark
            : AppleColors.backgroundLight,
        body: Center(
          child: Text(
            'Profil belum dibuat.',
            style: AppleTypography.body(isDark: isDark),
          ),
        ),
      );
    }

    final bmr = UserProfile.calculateBmr(
      gender: profile.gender,
      weightKg: profile.currentWeightKg,
      heightCm: profile.heightCm,
      age: profile.age,
    );
    final tdee = UserProfile.calculateTdee(
      bmr: bmr,
      activityLevel: profile.activityLevel,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppleColors.backgroundDark
          : AppleColors.backgroundLight,
      body: SafeArea(
        child: ResponsiveContainer(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenBreakpoints.horizontalPadding(context),
            vertical: 12,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Text(
                'Modul Diet AI',
                style: AppleTypography.largeTitle(isDark: isDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Strategi & Target Kalori Terpersonalisasi',
                style: AppleTypography.callout(isDark: isDark),
              ),
              const SizedBox(height: 18),

              // Active Strategy Badge Card
              AppleCard(
                backgroundColor: AppleColors.primaryGreen.withValues(
                  alpha: isDark ? 0.16 : 0.10,
                ),
                border: Border.all(
                  color:
                      (isDark
                              ? AppleColors.primaryGreenDark
                              : AppleColors.primaryGreen)
                          .withValues(alpha: 0.35),
                  width: 1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.sparkles,
                          color: isDark
                              ? AppleColors.primaryGreenDark
                              : AppleColors.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile.strategyTitle,
                            style: AppleTypography.headline(isDark: isDark)
                                .copyWith(
                                  color: isDark
                                      ? AppleColors.primaryGreenDark
                                      : AppleColors.primaryGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Berat: ${profile.currentWeightKg.round()}kg ➔ Target: ${profile.targetWeightKg.round()}kg • ${profile.targetWeeks} Minggu',
                            style: AppleTypography.body(
                              isDark: isDark,
                            ).copyWith(fontSize: 13),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () => _showEditGoalModal(profile),
                          child: Row(
                            children: [
                              Text(
                                'Ubah',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppleColors.primaryGreenDark
                                      : AppleColors.primaryGreen,
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_forward,
                                size: 14,
                                color: isDark
                                    ? AppleColors.primaryGreenDark
                                    : AppleColors.primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Target Numbers Card
              AppleCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          '${profile.targetCalories}',
                          'Kcal Target',
                          AppleColors.calorieOrange,
                          isDark,
                          isSmall,
                        ),
                        _buildStatItem(
                          '${profile.targetProteinG}g',
                          'Protein',
                          AppleColors.proteinCoral,
                          isDark,
                          isSmall,
                        ),
                        _buildStatItem(
                          '${profile.targetCarbsG}g',
                          'Karbo',
                          AppleColors.carbsYellow,
                          isDark,
                          isSmall,
                        ),
                        _buildStatItem(
                          '${profile.targetFatG}g',
                          'Lemak',
                          AppleColors.fatCyan,
                          isDark,
                          isSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BMR (Basal Metabolisme):',
                          style: AppleTypography.caption(isDark: isDark),
                        ),
                        Text(
                          '${bmr.round()} kcal',
                          style: AppleTypography.headline(
                            isDark: isDark,
                          ).copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TDEE (Total Energi Harian):',
                          style: AppleTypography.caption(isDark: isDark),
                        ),
                        Text(
                          '${tdee.round()} kcal',
                          style: AppleTypography.headline(
                            isDark: isDark,
                          ).copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Guidelines
              if (profile.guidelines.isNotEmpty) ...[
                Text(
                  'Panduan Nutrisi dari AI',
                  style: AppleTypography.title2(isDark: isDark),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 22),
              ],

              // Recommended Foods
              if (profile.recommendedFoods.isNotEmpty) ...[
                Text(
                  'Rekomendasi Pilihan Menu',
                  style: AppleTypography.title2(isDark: isDark),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 24),
              ],

              // Edit Target & Duration Button
              AppleButton(
                backgroundColor: isDark
                    ? AppleColors.surfaceSecondaryDark
                    : AppleColors.surfaceSecondaryLight,
                onPressed: () => _showEditGoalModal(profile),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sesuaikan Target & Kecepatan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Refresh Diet Plan with Gemini
              AppleButton(
                backgroundColor: isDark
                    ? AppleColors.primaryGreenDark
                    : AppleColors.primaryGreen,
                onPressed: _isRecalculating
                    ? null
                    : () => _recalculatePlan(profile),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRecalculating) ...[
                      const CupertinoActivityIndicator(color: Colors.white),
                      const SizedBox(width: 8),
                    ] else ...[
                      const Icon(
                        CupertinoIcons.arrow_2_circlepath,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isRecalculating
                          ? 'Menyusun Ulang...'
                          : 'Konsultasikan Ulang Rencana',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String val,
    String label,
    Color color,
    bool isDark,
    bool isSmall,
  ) {
    return Column(
      children: [
        Text(
          val,
          style: AppleTypography.headline(isDark: isDark).copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: isSmall ? 15 : 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppleTypography.caption(
            isDark: isDark,
          ).copyWith(fontSize: isSmall ? 11 : 12),
        ),
      ],
    );
  }
}
