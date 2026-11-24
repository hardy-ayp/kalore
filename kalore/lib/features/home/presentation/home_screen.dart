import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/apple_colors.dart';
import '../../../core/theme/apple_typography.dart';
import '../../../core/widgets/activity_rings.dart';
import '../../../core/widgets/apple_button.dart';
import '../../../core/widgets/apple_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../food_logging/models/food_entry.dart';
import '../../food_logging/presentation/scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showWaterModal(BuildContext context, WidgetRef ref, int currentMl, int targetMl, bool isDark) {
    HapticFeedback.lightImpact();
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppleColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(CupertinoIcons.drop_fill, color: AppleColors.waterBlue, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Catat Asupan Air Minum',
                    style: AppleTypography.headline(isDark: isDark),
                  ),
                  const Spacer(),
                  Text(
                    '${(currentMl / 1000).toStringAsFixed(1)} / ${(targetMl / 1000).toStringAsFixed(1)} L',
                    style: AppleTypography.callout(isDark: isDark).copyWith(
                      color: AppleColors.waterBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text('PILIH TAMBAHAN CEPAT', style: AppleTypography.caption2(isDark: isDark)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [150, 250, 330, 500, 600, 1000].map((ml) {
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    color: AppleColors.waterBlue.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(dailyWaterProvider.notifier).addWater(ml);
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      '+$ml ml',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppleColors.waterBlueDark : AppleColors.waterBlue,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              Text('INPUT MANUAL JUMLAH (ML)', style: AppleTypography.caption2(isDark: isDark)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: customController,
                      keyboardType: TextInputType.number,
                      placeholder: 'Misal: 450',
                      padding: const EdgeInsets.all(12),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: BoxDecoration(
                        color: isDark ? AppleColors.surfaceSecondaryDark : AppleColors.surfaceSecondaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppleButton(
                    width: 100,
                    height: 44,
                    backgroundColor: AppleColors.waterBlue,
                    onPressed: () {
                      final val = int.tryParse(customController.text.trim());
                      if (val != null && val > 0) {
                        HapticFeedback.lightImpact();
                        ref.read(dailyWaterProvider.notifier).addWater(val);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(dailyWaterProvider.notifier).addWater(-250);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      '-250 ml (Koreksi)',
                      style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(dailyWaterProvider.notifier).reset();
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Reset Hari Ini',
                      style: TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMealOptions(BuildContext context, String mealType, String title) {
    HapticFeedback.lightImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Tambah Makanan - $title'),
        message: const Text('Pilih metode pencatatan nutrisi yang kamu inginkan'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => ScanScreen(initialTab: 0, initialMealType: mealType),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera_fill, size: 18),
                SizedBox(width: 8),
                Text('Pindai Foto AI'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => ScanScreen(initialTab: 1, initialMealType: mealType),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.sparkles, size: 18),
                SizedBox(width: 8),
                Text('Deskripsi Teks AI'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => ScanScreen(initialTab: 2, initialMealType: mealType),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 18),
                SizedBox(width: 8),
                Text('Input Manual Langsung'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final entries = ref.watch(dailyFoodEntriesProvider);
    final waterMl = ref.watch(dailyWaterProvider);

    // Compute consumed macros
    final totalCalories = entries.fold(0, (sum, e) => sum + e.calories);
    final totalProtein = entries.fold(0.0, (sum, e) => sum + e.proteinG);
    final totalCarbs = entries.fold(0.0, (sum, e) => sum + e.carbsG);
    final totalFat = entries.fold(0.0, (sum, e) => sum + e.fatG);

    final targetCalories = profile?.targetCalories ?? 2000;
    final targetProtein = profile?.targetProteinG ?? 130;
    final targetCarbs = profile?.targetCarbsG ?? 220;
    final targetFat = profile?.targetFatG ?? 65;

    final remainingCalories = (targetCalories - totalCalories).clamp(0, 9999);

    final calorieProgress = totalCalories / targetCalories;
    final proteinProgress = totalProtein / targetProtein;
    final carbsProgress = totalCarbs / targetCarbs;

    final ringSize = ScreenBreakpoints.activityRingDiameter(context);
    final isSmall = ScreenBreakpoints.isSmallPhone(context);

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
              // Top Date Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, d MMMM',
                            'id_ID',
                          ).format(selectedDate).toUpperCase(),
                          style: AppleTypography.caption(isDark: isDark)
                              .copyWith(
                                color: isDark
                                    ? AppleColors.primaryGreenDark
                                    : AppleColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ringkasan Nutrisi',
                          style: AppleTypography.largeTitle(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref.read(mainNavIndexProvider.notifier).setIndex(1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppleColors.primaryGreenDark
                                    : AppleColors.primaryGreen)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (isDark
                                      ? AppleColors.primaryGreenDark
                                      : AppleColors.primaryGreen)
                                  .withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.chart_bar_alt_fill,
                                size: 12,
                                color: isDark
                                    ? AppleColors.primaryGreenDark
                                    : AppleColors.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Rekap',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppleColors.primaryGreenDark
                                      : AppleColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
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
                          (profile?.isGuest ?? true) ? 'Tamu' : 'Cloud',
                          style: AppleTypography.caption(isDark: isDark).copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero Ring & Calorie Overview Card
              AppleCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SISA KALORI',
                              style: AppleTypography.caption2(
                                isDark: isDark,
                              ).copyWith(letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$remainingCalories',
                              style: AppleTypography.largeTitle(
                                isDark: isDark,
                              ).copyWith(
                                fontSize: isSmall ? 36 : 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                              ),
                            ),
                            Text(
                              'dari target $targetCalories kkal',
                              style: AppleTypography.caption(isDark: isDark),
                            ),
                          ],
                        ),
                        ActivityRings(
                          size: ringSize,
                          strokeWidth: isSmall ? 9 : 12,
                          calorieProgress: calorieProgress,
                          proteinProgress: proteinProgress,
                          carbsProgress: carbsProgress,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 0.5),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroProgress(
                          'Protein',
                          totalProtein.round(),
                          targetProtein,
                          AppleColors.proteinCoral,
                          isDark,
                          isSmall,
                        ),
                        _buildMacroProgress(
                          'Karbohidrat',
                          totalCarbs.round(),
                          targetCarbs,
                          AppleColors.carbsYellow,
                          isDark,
                          isSmall,
                        ),
                        _buildMacroProgress(
                          'Lemak',
                          totalFat.round(),
                          targetFat,
                          AppleColors.fatCyan,
                          isDark,
                          isSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Meal Log Header & Quick Scan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'JADWAL MAKAN',
                    style: AppleTypography.caption2(
                      isDark: isDark,
                    ).copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.camera_viewfinder,
                          size: 16,
                          color: isDark
                              ? AppleColors.primaryGreenDark
                              : AppleColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scan Cepat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppleColors.primaryGreenDark
                                : AppleColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const ScanScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Meal Sections
              _buildMealBucket(
                title: 'Sarapan',
                icon: '🍳',
                mealType: 'breakfast',
                entries: entries.where((e) => e.mealType == 'breakfast').toList(),
                context: context,
                ref: ref,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildMealBucket(
                title: 'Makan Siang',
                icon: '🍗',
                mealType: 'lunch',
                entries: entries.where((e) => e.mealType == 'lunch').toList(),
                context: context,
                ref: ref,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildMealBucket(
                title: 'Makan Malam',
                icon: '🍲',
                mealType: 'dinner',
                entries: entries.where((e) => e.mealType == 'dinner').toList(),
                context: context,
                ref: ref,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildMealBucket(
                title: 'Camilan',
                icon: '☕',
                mealType: 'snack',
                entries: entries.where((e) => e.mealType == 'snack').toList(),
                context: context,
                ref: ref,
                isDark: isDark,
              ),

              const SizedBox(height: 22),

              // Water Tracker Card with Quick and Manual Input
              AppleCard(
                onTap: () => _showWaterModal(context, ref, waterMl, profile?.targetWaterMl ?? 2500, isDark),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppleColors.waterBlue.withValues(
                          alpha: isDark ? 0.22 : 0.14,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.drop_fill,
                        color: AppleColors.waterBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asupan Air Minum',
                            style: AppleTypography.headline(isDark: isDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(waterMl / 1000).toStringAsFixed(1)} / ${(profile?.targetWaterMl ?? 2500) / 1000} Liter',
                            style: AppleTypography.caption(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    // Quick +250ml
                    AppleButton(
                      width: 74,
                      height: 36,
                      padding: EdgeInsets.zero,
                      backgroundColor: AppleColors.waterBlue,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref.read(dailyWaterProvider.notifier).addWater(250);
                      },
                      child: const Text(
                        '+250ml',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Manual Modal Opener
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showWaterModal(context, ref, waterMl, profile?.targetWaterMl ?? 2500, isDark),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppleColors.surfaceSecondaryDark : AppleColors.surfaceSecondaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.ellipsis,
                          color: AppleColors.waterBlue,
                          size: 16,
                        ),
                      ),
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

  Widget _buildMacroProgress(
    String label,
    int current,
    int target,
    Color color,
    bool isDark,
    bool isSmall,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              '$current / ${target}g',
              style: AppleTypography.headline(isDark: isDark).copyWith(
                fontSize: isSmall ? 13 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppleTypography.caption(
            isDark: isDark,
          ).copyWith(fontSize: isSmall ? 11 : 12),
        ),
      ],
    );
  }

  Widget _buildMealBucket({
    required String title,
    required String icon,
    required String mealType,
    required List<FoodEntry> entries,
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
  }) {
    final bucketCalories = entries.fold(0, (sum, e) => sum + e.calories);

    return AppleCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppleColors.surfaceSecondaryDark
                      : AppleColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppleTypography.headline(isDark: isDark),
                ),
              ),
              Text(
                bucketCalories > 0 ? '$bucketCalories kcal' : 'Belum diisi',
                style: AppleTypography.callout(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w600,
                  color: bucketCalories > 0
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark
                            ? AppleColors.textSecondaryDark
                            : AppleColors.textSecondaryLight),
                ),
              ),
              const SizedBox(width: 6),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showAddMealOptions(context, mealType, title),
                child: Icon(
                  CupertinoIcons.plus_circle_fill,
                  color: isDark
                      ? AppleColors.primaryGreenDark
                      : AppleColors.primaryGreen,
                  size: 24,
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const Divider(),
            ...entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: AppleTypography.body(isDark: isDark)
                                .copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.calories} kcal • ${entry.proteinG.round()}g Prot • ${entry.carbsG.round()}g Carb • ${entry.fatG.round()}g Lemak',
                            style: AppleTypography.caption(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => ref
                          .read(dailyFoodEntriesProvider.notifier)
                          .removeEntry(entry.id),
                      child: const Icon(
                        CupertinoIcons.trash,
                        size: 18,
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
