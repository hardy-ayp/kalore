class UserProfile {
  final String id;
  final String name;
  final String gender; // 'male' or 'female'
  final int age;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'very_active'
  final String goal; // 'cutting_aggressive', 'cutting', 'maintenance', 'bulking', 'bulking_aggressive'
  final int targetWeeks; // Duration to target weight (e.g. 2, 4, 8, 12 weeks)
  final String targetPace; // 'aggressive', 'moderate', 'relaxed'
  final List<String> dietaryPreferences;

  // Nutritional targets (Deterministic + AI tailored)
  final int targetCalories;
  final int targetProteinG;
  final int targetCarbsG;
  final int targetFatG;
  final int targetWaterMl;

  // AI Strategy notes
  final String strategyTitle;
  final List<String> guidelines;
  final List<String> recommendedFoods;

  final bool isGuest;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.goal,
    this.targetWeeks = 4,
    this.targetPace = 'moderate',
    required this.dietaryPreferences,
    required this.targetCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    required this.targetWaterMl,
    required this.strategyTitle,
    required this.guidelines,
    required this.recommendedFoods,
    this.isGuest = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Mifflin-St Jeor BMR Calculation (Medical Standard)
  static double calculateBmr({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    if (gender == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  /// Total Daily Energy Expenditure (TDEE) multiplier
  static double calculateTdee({
    required double bmr,
    required String activityLevel,
  }) {
    double multiplier = 1.2; // sedentary
    switch (activityLevel) {
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'very_active':
        multiplier = 1.725;
        break;
      default:
        multiplier = 1.2;
    }
    return bmr * multiplier;
  }

  /// Dynamic Athlete-Grade Calorie & Macro Calculator.
  /// Tailors caloric deficit or surplus based on target weight, duration in weeks,
  /// and athlete aggressive cut / bulk requirements.
  static Map<String, dynamic> calculateDynamicNutritionalTargets({
    required String gender,
    required double currentWeightKg,
    required double targetWeightKg,
    required double heightCm,
    required int age,
    required String activityLevel,
    required String goal,
    required int targetWeeks,
  }) {
    final bmr = calculateBmr(
      gender: gender,
      weightKg: currentWeightKg,
      heightCm: heightCm,
      age: age,
    );
    final tdee = calculateTdee(bmr: bmr, activityLevel: activityLevel);

    final weeks = targetWeeks <= 0 ? 4 : targetWeeks;
    final totalDays = weeks * 7;
    final deltaKg = (targetWeightKg - currentWeightKg).abs();

    int targetCal = tdee.round();
    int proteinG = (currentWeightKg * 1.6).round();
    int fatG = ((targetCal * 0.25) / 9).round();
    int carbsG = 200;
    int waterMl = 2500;
    String title = 'Target Pemeliharaan Tubuh (Maintenance)';
    final guidelines = <String>[];
    final recommendedFoods = <String>[
      'Dada ayam tanpa kulit',
      'Telur & putih telur',
      'Tempe & tahu kukus / panggang',
      'Sayuran hijau segar (brokoli, bayam)',
      'Pisang, apel, dan alpukat',
    ];

    final isAggressiveCut = goal == 'cutting_aggressive';
    final isStandardCut = goal == 'cutting' || goal == 'cutting_standard';
    final isAggressiveBulk = goal == 'bulking_aggressive';
    final isStandardBulk = goal == 'bulking' || goal == 'bulking_standard';

    if (isAggressiveCut || isStandardCut) {
      // 1 kg body fat ~= 7700 kcal
      final totalDeficitNeeded = deltaKg * 7700.0;
      double dailyDeficit = totalDays > 0 ? (totalDeficitNeeded / totalDays) : 500.0;

      if (isAggressiveCut) {
        // Athlete aggressive weight cut (e.g. combat sports, bodybuilding prep)
        // Cap deficit between 600 and 1100 kcal for safety floor
        dailyDeficit = dailyDeficit.clamp(600.0, 1100.0);
        // Minimum metabolic floor (1200 kcal for women, 1400 kcal for men)
        final floor = gender == 'male' ? 1400.0 : 1200.0;
        targetCal = (tdee - dailyDeficit).clamp(floor, tdee - 400).round();

        // High protein sparing (2.2 - 2.5 g/kg) to preserve lean mass
        proteinG = (currentWeightKg * 2.3).round();
        fatG = ((targetCal * 0.22) / 9).round();
        carbsG = ((targetCal - (proteinG * 4) - (fatG * 9)) / 4).round().clamp(50, 400);
        waterMl = 3200; // Hydration support for intense metabolic waste flushing

        final weeklyRate = (deltaKg / weeks).toStringAsFixed(1);
        title = '⚡ Cutting Agresif Atlet (-$weeklyRate kg/minggu)';
        guidelines.addAll([
          'Defisit agresif berkecepatan tinggi: Utamakan protein tinggi ($proteinG g/hari) untuk mencegah katabolisme massa otot.',
          'Konsumsi air minimal ${(waterMl / 1000).toStringAsFixed(1)} Liter untuk menjaga volume sel otot dan pemulihan ginjal.',
          'Jadwalkan karbohidrat kompleks ($carbsG g) di sekitar waktu latihan untuk menjaga performa angkat beban.',
          'Pertimbangkan Refeed Day (makan di level TDEE) 1x seminggu jika mengalami lemas ekstrem.',
        ]);
      } else {
        // Standard sustainable cut (350 - 500 kcal deficit)
        dailyDeficit = dailyDeficit.clamp(350.0, 550.0);
        targetCal = (tdee - dailyDeficit).round();
        proteinG = (currentWeightKg * 1.8).round();
        fatG = ((targetCal * 0.25) / 9).round();
        carbsG = ((targetCal - (proteinG * 4) - (fatG * 9)) / 4).round().clamp(60, 500);
        waterMl = 2700;

        final weeklyRate = (deltaKg / weeks).toStringAsFixed(1);
        title = '📉 Cutting Bertahap (-$weeklyRate kg/minggu)';
        guidelines.addAll([
          'Defisit kalori stabil dan berkelanjutan tanpa mengorbankan metabolisme dasar.',
          'Penuhi target protein ($proteinG g/hari) dari sumber alami untuk rasa kenyang lebih lama.',
          'Tidur minimal 7-8 jam per malam untuk memaksimalkan oksidasi lemak tubuh.',
        ]);
      }
    } else if (isAggressiveBulk || isStandardBulk) {
      if (isAggressiveBulk) {
        // Athlete aggressive bulking / power surplus (500 - 800 kcal surplus)
        final surplus = 650.0;
        targetCal = (tdee + surplus).round();
        proteinG = (currentWeightKg * 2.2).round();
        fatG = ((targetCal * 0.25) / 9).round();
        carbsG = ((targetCal - (proteinG * 4) - (fatG * 9)) / 4).round();
        waterMl = 3500;

        final weeklyRate = (deltaKg / weeks).toStringAsFixed(1);
        title = '💥 Bulking Agresif Atlet (+$weeklyRate kg/minggu)';
        guidelines.addAll([
          'Surplus kalori tinggi (+650 kkal/hari) khusus fase pertambahan massa otot dan kekuatan maksimal.',
          'Tingkatkan karbohidrat ($carbsG g) untuk mengisi cadangan glikogen dan daya angkat prima.',
          'Penuhi protein harian ($proteinG g) yang terdistribusi ke dalam 4-5 kali makan.',
          'Kombinasikan dengan latihan beban intensitas tinggi (progressive overload).',
        ]);
      } else {
        // Standard lean bulking (250 - 400 kcal surplus)
        final surplus = 350.0;
        targetCal = (tdee + surplus).round();
        proteinG = (currentWeightKg * 1.8).round();
        fatG = ((targetCal * 0.25) / 9).round();
        carbsG = ((targetCal - (proteinG * 4) - (fatG * 9)) / 4).round();
        waterMl = 2800;

        final weeklyRate = (deltaKg / weeks).toStringAsFixed(1);
        title = '📈 Lean Bulking Terukur (+$weeklyRate kg/minggu)';
        guidelines.addAll([
          'Surplus moderat untuk meminimalkan penumpukan lemak berlebih saat membentuk otot.',
          'Pastikan asupan protein cukup ($proteinG g/hari) dengan kualitas asam amino lengkap.',
          'Catat perkembangan lingkar otot dan beban angkatan secara berkala.',
        ]);
      }
    } else {
      // Maintenance
      targetCal = tdee.round();
      proteinG = (currentWeightKg * 1.6).round();
      fatG = ((targetCal * 0.25) / 9).round();
      carbsG = ((targetCal - (proteinG * 4) - (fatG * 9)) / 4).round();
      waterMl = 2500;
      title = '⚖️ Rekomposisi & Pemeliharaan Nutrisi';
      guidelines.addAll([
        'Keseimbangan energi seimbang (isokalori) untuk menjaga berat badan dan kebugaran prima.',
        'Jaga kualitas makanan utuh (whole foods) dan konsistensi hidrasi harian.',
      ]);
    }

    return {
      'targetCalories': targetCal,
      'targetProteinG': proteinG,
      'targetCarbsG': carbsG,
      'targetFatG': fatG,
      'targetWaterMl': waterMl,
      'strategyTitle': title,
      'guidelines': guidelines,
      'recommendedFoods': recommendedFoods,
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender,
    'age': age,
    'heightCm': heightCm,
    'currentWeightKg': currentWeightKg,
    'targetWeightKg': targetWeightKg,
    'activityLevel': activityLevel,
    'goal': goal,
    'targetWeeks': targetWeeks,
    'targetPace': targetPace,
    'dietaryPreferences': dietaryPreferences,
    'targetCalories': targetCalories,
    'targetProteinG': targetProteinG,
    'targetCarbsG': targetCarbsG,
    'targetFatG': targetFatG,
    'targetWaterMl': targetWaterMl,
    'strategyTitle': strategyTitle,
    'guidelines': guidelines,
    'recommendedFoods': recommendedFoods,
    'isGuest': isGuest,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String? ?? 'guest_user',
    name: json['name'] as String? ?? 'Teman Sehat',
    gender: json['gender'] as String? ?? 'male',
    age: json['age'] as int? ?? 25,
    heightCm: (json['heightCm'] as num?)?.toDouble() ?? 170.0,
    currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 65.0,
    targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 65.0,
    activityLevel: json['activityLevel'] as String? ?? 'light',
    goal: json['goal'] as String? ?? 'cutting',
    targetWeeks: json['targetWeeks'] as int? ?? 4,
    targetPace: json['targetPace'] as String? ?? 'moderate',
    dietaryPreferences:
        (json['dietaryPreferences'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    targetCalories: json['targetCalories'] as int? ?? 2000,
    targetProteinG: json['targetProteinG'] as int? ?? 130,
    targetCarbsG: json['targetCarbsG'] as int? ?? 220,
    targetFatG: json['targetFatG'] as int? ?? 65,
    targetWaterMl: json['targetWaterMl'] as int? ?? 2500,
    strategyTitle:
        json['strategyTitle'] as String? ?? 'Target Nutrisi Seimbang',
    guidelines:
        (json['guidelines'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    recommendedFoods:
        (json['recommendedFoods'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    isGuest: json['isGuest'] as bool? ?? true,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  UserProfile copyWith({
    String? id,
    String? name,
    String? gender,
    int? age,
    double? heightCm,
    double currentWeightKg = -1,
    double targetWeightKg = -1,
    String? activityLevel,
    String? goal,
    int? targetWeeks,
    String? targetPace,
    List<String>? dietaryPreferences,
    int? targetCalories,
    int? targetProteinG,
    int? targetCarbsG,
    int? targetFatG,
    int? targetWaterMl,
    String? strategyTitle,
    List<String>? guidelines,
    List<String>? recommendedFoods,
    bool? isGuest,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg == -1
          ? this.currentWeightKg
          : currentWeightKg,
      targetWeightKg: targetWeightKg == -1
          ? this.targetWeightKg
          : targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      targetWeeks: targetWeeks ?? this.targetWeeks,
      targetPace: targetPace ?? this.targetPace,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProteinG: targetProteinG ?? this.targetProteinG,
      targetCarbsG: targetCarbsG ?? this.targetCarbsG,
      targetFatG: targetFatG ?? this.targetFatG,
      targetWaterMl: targetWaterMl ?? this.targetWaterMl,
      strategyTitle: strategyTitle ?? this.strategyTitle,
      guidelines: guidelines ?? this.guidelines,
      recommendedFoods: recommendedFoods ?? this.recommendedFoods,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt,
    );
  }
}
