import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/apple_colors.dart';
import '../../../core/theme/apple_typography.dart';
import '../../../core/widgets/apple_button.dart';
import '../../../core/widgets/apple_card.dart';
import '../models/food_entry.dart';

class PortionReviewSheet extends StatefulWidget {
  final FoodEntry initialEntry;
  final ValueChanged<FoodEntry> onSave;

  const PortionReviewSheet({
    super.key,
    required this.initialEntry,
    required this.onSave,
  });

  @override
  State<PortionReviewSheet> createState() => _PortionReviewSheetState();
}

class _PortionReviewSheetState extends State<PortionReviewSheet> {
  late String _mealType;
  late String _foodName;
  late List<FoodSubItem> _items;
  final double _scaleFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialEntry.mealType;
    _foodName = widget.initialEntry.name;
    _items = List.from(widget.initialEntry.items);
  }

  int get _computedCalories {
    if (_items.isEmpty) {
      return (widget.initialEntry.calories * _scaleFactor).round();
    }
    return _items.fold(0, (sum, i) => sum + i.calories);
  }

  double get _computedProtein {
    if (_items.isEmpty) {
      return widget.initialEntry.proteinG * _scaleFactor;
    }
    return _items.fold(0.0, (sum, i) => sum + i.proteinG);
  }

  double get _computedCarbs {
    if (_items.isEmpty) {
      return widget.initialEntry.carbsG * _scaleFactor;
    }
    return _items.fold(0.0, (sum, i) => sum + i.carbsG);
  }

  double get _computedFat {
    if (_items.isEmpty) {
      return widget.initialEntry.fatG * _scaleFactor;
    }
    return _items.fold(0.0, (sum, i) => sum + i.fatG);
  }

  void _adjustItemPortion(int index, double factor) {
    HapticFeedback.lightImpact();
    setState(() {
      _items[index] = _items[index].scale(factor);
    });
  }

  void _removeItem(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _items.removeAt(index);
    });
  }

  void _showEditTitleDialog() {
    final controller = TextEditingController(text: _foodName);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ubah Nama Hidangan'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Nama hidangan...',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Simpan'),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _foodName = newName);
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: screenHeight * 0.90,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppleColors.surfaceDark : AppleColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: isDark
                ? const Border(
                    top: BorderSide(
                      color: AppleColors.cardBorderDark,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Scrollable Content Body
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Title & Confidence Badge (Tap title to edit)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _showEditTitleDialog,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _foodName,
                                      style: AppleTypography.title2(isDark: isDark),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    CupertinoIcons.pencil_circle,
                                    size: 18,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppleColors.primaryGreen.withValues(
                                alpha: isDark ? 0.22 : 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.sparkles,
                                  size: 14,
                                  color: isDark
                                      ? AppleColors.primaryGreenDark
                                      : AppleColors.primaryGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI ${(widget.initialEntry.confidenceScore * 100).round()}%',
                                  style: AppleTypography.caption(isDark: isDark)
                                      .copyWith(
                                        color: isDark
                                            ? AppleColors.primaryGreenDark
                                            : AppleColors.primaryGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Total Nutrition Overview Card
                      AppleCard(
                        backgroundColor: isDark
                            ? AppleColors.surfaceSecondaryDark
                            : AppleColors.surfaceSecondaryLight,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTotalMetric(
                              '$_computedCalories',
                              'Kcal',
                              AppleColors.calorieOrange,
                              isDark,
                            ),
                            _buildTotalMetric(
                              '${_computedProtein.round()}g',
                              'Protein',
                              AppleColors.proteinCoral,
                              isDark,
                            ),
                            _buildTotalMetric(
                              '${_computedCarbs.round()}g',
                              'Karbo',
                              AppleColors.carbsYellow,
                              isDark,
                            ),
                            _buildTotalMetric(
                              '${_computedFat.round()}g',
                              'Lemak',
                              AppleColors.fatCyan,
                              isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Visual Analysis & Cooking Method Card (Apple Frosted style)
                      if (widget.initialEntry.cookingMethod != null ||
                          widget.initialEntry.visualCues.isNotEmpty) ...[
                        AppleCard(
                          backgroundColor: isDark
                              ? AppleColors.surfaceSecondaryDark
                              : AppleColors.surfaceSecondaryLight,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.viewfinder,
                                    size: 16,
                                    color: AppleColors.calorieOrange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'HASIL ANALISIS VISUAL AI',
                                    style: AppleTypography.caption2(
                                      isDark: isDark,
                                    ).copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: AppleColors.calorieOrange,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.initialEntry.cookingMethod != null &&
                                  widget.initialEntry.cookingMethod!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppleColors.calorieOrange.withValues(
                                      alpha: isDark ? 0.22 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '🔥 Metode: ${widget.initialEntry.cookingMethod}',
                                    style: AppleTypography.caption(
                                      isDark: isDark,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFFFB340)
                                          : const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ],
                              if (widget.initialEntry.visualCues.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Ciri Visual yang Dikenali:',
                                  style: AppleTypography.caption(isDark: isDark)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                ...widget.initialEntry.visualCues.map((cue) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '• ',
                                            style: TextStyle(
                                              color: AppleColors.primaryGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              cue,
                                              style: AppleTypography.caption(
                                                  isDark: isDark),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Dietary & Athlete Advice Card
                      if (widget.initialEntry.dietaryAdvice != null &&
                          widget.initialEntry.dietaryAdvice!.isNotEmpty) ...[
                        AppleCard(
                          backgroundColor: isDark
                              ? AppleColors.surfaceSecondaryDark
                              : AppleColors.surfaceSecondaryLight,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.flame_fill,
                                    size: 16,
                                    color: isDark
                                        ? AppleColors.primaryGreenDark
                                        : AppleColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ANALISIS NUTRISI & TARGET DIET',
                                    style: AppleTypography.caption2(
                                      isDark: isDark,
                                    ).copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: isDark
                                          ? AppleColors.primaryGreenDark
                                          : AppleColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.initialEntry.dietaryAdvice!,
                                style: AppleTypography.caption(isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildMealTypeChip('breakfast', '🍳 Sarapan'),
                            const SizedBox(width: 8),
                            _buildMealTypeChip('lunch', '🍗 Makan Siang'),
                            const SizedBox(width: 8),
                            _buildMealTypeChip('dinner', '🍲 Makan Malam'),
                            const SizedBox(width: 8),
                            _buildMealTypeChip('snack', '☕ Camilan'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sub-items List (Editable portions)
                      if (_items.isNotEmpty) ...[
                        Text(
                          'Rincian Porsi Bahan (Bisa Disesuaikan):',
                          style: AppleTypography.headline(isDark: isDark),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_items.length, (i) {
                          final item = _items[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppleCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: AppleTypography.headline(
                                            isDark: isDark,
                                          ).copyWith(fontSize: 15),
                                        ),
                                        Text(
                                          '${item.calories} kcal • ${item.proteinG.round()}g Prot • ${item.portion}',
                                          style: AppleTypography.caption(
                                            isDark: isDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Portion Stepper (- / +)
                                  CupertinoButton(
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () => _adjustItemPortion(i, 0.8),
                                    child: const Icon(
                                      CupertinoIcons.minus_circle,
                                      size: 24,
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () => _adjustItemPortion(i, 1.2),
                                    child: const Icon(
                                      CupertinoIcons.plus_circle,
                                      size: 24,
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () => _removeItem(i),
                                    child: const Icon(
                                      CupertinoIcons.xmark_circle,
                                      color: CupertinoColors.destructiveRed,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],

                      // Health Note from Gemini
                      if (widget.initialEntry.notes != null) ...[
                        AppleCard(
                          backgroundColor: isDark
                              ? AppleColors.surfaceSecondaryDark
                              : AppleColors.surfaceSecondaryLight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                CupertinoIcons.lightbulb_fill,
                                color: AppleColors.carbsYellow,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.initialEntry.notes!,
                                  style: AppleTypography.caption(
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Save Button
                      AppleButton(
                        backgroundColor: isDark
                            ? AppleColors.primaryGreenDark
                            : AppleColors.primaryGreen,
                        onPressed: () {
                          final finalEntry = FoodEntry(
                            id: widget.initialEntry.id,
                            mealType: _mealType,
                            name: _foodName,
                            calories: _computedCalories,
                            proteinG: _computedProtein,
                            carbsG: _computedCarbs,
                            fatG: _computedFat,
                            portionDescription:
                                widget.initialEntry.portionDescription,
                            items: _items,
                            notes: widget.initialEntry.notes,
                            confidenceScore:
                                widget.initialEntry.confidenceScore,
                            cookingMethod: widget.initialEntry.cookingMethod,
                            visualCues: widget.initialEntry.visualCues,
                            dietaryAdvice: widget.initialEntry.dietaryAdvice,
                            imagePath: widget.initialEntry.imagePath,
                            loggedAt: widget.initialEntry.loggedAt,
                          );
                          widget.onSave(finalEntry);
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Simpan ke Log Harian',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalMetric(
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: AppleTypography.headline(
            isDark: isDark,
          ).copyWith(color: color, fontWeight: FontWeight.w800),
        ),
        Text(label, style: AppleTypography.caption(isDark: isDark)),
      ],
    );
  }

  Widget _buildMealTypeChip(String type, String label) {
    final isSelected = _mealType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _mealType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppleColors.primaryGreenDark
                    : AppleColors.primaryGreen)
              : (isDark
                    ? AppleColors.surfaceSecondaryDark
                    : AppleColors.surfaceSecondaryLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                      ? AppleColors.separatorDark
                      : AppleColors.separatorLight),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
