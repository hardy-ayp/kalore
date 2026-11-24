class FoodSubItem {
  final String name;
  final String portion;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  FoodSubItem({
    required this.name,
    required this.portion,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'portion': portion,
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
  };

  factory FoodSubItem.fromJson(Map<String, dynamic> json) => FoodSubItem(
    name: json['name'] as String? ?? '',
    portion: json['portion'] as String? ?? '1 porsi',
    calories: json['calories'] as int? ?? 0,
    proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
    carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
    fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
  );

  FoodSubItem scale(double factor) => FoodSubItem(
    name: name,
    portion: portion,
    calories: (calories * factor).round(),
    proteinG: (proteinG * factor),
    carbsG: (carbsG * factor),
    fatG: (fatG * factor),
  );
}

class FoodEntry {
  final String id;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String portionDescription;
  final List<FoodSubItem> items;
  final String? notes;
  final String? imagePath;
  final double confidenceScore;
  final DateTime loggedAt;

  // Rich Visual & Culinary Intelligence Fields
  final String? cookingMethod; // e.g. "Dibakar Karamelisasi Kecap"
  final List<String> visualCues; // e.g. ["Ayam kecokelatan meresap", "Nasi putih pulen"]
  final String? dietaryAdvice; // e.g. "Rasio protein tinggi, cocok untuk cutting agresif"

  FoodEntry({
    required this.id,
    required this.mealType,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.portionDescription = '1 porsi',
    this.items = const [],
    this.notes,
    this.imagePath,
    this.confidenceScore = 1.0,
    this.cookingMethod,
    this.visualCues = const [],
    this.dietaryAdvice,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  FoodEntry copyWith({
    String? id,
    String? mealType,
    String? name,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? portionDescription,
    List<FoodSubItem>? items,
    String? notes,
    String? imagePath,
    double? confidenceScore,
    String? cookingMethod,
    List<String>? visualCues,
    String? dietaryAdvice,
    DateTime? loggedAt,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      portionDescription: portionDescription ?? this.portionDescription,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      visualCues: visualCues ?? this.visualCues,
      dietaryAdvice: dietaryAdvice ?? this.dietaryAdvice,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mealType': mealType,
    'name': name,
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'portionDescription': portionDescription,
    'items': items.map((i) => i.toJson()).toList(),
    'notes': notes,
    'imagePath': imagePath,
    'confidenceScore': confidenceScore,
    'cookingMethod': cookingMethod,
    'visualCues': visualCues,
    'dietaryAdvice': dietaryAdvice,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
    id:
        json['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    mealType: json['mealType'] as String? ?? 'lunch',
    name: json['name'] as String? ?? 'Makanan',
    calories: json['calories'] as int? ?? 0,
    proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
    carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
    fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
    portionDescription: json['portionDescription'] as String? ?? '1 porsi',
    items:
        (json['items'] as List<dynamic>?)
            ?.map((item) => FoodSubItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [],
    notes: json['notes'] as String?,
    imagePath: json['imagePath'] as String?,
    confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
    cookingMethod: json['cookingMethod'] as String?,
    visualCues:
        (json['visualCues'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    dietaryAdvice: json['dietaryAdvice'] as String?,
    loggedAt: json['loggedAt'] != null
        ? DateTime.tryParse(json['loggedAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
