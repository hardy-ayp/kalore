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
import '../../food_logging/models/food_entry.dart';

/// Riwayat & Rekap Nutrisi Screen.
/// Provides comprehensive historical tracking, weekly/monthly calorie trends,
/// macro compliance, daily logs, and data export.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedPeriod = '7d'; // '7d', '30d', 'all'
  String _searchQuery = '';
  DateTime? _selectedInspectDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onInspectDay(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedInspectDate != null &&
          _selectedInspectDate!.year == date.year &&
          _selectedInspectDate!.month == date.month &&
          _selectedInspectDate!.day == date.day) {
        _selectedInspectDate = null;
      } else {
        _selectedInspectDate = date;
      }
    });
  }

  void _openDateInDashboard(DateTime date) {
    HapticFeedback.lightImpact();
    ref.read(selectedDateProvider.notifier).setDate(date);
    ref.read(mainNavIndexProvider.notifier).setIndex(0);
  }

  Future<void> _confirmDeleteEntry(FoodEntry entry) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Hapus Catatan Makanan?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${entry.name}" dari riwayat? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(dailyFoodEntriesProvider.notifier).removeEntry(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Catatan "${entry.name}" berhasil dihapus'),
            backgroundColor: isDark
                ? AppleColors.surfaceSecondaryDark
                : AppleColors.surfaceDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    HapticFeedback.selectionClick();
    final storage = ref.read(storageServiceProvider);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Ekspor & Berbagi Riwayat Nutrisi'),
        message: const Text(
          'Simpan atau salin data riwayat dan rencana nutrisi kamu untuk arsip pribadi atau pemulihan.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final file = await storage.exportToFile();
                if (mounted) {
                  _showExportSuccessDialog(file.path);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengekspor file: $e')),
                  );
                }
              }
            },
            child: const Text('Simpan File Cadangan (.JSON)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              final jsonStr = storage.exportDataAsJson();
              Clipboard.setData(ClipboardData(text: jsonStr));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Data riwayat lengkap berhasil disalin ke clipboard!',
                    ),
                    backgroundColor: AppleColors.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text('Salin Data ke Clipboard'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
      ),
    );
  }

  void _showExportSuccessDialog(String path) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ekspor Berhasil!'),
        content: Text(
          'File cadangan tersimpan di:\n$path\n\nKamu dapat menggunakan file ini di menu Pengaturan untuk memulihkan data kapan saja.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allEntries = ref.watch(allFoodEntriesProvider);
    final profile = ref.watch(userProfileProvider);
    final storage = ref.watch(storageServiceProvider);

    final targetCalories = profile?.targetCalories ?? 2000;
    final targetProtein = profile?.targetProteinG ?? 130;
    final targetCarbs = profile?.targetCarbsG ?? 220;
    final targetFat = profile?.targetFatG ?? 65;

    // Filter by Period
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<FoodEntry> filteredEntries = allEntries;
    DateTime startDate;

    if (_selectedPeriod == '7d') {
      startDate = today.subtract(const Duration(days: 6));
      filteredEntries = allEntries.where((e) {
        final d = DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day);
        return d.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            d.isBefore(today.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedPeriod == '30d') {
      startDate = today.subtract(const Duration(days: 29));
      filteredEntries = allEntries.where((e) {
        final d = DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day);
        return d.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            d.isBefore(today.add(const Duration(days: 1)));
      }).toList();
    } else {
      startDate = allEntries.isNotEmpty
          ? DateTime(
              allEntries.last.loggedAt.year,
              allEntries.last.loggedAt.month,
              allEntries.last.loggedAt.day,
            )
          : today.subtract(const Duration(days: 6));
    }

    // Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filteredEntries = filteredEntries.where((e) {
        final matchTitle = e.name.toLowerCase().contains(q);
        final matchItems = e.items.any((i) => i.name.toLowerCase().contains(q));
        return matchTitle || matchItems;
      }).toList();
    }

    // Group Entries by Day
    final Map<DateTime, List<FoodEntry>> entriesByDay = {};
    for (final entry in filteredEntries) {
      final dayKey = DateTime(
        entry.loggedAt.year,
        entry.loggedAt.month,
        entry.loggedAt.day,
      );
      entriesByDay.putIfAbsent(dayKey, () => []).add(entry);
    }

    // Compute Days List for Chart & Timeline
    final List<DateTime> chartDays = [];
    final int chartSpan = _selectedPeriod == '7d' ? 7 : (_selectedPeriod == '30d' ? 14 : 7);
    for (int i = chartSpan - 1; i >= 0; i--) {
      chartDays.add(today.subtract(Duration(days: i)));
    }

    // Metrics Calculation
    final trackedDaysCount = entriesByDay.keys.length;
    double totalCaloriesSum = 0;
    double totalProteinSum = 0;
    double totalCarbsSum = 0;
    double totalFatSum = 0;
    int totalWaterSum = 0;
    int onTargetDaysCount = 0;

    for (final day in entriesByDay.keys) {
      final dayEntries = entriesByDay[day]!;
      final dayCal = dayEntries.fold<int>(0, (acc, e) => acc + e.calories);
      final dayP = dayEntries.fold<double>(0, (acc, e) => acc + e.proteinG);
      final dayC = dayEntries.fold<double>(0, (acc, e) => acc + e.carbsG);
      final dayF = dayEntries.fold<double>(0, (acc, e) => acc + e.fatG);
      final dayWater = storage.getWaterIntake(day);

      totalCaloriesSum += dayCal;
      totalProteinSum += dayP;
      totalCarbsSum += dayC;
      totalFatSum += dayF;
      totalWaterSum += dayWater;

      // On target if within 15% of calorie goal
      if (dayCal >= (targetCalories * 0.85) && dayCal <= (targetCalories * 1.15)) {
        onTargetDaysCount++;
      }
    }

    final double avgCalories = trackedDaysCount > 0
        ? totalCaloriesSum / trackedDaysCount
        : 0;
    final double avgProtein = trackedDaysCount > 0
        ? totalProteinSum / trackedDaysCount
        : 0;
    final double avgCarbs = trackedDaysCount > 0
        ? totalCarbsSum / trackedDaysCount
        : 0;
    final double avgFat = trackedDaysCount > 0
        ? totalFatSum / trackedDaysCount
        : 0;
    final double avgWater = trackedDaysCount > 0
        ? totalWaterSum / trackedDaysCount
        : 0;

    final int compliancePercent = trackedDaysCount > 0
        ? ((onTargetDaysCount / trackedDaysCount) * 100).round()
        : 0;

    // Calculate Active Streak
    int currentStreak = 0;
    DateTime checkDate = today;
    while (true) {
      final hasLog = allEntries.any((e) =>
          e.loggedAt.year == checkDate.year &&
          e.loggedAt.month == checkDate.month &&
          e.loggedAt.day == checkDate.day);
      if (hasLog) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // If today not yet logged, check if yesterday was logged to not break streak early
        if (checkDate == today) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }

    // Sorted Days for Timeline Feed (Recent first)
    final sortedDays = entriesByDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: isDark
          ? AppleColors.backgroundDark
          : AppleColors.backgroundLight,
      body: SafeArea(
        child: ResponsiveContainer(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenBreakpoints.horizontalPadding(context),
            vertical: 8,
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Apple Navigation Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat & Rekap',
                            style: AppleTypography.largeTitle(isDark: isDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tren Nutrisi, Kepatuhan & Log Historis',
                            style: AppleTypography.caption(isDark: isDark),
                          ),
                        ],
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _exportData,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppleColors.surfaceSecondaryDark
                                : AppleColors.surfaceSecondaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.square_arrow_up,
                            color: isDark
                                ? AppleColors.primaryGreenDark
                                : AppleColors.primaryGreen,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Segmented Period Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      backgroundColor: isDark
                          ? AppleColors.surfaceSecondaryDark
                          : AppleColors.surfaceSecondaryLight,
                      thumbColor: isDark
                          ? AppleColors.surfaceDark
                          : Colors.white,
                      groupValue: _selectedPeriod,
                      onValueChanged: (val) {
                        if (val != null) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedPeriod = val;
                            _selectedInspectDate = null;
                          });
                        }
                      },
                      children: const {
                        '7d': Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '7 Hari',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        '30d': Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '30 Hari',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        'all': Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Semua',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      },
                    ),
                  ),
                ),
              ),

              // Executive Stats 4-Grid Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppleCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RATA-RATA KALORI',
                                style: AppleTypography.caption(isDark: isDark)
                                    .copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${avgCalories.round()}',
                                style: AppleTypography.metricNumber(
                                  size: 24,
                                  isDark: isDark,
                                  color: AppleColors.calorieOrange,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'dari $targetCalories kkal',
                                style: AppleTypography.caption(isDark: isDark)
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppleCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KEPATUHAN TARGET',
                                style: AppleTypography.caption(isDark: isDark)
                                    .copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$compliancePercent%',
                                style: AppleTypography.metricNumber(
                                  size: 24,
                                  isDark: isDark,
                                  color: isDark
                                      ? AppleColors.primaryGreenDark
                                      : AppleColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$onTargetDaysCount dari $trackedDaysCount hari',
                                style: AppleTypography.caption(isDark: isDark)
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppleCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STREAK AKTIF',
                                style: AppleTypography.caption(isDark: isDark)
                                    .copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '🔥 $currentStreak',
                                style: AppleTypography.metricNumber(
                                  size: 24,
                                  isDark: isDark,
                                  color: AppleColors.calorieOrange,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hari berturut-turut',
                                style: AppleTypography.caption(isDark: isDark)
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Daily Calorie Bar Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tren Kalori Harian',
                              style: AppleTypography.headline(isDark: isDark),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppleColors.primaryGreenDark
                                        : AppleColors.primaryGreen)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Target: $targetCalories kkal',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppleColors.primaryGreenDark
                                      : AppleColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCalorieBarChart(
                          chartDays: chartDays,
                          entriesByDay: entriesByDay,
                          targetCalories: targetCalories,
                          isDark: isDark,
                        ),
                        if (_selectedInspectDate != null) ...[
                          const SizedBox(height: 12),
                          _buildInspectDayBanner(
                            date: _selectedInspectDate!,
                            entries: entriesByDay[_selectedInspectDate!] ?? [],
                            waterMl: storage.getWaterIntake(_selectedInspectDate!),
                            targetCalories: targetCalories,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Macro Ratio Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rata-rata Sebaran Makronutrisi',
                          style: AppleTypography.headline(isDark: isDark),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMacroStat(
                              'Protein',
                              '${avgProtein.round()}g',
                              'Target: ${targetProtein}g',
                              AppleColors.proteinCoral,
                              isDark,
                            ),
                            _buildMacroStat(
                              'Karbohidrat',
                              '${avgCarbs.round()}g',
                              'Target: ${targetCarbs}g',
                              AppleColors.carbsYellow,
                              isDark,
                            ),
                            _buildMacroStat(
                              'Lemak',
                              '${avgFat.round()}g',
                              'Target: ${targetFat}g',
                              AppleColors.fatCyan,
                              isDark,
                            ),
                            _buildMacroStat(
                              'Air Hidrasi',
                              '${(avgWater / 1000).toStringAsFixed(1)}L',
                              'Harian',
                              AppleColors.waterBlue,
                              isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildMacroRatioBar(
                          proteinG: avgProtein,
                          carbsG: avgCarbs,
                          fatG: avgFat,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search Box for History
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Cari riwayat menu makanan...',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    onSuffixTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
              ),

              // Daily Timeline Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Catatan Harian (${sortedDays.length} Hari)',
                        style: AppleTypography.headline(isDark: isDark),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Text(
                            'Reset Filter',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppleColors.primaryGreenDark
                                  : AppleColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Empty State
              if (sortedDays.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.square_list,
                            size: 48,
                            color: isDark
                                ? AppleColors.textSecondaryDark
                                : AppleColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ada makanan yang cocok dengan "$_searchQuery"'
                                : 'Belum ada riwayat tercatat pada periode ini.',
                            textAlign: TextAlign.center,
                            style: AppleTypography.body(isDark: isDark),
                          ),
                          const SizedBox(height: 16),
                          AppleButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            onPressed: () {
                              ref
                                  .read(mainNavIndexProvider.notifier)
                                  .setIndex(2); // Go to Scan tab
                            },
                            child: const Text('Mulai Catat Makanan'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Daily History Cards Feed
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final day = sortedDays[index];
                    final entries = entriesByDay[day] ?? [];
                    final waterMl = storage.getWaterIntake(day);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildDayHistoryCard(
                        date: day,
                        entries: entries,
                        waterMl: waterMl,
                        targetCalories: targetCalories,
                        isDark: isDark,
                      ),
                    );
                  },
                  childCount: sortedDays.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildCalorieBarChart({
    required List<DateTime> chartDays,
    required Map<DateTime, List<FoodEntry>> entriesByDay,
    required int targetCalories,
    required bool isDark,
  }) {
    const double chartHeight = 120.0;
    final maxCal = targetCalories * 1.35;

    final weekdaysIndo = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return SizedBox(
      height: chartHeight + 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chartDays.map((day) {
          final entries = entriesByDay[day] ?? [];
          final dayCal = entries.fold<int>(0, (sum, e) => sum + e.calories);
          final ratio = (dayCal / maxCal).clamp(0.0, 1.0);
          final barHeight = (ratio * chartHeight).clamp(6.0, chartHeight);

          final isSelected = _selectedInspectDate != null &&
              _selectedInspectDate!.year == day.year &&
              _selectedInspectDate!.month == day.month &&
              _selectedInspectDate!.day == day.day;

          Color barColor;
          if (dayCal == 0) {
            barColor = isDark
                ? AppleColors.surfaceSecondaryDark
                : AppleColors.surfaceSecondaryLight;
          } else if (dayCal >= (targetCalories * 0.85) &&
              dayCal <= (targetCalories * 1.15)) {
            barColor = isDark
                ? AppleColors.primaryGreenDark
                : AppleColors.primaryGreen;
          } else if (dayCal > targetCalories) {
            barColor = AppleColors.calorieOrange;
          } else {
            barColor = AppleColors.proteinCoral;
          }

          final dayName = weekdaysIndo[day.weekday - 1];

          return GestureDetector(
            onTap: () => _onInspectDay(day),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (dayCal > 0)
                  Text(
                    '${(dayCal / 1000).toStringAsFixed(1)}k',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isDark
                              ? AppleColors.primaryGreenDark
                              : AppleColors.primaryGreen)
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  )
                else
                  const SizedBox(height: 12),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: chartDays.length > 10 ? 14 : 22,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: isSelected ? barColor : barColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? Border.all(
                            color: Colors.white,
                            width: 1.5,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? (isDark
                            ? AppleColors.primaryGreenDark
                            : AppleColors.primaryGreen)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInspectDayBanner({
    required DateTime date,
    required List<FoodEntry> entries,
    required int waterMl,
    required int targetCalories,
    required bool isDark,
  }) {
    final dayCal = entries.fold<int>(0, (sum, e) => sum + e.calories);
    final dayP = entries.fold<double>(0, (sum, e) => sum + e.proteinG);
    final dayC = entries.fold<double>(0, (sum, e) => sum + e.carbsG);
    final dayF = entries.fold<double>(0, (sum, e) => sum + e.fatG);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppleColors.surfaceSecondaryDark
            : AppleColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day}/${date.month}/${date.year} • $dayCal kkal',
                style: AppleTypography.headline(isDark: isDark).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'P: ${dayP.round()}g • C: ${dayC.round()}g • L: ${dayF.round()}g • Air: ${(waterMl / 1000).toStringAsFixed(1)}L',
                style: AppleTypography.caption(isDark: isDark).copyWith(
                  fontSize: 11,
                ),
              ),
            ],
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openDateInDashboard(date),
            child: Row(
              children: [
                Text(
                  'Buka',
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
    );
  }

  Widget _buildMacroStat(
    String label,
    String value,
    String sub,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppleTypography.headline(isDark: isDark).copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: AppleTypography.caption(isDark: isDark).copyWith(fontSize: 11)),
        Text(
          sub,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRatioBar({
    required double proteinG,
    required double carbsG,
    required double fatG,
    required bool isDark,
  }) {
    final pCal = proteinG * 4;
    final cCal = carbsG * 4;
    final fCal = fatG * 9;
    final totalMacroCal = pCal + cCal + fCal;

    final pRatio = totalMacroCal > 0 ? (pCal / totalMacroCal) : 0.33;
    final cRatio = totalMacroCal > 0 ? (cCal / totalMacroCal) : 0.33;
    final fRatio = totalMacroCal > 0 ? (fCal / totalMacroCal) : 0.34;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: (pRatio * 100).round().clamp(1, 100),
                  child: Container(color: AppleColors.proteinCoral),
                ),
                Expanded(
                  flex: (cRatio * 100).round().clamp(1, 100),
                  child: Container(color: AppleColors.carbsYellow),
                ),
                Expanded(
                  flex: (fRatio * 100).round().clamp(1, 100),
                  child: Container(color: AppleColors.fatCyan),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rasio Kalori: ${(pRatio * 100).round()}% Protein',
              style: TextStyle(
                fontSize: 10,
                color: AppleColors.proteinCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(cRatio * 100).round()}% Karbo',
              style: TextStyle(
                fontSize: 10,
                color: AppleColors.carbsYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(fRatio * 100).round()}% Lemak',
              style: TextStyle(
                fontSize: 10,
                color: AppleColors.fatCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayHistoryCard({
    required DateTime date,
    required List<FoodEntry> entries,
    required int waterMl,
    required int targetCalories,
    required bool isDark,
  }) {
    final dayCal = entries.fold<int>(0, (sum, e) => sum + e.calories);
    final dayP = entries.fold<double>(0, (sum, e) => sum + e.proteinG);
    final dayC = entries.fold<double>(0, (sum, e) => sum + e.carbsG);
    final dayF = entries.fold<double>(0, (sum, e) => sum + e.fatG);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateTitle;
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      dateTitle = 'Hari Ini (${date.day}/${date.month})';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      dateTitle = 'Kemarin (${date.day}/${date.month})';
    } else {
      dateTitle = '${date.day}/${date.month}/${date.year}';
    }

    return AppleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Day
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 16,
                    color: isDark
                        ? AppleColors.primaryGreenDark
                        : AppleColors.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateTitle,
                    style: AppleTypography.headline(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '$dayCal',
                    style: AppleTypography.headline(isDark: isDark).copyWith(
                      color: AppleColors.calorieOrange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    ' / $targetCalories kkal',
                    style: AppleTypography.caption(isDark: isDark).copyWith(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Day Macro Badges
          Row(
            children: [
              _buildBadgePill('P: ${dayP.round()}g', AppleColors.proteinCoral, isDark),
              const SizedBox(width: 6),
              _buildBadgePill('C: ${dayC.round()}g', AppleColors.carbsYellow, isDark),
              const SizedBox(width: 6),
              _buildBadgePill('L: ${dayF.round()}g', AppleColors.fatCyan, isDark),
              const SizedBox(width: 6),
              _buildBadgePill(
                '💧 ${(waterMl / 1000).toStringAsFixed(1)}L',
                AppleColors.waterBlue,
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // List of Meal Entries for this Day
          ...entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppleColors.surfaceSecondaryDark
                          : AppleColors.surfaceSecondaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getMealIcon(entry.mealType),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${entry.portionDescription} • P:${entry.proteinG.round()}g C:${entry.carbsG.round()}g L:${entry.fatG.round()}g',
                          style: AppleTypography.caption(isDark: isDark).copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${entry.calories} kkal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppleColors.calorieOrange,
                    ),
                  ),
                  const SizedBox(width: 6),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => _confirmDeleteEntry(entry),
                    child: Icon(
                      CupertinoIcons.trash,
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          Center(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => _openDateInDashboard(date),
              child: Text(
                'Buka Hari Ini di Ringkasan ➔',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppleColors.primaryGreenDark
                      : AppleColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePill(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'sarapan':
        return '🍳';
      case 'makan siang':
      case 'siang':
        return '🥗';
      case 'makan malam':
      case 'malam':
        return '🍲';
      case 'camilan':
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }
}
