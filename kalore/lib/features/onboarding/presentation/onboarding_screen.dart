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
import '../models/user_profile.dart';
import 'diet_reveal_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isCloud;

  const OnboardingScreen({super.key, this.isCloud = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isGenerating = false;

  // Form State
  String _name = 'Teman Sehat';
  String _gender = 'male';
  int _age = 24;
  double _heightCm = 172.0;
  double _currentWeightKg = 68.0;
  double _targetWeightKg = 65.0;
  int _targetWeeks = 4; // Target durasi (minggu)
  String _activityLevel = 'moderate';
  String _goal = 'cutting';
  final List<String> _selectedPreferences = ['Tinggi Protein', 'Halal'];

  final List<String> _allPreferences = [
    'Halal',
    'Tinggi Protein',
    'Rendah Santan',
    'Budget Mahasiswa/Warteg',
    'Vegetarian',
    'Bebas Laktosa',
    'Rendah Garam',
  ];

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isGenerating = true);

    // Compute athlete-grade dynamic baseline targets (no generic template)
    final baseTargets = UserProfile.calculateDynamicNutritionalTargets(
      gender: _gender,
      currentWeightKg: _currentWeightKg,
      targetWeightKg: _targetWeightKg,
      heightCm: _heightCm,
      age: _age,
      activityLevel: _activityLevel,
      goal: _goal,
      targetWeeks: _targetWeeks,
    );

    final rawProfile = UserProfile(
      id: widget.isCloud
          ? 'cloud_user'
          : 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: _name,
      gender: _gender,
      age: _age,
      heightCm: _heightCm,
      currentWeightKg: _currentWeightKg,
      targetWeightKg: _targetWeightKg,
      activityLevel: _activityLevel,
      goal: _goal,
      targetWeeks: _targetWeeks,
      targetPace: (_goal.contains('aggressive') ||
              ((_targetWeightKg - _currentWeightKg).abs() / _targetWeeks) >= 1.2)
          ? 'aggressive'
          : 'moderate',
      dietaryPreferences: _selectedPreferences,
      targetCalories: baseTargets['targetCalories'] as int,
      targetProteinG: baseTargets['targetProteinG'] as int,
      targetCarbsG: baseTargets['targetCarbsG'] as int,
      targetFatG: baseTargets['targetFatG'] as int,
      targetWaterMl: baseTargets['targetWaterMl'] as int,
      strategyTitle: baseTargets['strategyTitle'] as String,
      guidelines: List<String>.from(baseTargets['guidelines'] as List),
      recommendedFoods:
          List<String>.from(baseTargets['recommendedFoods'] as List),
      isGuest: !widget.isCloud,
    );

    try {
      final gemini = ref.read(geminiServiceProvider);
      final finalizedProfile = await gemini.generateDietPlan(rawProfile);

      if (mounted) {
        setState(() => _isGenerating = false);
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (_) => DietRevealScreen(profile: finalizedProfile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (_) => DietRevealScreen(profile: rawProfile),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isGenerating) {
      return Scaffold(
        backgroundColor: isDark
            ? AppleColors.backgroundDark
            : AppleColors.backgroundLight,
        body: Center(
          child: ResponsiveContainer(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppleColors.primaryGreen.withValues(
                      alpha: isDark ? 0.22 : 0.15,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CupertinoActivityIndicator(
                    radius: 18,
                    color: isDark
                        ? AppleColors.primaryGreenDark
                        : AppleColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Kalore AI Sedang Meracik...',
                  style: AppleTypography.title2(isDark: isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Menganalisis BMR (${_gender == "male" ? "Pria" : "Wanita"}, ${_age}th), TDEE gaya hidup $_activityLevel, dan target nutrisi $_goal kamu.',
                  textAlign: TextAlign.center,
                  style: AppleTypography.callout(isDark: isDark),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppleColors.backgroundDark
          : AppleColors.backgroundLight,
      appBar: AppBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _prevPage,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Langkah ${_currentStep + 1} dari 5',
          style: AppleTypography.callout(
            isDark: isDark,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenBreakpoints.horizontalPadding(context),
            vertical: 8,
          ),
          child: Column(
            children: [
              // Progress Bar (Apple style)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 5,
                  backgroundColor: isDark
                      ? AppleColors.surfaceSecondaryDark
                      : AppleColors.surfaceSecondaryLight,
                  valueColor: AlwaysStoppedAnimation(
                    isDark
                        ? AppleColors.primaryGreenDark
                        : AppleColors.primaryGreen,
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(isDark),
                    _buildStep2(isDark),
                    _buildStep3(isDark),
                    _buildStep4(isDark),
                    _buildStep5(isDark),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AppleButton(
                  backgroundColor: isDark
                      ? AppleColors.primaryGreenDark
                      : AppleColors.primaryGreen,
                  onPressed: _nextPage,
                  child: Text(
                    _currentStep == 4 ? 'Buat Rencana Nutrisi AI' : 'Lanjutkan',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 1: Profil Dasar
  Widget _buildStep1(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Text('Kenalan Dulu Yuk', style: AppleTypography.title1(isDark: isDark)),
        const SizedBox(height: 6),
        Text(
          'Siapa nama panggilanmu dan apa jenis kelaminmu?',
          style: AppleTypography.callout(isDark: isDark),
        ),
        const SizedBox(height: 20),
        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nama Panggilan',
                style: AppleTypography.caption(isDark: isDark),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                placeholder: 'Nama Anda',
                controller: TextEditingController(text: _name),
                onChanged: (v) => _name = v,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppleColors.surfaceSecondaryDark
                      : AppleColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Jenis Kelamin',
                style: AppleTypography.caption(isDark: isDark),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppleCard(
                      backgroundColor: _gender == 'male'
                          ? AppleColors.primaryGreen.withValues(
                              alpha: isDark ? 0.25 : 0.15,
                            )
                          : null,
                      border: _gender == 'male'
                          ? Border.all(
                              color: isDark
                                  ? AppleColors.primaryGreenDark
                                  : AppleColors.primaryGreen,
                              width: 2,
                            )
                          : null,
                      onTap: () => setState(() => _gender = 'male'),
                      child: Center(
                        child: Text(
                          '👨 Pria',
                          style: AppleTypography.headline(isDark: isDark),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppleCard(
                      backgroundColor: _gender == 'female'
                          ? AppleColors.primaryGreen.withValues(
                              alpha: isDark ? 0.25 : 0.15,
                            )
                          : null,
                      border: _gender == 'female'
                          ? Border.all(
                              color: isDark
                                  ? AppleColors.primaryGreenDark
                                  : AppleColors.primaryGreen,
                              width: 2,
                            )
                          : null,
                      onTap: () => setState(() => _gender = 'female'),
                      child: Center(
                        child: Text(
                          '👩 Wanita',
                          style: AppleTypography.headline(isDark: isDark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Usia', style: AppleTypography.caption(isDark: isDark)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_age Tahun',
                    style: AppleTypography.headline(isDark: isDark),
                  ),
                  Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(6),
                        onPressed: () => setState(
                          () => _age = (_age > 12) ? _age - 1 : _age,
                        ),
                        child: const Icon(
                          CupertinoIcons.minus_circle,
                          size: 26,
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.all(6),
                        onPressed: () => setState(() => _age++),
                        child: const Icon(CupertinoIcons.plus_circle, size: 26),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: Ukuran Tubuh & Target Durasi
  Widget _buildStep2(bool isDark) {
    final deltaKg = _targetWeightKg - _currentWeightKg;
    final absDelta = deltaKg.abs();
    final ratePerWeek = absDelta / _targetWeeks;

    final isLoss = deltaKg < -0.1;
    final isGain = deltaKg > 0.1;

    String paceTitle;
    String paceDesc;
    Color paceColor;
    IconData paceIcon;

    if (isLoss) {
      if (ratePerWeek >= 1.2) {
        paceTitle = '⚡ Cutting Agresif Atlet (-${ratePerWeek.toStringAsFixed(1)} kg/minggu)';
        paceDesc =
            'Target ambisius! Kalore AI akan menghitung defisit terukur & memaksimalkan protein (2.3 g/kg) agar massa otot tetap kokoh dan metabolisme terlindungi.';
        paceColor = AppleColors.calorieOrange;
        paceIcon = CupertinoIcons.bolt_fill;
      } else if (ratePerWeek >= 0.6) {
        paceTitle = '🔥 Cutting Cepat Terarah (-${ratePerWeek.toStringAsFixed(1)} kg/minggu)';
        paceDesc =
            'Fase fat-loss optimal yang terbukti efektif dan aman untuk kebugaran harian.';
        paceColor = AppleColors.calorieOrange;
        paceIcon = CupertinoIcons.flame_fill;
      } else {
        paceTitle = '🌱 Cutting Bertahap (-${ratePerWeek.toStringAsFixed(1)} kg/minggu)';
        paceDesc =
            'Defisit kalori santai dan nyaman, sangat mudah dipertahankan jangka panjang.';
        paceColor = isDark
            ? AppleColors.primaryGreenDark
            : AppleColors.primaryGreen;
        paceIcon = CupertinoIcons.leaf_arrow_circlepath;
      }
    } else if (isGain) {
      if (ratePerWeek >= 0.6) {
        paceTitle = '💥 Bulking Agresif Atlet (+${ratePerWeek.toStringAsFixed(1)} kg/minggu)';
        paceDesc =
            'Surplus kalori tinggi (+650 kkal/hari) khusus atlet yang membutuhkan kenaikan power dan massa tubuh cepat.';
        paceColor = AppleColors.proteinCoral;
        paceIcon = CupertinoIcons.flame_fill;
      } else {
        paceTitle = '📈 Lean Bulking Terukur (+${ratePerWeek.toStringAsFixed(1)} kg/minggu)';
        paceDesc =
            'Surplus moderat untuk memicu sintesis protein otot tanpa penumpukan lemak berlebih.';
        paceColor = isDark
            ? AppleColors.primaryGreenDark
            : AppleColors.primaryGreen;
        paceIcon = CupertinoIcons.graph_circle_fill;
      }
    } else {
      paceTitle = '⚖️ Maintenance & Rekomposisi Tubuh';
      paceDesc =
          'Mempertahankan bobot badan dengan asupan energi seimbang sembari mengencangkan otot.';
      paceColor = isDark
          ? AppleColors.primaryGreenDark
          : AppleColors.primaryGreen;
      paceIcon = CupertinoIcons.checkmark_seal_fill;
    }

    final durationPresets = [
      {'weeks': 2, 'label': '2 Mgg (Kilat)'},
      {'weeks': 4, 'label': '4 Mgg (1 Bln)'},
      {'weeks': 8, 'label': '8 Mgg (2 Bln)'},
      {'weeks': 12, 'label': '12 Mgg (3 Bln)'},
      {'weeks': 16, 'label': '16 Mgg (4 Bln)'},
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Text('Ukuran Fisik & Target', style: AppleTypography.title1(isDark: isDark)),
        const SizedBox(height: 6),
        Text(
          'Digunakan untuk menghitung BMR, TDEE, serta kecepatan targetmu.',
          style: AppleTypography.callout(isDark: isDark),
        ),
        const SizedBox(height: 20),
        AppleCard(
          child: Column(
            children: [
              _buildSliderRow(
                'Tinggi Badan',
                '${_heightCm.round()} cm',
                _heightCm,
                120,
                220,
                (v) => setState(() => _heightCm = v),
                isDark,
              ),
              const Divider(),
              _buildSliderRow(
                'Berat Saat Ini',
                '${_currentWeightKg.round()} kg',
                _currentWeightKg,
                35,
                180,
                (v) => setState(() => _currentWeightKg = v),
                isDark,
              ),
              const Divider(),
              _buildSliderRow(
                'Target Berat',
                '${_targetWeightKg.round()} kg',
                _targetWeightKg,
                35,
                180,
                (v) => setState(() => _targetWeightKg = v),
                isDark,
              ),
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Waktu Selesai',
                        style: AppleTypography.caption(isDark: isDark),
                      ),
                      Text(
                        '$_targetWeeks Minggu (${(_targetWeeks / 4).toStringAsFixed(1)} Bulan)',
                        style: AppleTypography.headline(isDark: isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: durationPresets.map((item) {
                        final w = item['weeks'] as int;
                        final isSel = _targetWeeks == w;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _targetWeeks = w);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? (isDark
                                        ? AppleColors.primaryGreenDark
                                            .withValues(alpha: 0.3)
                                        : AppleColors.primaryGreen
                                            .withValues(alpha: 0.15))
                                    : (isDark
                                        ? AppleColors.surfaceSecondaryDark
                                        : AppleColors.surfaceSecondaryLight),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? (isDark
                                          ? AppleColors.primaryGreenDark
                                          : AppleColors.primaryGreen)
                                      : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSel
                                      ? (isDark
                                          ? AppleColors.primaryGreenDark
                                          : AppleColors.primaryGreen)
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  CupertinoSlider(
                    value: _targetWeeks.toDouble(),
                    min: 1,
                    max: 24,
                    divisions: 23,
                    activeColor: isDark
                        ? AppleColors.primaryGreenDark
                        : AppleColors.primaryGreen,
                    onChanged: (v) => setState(() => _targetWeeks = v.round()),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Live Pace Analysis Card
        AppleCard(
          backgroundColor: paceColor.withValues(alpha: isDark ? 0.14 : 0.08),
          border: Border.all(
            color: paceColor.withValues(alpha: isDark ? 0.4 : 0.25),
            width: 1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(paceIcon, color: paceColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      paceTitle,
                      style: AppleTypography.headline(isDark: isDark).copyWith(
                        color: paceColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                paceDesc,
                style: AppleTypography.caption(isDark: isDark).copyWith(
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 3: Aktivitas
  Widget _buildStep3(bool isDark) {
    final levels = [
      {
        'key': 'sedentary',
        'title': '🛋️ Sedentary',
        'desc': 'Banyak duduk, minim olahraga harian',
      },
      {
        'key': 'light',
        'title': '🚶 Aktif Ringan',
        'desc': 'Olahraga ringan 1-2 hari per minggu',
      },
      {
        'key': 'moderate',
        'title': '🏃 Moderat',
        'desc': 'Olahraga 3-5 hari per minggu',
      },
      {
        'key': 'very_active',
        'title': '🏋️ Sangat Aktif',
        'desc': 'Latihan berat 6-7 hari/minggu atau pekerja fisik',
      },
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Tingkat Aktivitas',
          style: AppleTypography.title1(isDark: isDark),
        ),
        const SizedBox(height: 6),
        Text(
          'Berapa banyak energimu yang terbakar setiap hari?',
          style: AppleTypography.callout(isDark: isDark),
        ),
        const SizedBox(height: 18),
        ...levels.map((item) {
          final isSelected = _activityLevel == item['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppleCard(
              backgroundColor: isSelected
                  ? AppleColors.primaryGreen.withValues(
                      alpha: isDark ? 0.22 : 0.15,
                    )
                  : null,
              border: isSelected
                  ? Border.all(
                      color: isDark
                          ? AppleColors.primaryGreenDark
                          : AppleColors.primaryGreen,
                      width: 2,
                    )
                  : null,
              onTap: () => setState(() => _activityLevel = item['key']!),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: AppleTypography.headline(isDark: isDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['desc']!,
                          style: AppleTypography.caption(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: isDark
                          ? AppleColors.primaryGreenDark
                          : AppleColors.primaryGreen,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // Step 4: Tujuan Diet & Rekomendasi Dinamis
  Widget _buildStep4(bool isDark) {
    final goals = [
      {
        'key': 'cutting_aggressive',
        'title': '⚡ Cutting Agresif (Fase Atlet / Cepat)',
        'desc':
            'Defisit kalori tinggi terukur, protein tinggi (2.3 g/kg) melindungi massa otot dari katabolisme. Ideal untuk atlet tanding atau target cepat.',
      },
      {
        'key': 'cutting',
        'title': '📉 Cutting Bertahap (Fat Loss Sehat)',
        'desc':
            'Defisit kalori moderat berkelanjutan (350-500 kkal), nyaman dan aman untuk jangka panjang.',
      },
      {
        'key': 'maintenance',
        'title': '⚖️ Maintenance (Komposisi & Stamina)',
        'desc':
            'Keseimbangan energi isokalori untuk mempertahankan berat badan ideal dan performa harian.',
      },
      {
        'key': 'bulking',
        'title': '📈 Lean Bulking (Pertambahan Otot Bersih)',
        'desc':
            'Surplus kalori terkontrol (+350 kkal) untuk memicu hipertrofi otot dengan penumpukan lemak minim.',
      },
      {
        'key': 'bulking_aggressive',
        'title': '💥 Bulking Agresif (Power & Mass Atlet)',
        'desc':
            'Surplus kalori tinggi (+650 kkal) bagi atlet yang butuh kenaikan massa tubuh dan tenaga angkat maksimal.',
      },
    ];

    final liveTargets = UserProfile.calculateDynamicNutritionalTargets(
      gender: _gender,
      currentWeightKg: _currentWeightKg,
      targetWeightKg: _targetWeightKg,
      heightCm: _heightCm,
      age: _age,
      activityLevel: _activityLevel,
      goal: _goal,
      targetWeeks: _targetWeeks,
    );

    final bmr = UserProfile.calculateBmr(
      gender: _gender,
      weightKg: _currentWeightKg,
      heightCm: _heightCm,
      age: _age,
    );
    final tdee = UserProfile.calculateTdee(
      bmr: bmr,
      activityLevel: _activityLevel,
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Tujuan Utama Kamu',
          style: AppleTypography.title1(isDark: isDark),
        ),
        const SizedBox(height: 6),
        Text(
          'Pilih strategi nutrisi. Kalore AI akan menyesuaikan target makronutrisi harian secara presisi.',
          style: AppleTypography.callout(isDark: isDark),
        ),
        const SizedBox(height: 18),
        ...goals.map((item) {
          final isSelected = _goal == item['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppleCard(
              backgroundColor: isSelected
                  ? AppleColors.primaryGreen.withValues(
                      alpha: isDark ? 0.22 : 0.15,
                    )
                  : null,
              border: isSelected
                  ? Border.all(
                      color: isDark
                          ? AppleColors.primaryGreenDark
                          : AppleColors.primaryGreen,
                      width: 2,
                    )
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _goal = item['key']!);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: AppleTypography.headline(isDark: isDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['desc']!,
                          style: AppleTypography.caption(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: isDark
                          ? AppleColors.primaryGreenDark
                          : AppleColors.primaryGreen,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 14),

        // Live Real-Time Calculation Preview Card
        AppleCard(
          backgroundColor: AppleColors.primaryGreen.withValues(
            alpha: isDark ? 0.15 : 0.08,
          ),
          border: Border.all(
            color: (isDark
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
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kalkulasi Dinamis Terpersonalisasi',
                      style: AppleTypography.headline(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppleColors.primaryGreenDark
                          : AppleColors.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Live Preview',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${liveTargets['targetCalories']}',
                    style: AppleTypography.metricNumber(
                      size: 36,
                      isDark: isDark,
                      color: AppleColors.calorieOrange,
                    ),
                  ),
                  Text(
                    'kkal / hari',
                    style: AppleTypography.callout(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                liveTargets['strategyTitle'] as String,
                style: AppleTypography.caption(isDark: isDark).copyWith(
                  color: isDark
                      ? AppleColors.primaryGreenDark
                      : AppleColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPreviewCol(
                    'Protein',
                    '${liveTargets['targetProteinG']}g',
                    AppleColors.proteinCoral,
                    isDark,
                  ),
                  _buildPreviewCol(
                    'Karbohidrat',
                    '${liveTargets['targetCarbsG']}g',
                    AppleColors.carbsYellow,
                    isDark,
                  ),
                  _buildPreviewCol(
                    'Lemak',
                    '${liveTargets['targetFatG']}g',
                    AppleColors.fatCyan,
                    isDark,
                  ),
                  _buildPreviewCol(
                    'Air Minum',
                    '${((liveTargets['targetWaterMl'] as int) / 1000).toStringAsFixed(1)}L',
                    AppleColors.waterBlue,
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppleColors.surfaceSecondaryDark
                      : AppleColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'BMR: ${bmr.round()} kkal • TDEE: ${tdee.round()} kkal • Durasi: $_targetWeeks Minggu',
                  textAlign: TextAlign.center,
                  style: AppleTypography.caption(isDark: isDark).copyWith(
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPreviewCol(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: AppleTypography.headline(isDark: isDark).copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppleTypography.caption(isDark: isDark).copyWith(
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // Step 5: Preferensi Makanan
  Widget _buildStep5(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Preferensi Makanan',
          style: AppleTypography.title1(isDark: isDark),
        ),
        const SizedBox(height: 6),
        Text(
          'Pilih preferensi atau pantangan menu harianmu.',
          style: AppleTypography.callout(isDark: isDark),
        ),
        const SizedBox(height: 18),
        AppleCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allPreferences.map((pref) {
              final isSelected = _selectedPreferences.contains(pref);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedPreferences.remove(pref);
                    } else {
                      _selectedPreferences.add(pref);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? AppleColors.primaryGreenDark.withValues(
                                  alpha: 0.25,
                                )
                              : AppleColors.primaryGreen.withValues(
                                  alpha: 0.15,
                                ))
                        : (isDark
                              ? AppleColors.surfaceSecondaryDark
                              : AppleColors.surfaceSecondaryLight),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? (isDark
                                ? AppleColors.primaryGreenDark
                                : AppleColors.primaryGreen)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          CupertinoIcons.checkmark,
                          size: 14,
                          color: isDark
                              ? AppleColors.primaryGreenDark
                              : AppleColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        pref,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isSelected
                              ? (isDark
                                    ? AppleColors.primaryGreenDark
                                    : AppleColors.primaryGreen)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        AppleCard(
          backgroundColor: AppleColors.calorieOrange.withValues(
            alpha: isDark ? 0.12 : 0.08,
          ),
          border: Border.all(
            color: AppleColors.calorieOrange.withValues(
              alpha: isDark ? 0.4 : 0.25,
            ),
            width: 0.5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: AppleColors.calorieOrange,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Catatan: Rencana nutrisi ini dihitung sebagai panduan edukatif gaya hidup, bukan pengganti diagnosis medis dokter.',
                  style: AppleTypography.caption(isDark: isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow(
    String label,
    String valueStr,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppleTypography.caption(isDark: isDark)),
            Text(valueStr, style: AppleTypography.headline(isDark: isDark)),
          ],
        ),
        CupertinoSlider(
          value: value,
          min: min,
          max: max,
          activeColor: isDark
              ? AppleColors.primaryGreenDark
              : AppleColors.primaryGreen,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
