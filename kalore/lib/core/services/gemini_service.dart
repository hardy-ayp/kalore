import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../../features/food_logging/models/food_entry.dart';
import '../../features/onboarding/models/user_profile.dart';

/// Nutrition & AI Analysis Service for Kalore.
///
/// Multi-Tier Analysis Engine Hierarchy:
/// 1. Primary Engine #1: CalorieAPI (CalorieApiAdmin verified food database)
/// 2. Primary Engine #2: CalorieNinjas (Natural Language Processing nutrition engine)
/// 3. Fallback Engine #3: Google Gemini Generative AI (multimodal vision & structured text)
/// 4. Fallback Engine #4: Smart On-Device Nutrition Heuristics (100% offline capability)
class GeminiService {
  final String? _apiKey;
  final http.Client _httpClient;

  // Prioritized 2026 Gemini model candidates with instant failover
  static const List<String> _modelCandidates = [
    'gemini-flash-lite-latest',
    'gemini-3.5-flash-lite',
    'gemini-3-flash-preview',
  ];

  /// Detects MIME type from image bytes header signatures (Magic Bytes).
  static String detectMimeType(Uint8List bytes) {
    if (bytes.length >= 12) {
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      // WEBP: 'RIFF' .... 'WEBP'
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'image/webp';
      }
      // GIF: GIF87a or GIF89a
      if (bytes[0] == 0x47 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x38) {
        return 'image/gif';
      }
    } else if (bytes.length >= 3) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
    }
    return 'image/jpeg';
  }

  GeminiService({String? apiKey, http.Client? httpClient})
      : _apiKey = apiKey,
        _httpClient = httpClient ?? http.Client();

  bool get hasApiKey {
    final key = _apiKey;
    return key != null && key.trim().isNotEmpty;
  }

  GenerativeModel _getModel(String modelName) {
    if (!hasApiKey) {
      throw Exception('AI key belum dikonfigurasi.');
    }
    return GenerativeModel(
      model: modelName,
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
  }

  String _cleanJsonString(String raw) {
    String cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }
    return cleaned;
  }

  // =========================================================================
  // PRIMARY ENGINE #1: CalorieAPI (CalorieApiAdmin)
  // =========================================================================
  Future<FoodEntry?> _fetchFromCalorieApi(String query, String mealType) async {
    if (ApiConfig.defaultCalorieApiKey.trim().isEmpty) {
      return null;
    }
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final url = Uri.parse('https://calorieapiadmin.com/api/v1/search/foods?q=$encoded');
      final response = await _httpClient.get(
        url,
        headers: {
          'X-API-Key': ApiConfig.defaultCalorieApiKey,
          'Accept': 'application/json',
          'User-Agent': 'Kalore/${ApiConfig.appVersionName} (Dart/Flutter; Mobile)',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final list = decoded['data'] as List<dynamic>;
          if (list.isNotEmpty) {
            return _mapCalorieApiToFoodEntry(query, list, mealType);
          }
        }
      } else {
        debugPrint('CalorieAPI status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('CalorieAPI error: $e');
    }
    return null;
  }

  double _extractNutrient(List<dynamic>? list, String name) {
    if (list == null) return 0.0;
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final nName = (item['nutrient_name'] ?? item['name'] ?? '').toString().toLowerCase();
        if (nName == name.toLowerCase() || nName.startsWith(name.toLowerCase())) {
          final amount = item['amount'] ?? item['value'];
          if (amount is num) return amount.toDouble();
        }
      }
    }
    return 0.0;
  }

  FoodEntry _mapCalorieApiToFoodEntry(String query, List<dynamic> data, String mealType) {
    final topItem = data.first as Map<String, dynamic>;
    final name = topItem['name'] as String? ?? query;
    final serving = (topItem['serving'] ?? topItem['default_portion']?['label'] ?? '1 porsi').toString();

    final portionNutrients = topItem['portion_nutrients'] as List<dynamic>?;
    final nutrients100g = topItem['nutrients'] as List<dynamic>?;
    final mealObj = topItem['meal'] as Map<String, dynamic>?;

    double cal = _extractNutrient(portionNutrients, 'Calories');
    if (cal <= 0 && mealObj != null && mealObj['calories'] is num) {
      cal = (mealObj['calories'] as num).toDouble();
    }
    if (cal <= 0) {
      cal = (topItem['calories_100g'] as num?)?.toDouble() ?? _extractNutrient(nutrients100g, 'Calories');
    }

    double p = _extractNutrient(portionNutrients, 'Protein');
    if (p <= 0 && mealObj != null && mealObj['macros']?['protein'] is num) {
      p = (mealObj['macros']['protein'] as num).toDouble();
    }
    if (p <= 0) {
      p = (topItem['protein_100g'] as num?)?.toDouble() ?? _extractNutrient(nutrients100g, 'Protein');
    }

    double c = _extractNutrient(portionNutrients, 'Carbohydrates');
    if (c <= 0 && mealObj != null && mealObj['macros']?['carbs'] is num) {
      c = (mealObj['macros']['carbs'] as num).toDouble();
    }
    if (c <= 0) {
      c = (topItem['carbs_100g'] as num?)?.toDouble() ?? _extractNutrient(nutrients100g, 'Carbohydrates');
    }

    double f = _extractNutrient(portionNutrients, 'Fat');
    if (f <= 0 && mealObj != null && mealObj['macros']?['fat'] is num) {
      f = (mealObj['macros']['fat'] as num).toDouble();
    }
    if (f <= 0) {
      f = (topItem['fat_100g'] as num?)?.toDouble() ?? _extractNutrient(nutrients100g, 'Fat');
    }

    final subItems = <FoodSubItem>[
      FoodSubItem(
        name: name,
        portion: serving,
        calories: cal.round(),
        proteinG: p,
        carbsG: c,
        fatG: f,
      ),
    ];

    return FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mealType: mealType,
      name: name,
      calories: cal.round(),
      proteinG: p,
      carbsG: c,
      fatG: f,
      portionDescription: serving,
      items: subItems,
      notes: 'Dianalisis melalui CalorieAPI Verified Database.',
      confidenceScore: 0.98,
    );
  }

  // =========================================================================
  // PRIMARY ENGINE #2: CalorieNinjas NLP Engine
  // =========================================================================
  Future<FoodEntry?> _fetchFromCalorieNinjas(String query, String mealType) async {
    if (ApiConfig.defaultCalorieNinjasKey.trim().isEmpty) {
      return null;
    }
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final url = Uri.parse('https://api.calorieninjas.com/v1/nutrition?query=$encoded');
      final response = await _httpClient.get(
        url,
        headers: {
          'X-Api-Key': ApiConfig.defaultCalorieNinjasKey,
          'Accept': 'application/json',
          'User-Agent': 'Kalore/${ApiConfig.appVersionName} (Dart/Flutter; Mobile)',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['items'] is List) {
          final items = decoded['items'] as List<dynamic>;
          if (items.isNotEmpty) {
            return _mapCalorieNinjasToFoodEntry(query, items, mealType);
          }
        }
      } else {
        debugPrint('CalorieNinjas status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('CalorieNinjas error: $e');
    }
    return null;
  }

  /// Official CalorieNinjas Image Text OCR Endpoint (Extracts nutrition from menus, labels, recipes)
  Future<FoodEntry?> _fetchFromCalorieNinjasImage(Uint8List imageBytes, String mealType) async {
    if (ApiConfig.defaultCalorieNinjasKey.trim().isEmpty) {
      return null;
    }
    try {
      final uri = Uri.parse('https://api.calorieninjas.com/v1/imagetextnutrition');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'X-Api-Key': ApiConfig.defaultCalorieNinjasKey,
          'User-Agent': 'Kalore/${ApiConfig.appVersionName} (Dart/Flutter; Mobile)',
        })
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'food_capture.png',
        ));

      final streamed = await _httpClient.send(request).timeout(const Duration(seconds: 8));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['items'] is List) {
          final items = decoded['items'] as List<dynamic>;
          if (items.isNotEmpty) {
            debugPrint('CalorieNinjas Image OCR detected ${items.length} food items');
            return _mapCalorieNinjasToFoodEntry('Menu & Label Terdeteksi', items, mealType).copyWith(
              cookingMethod: 'Dikenali melalui OCR CalorieNinjas',
              visualCues: ['Teks makanan berhasil diekstrak dari gambar'],
              dietaryAdvice: 'Nutrisi dihitung langsung dari menu/kemasan makanan yang tertera di foto.',
            );
          }
        }
      } else {
        debugPrint('CalorieNinjas Image OCR status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('CalorieNinjas Image OCR error: $e');
    }
    return null;
  }

  FoodEntry _mapCalorieNinjasToFoodEntry(String query, List<dynamic> items, String mealType) {
    final subItems = <FoodSubItem>[];
    int totalCal = 0;
    double totalP = 0;
    double totalC = 0;
    double totalF = 0;

    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final rawName = raw['name'] as String? ?? 'Makanan';
      final capitalized = rawName
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
      final servingG = (raw['serving_size_g'] as num?)?.round() ?? 100;
      final cals = (raw['calories'] as num?)?.round() ?? 0;
      final p = (raw['protein_g'] as num?)?.toDouble() ?? 0.0;
      final c = (raw['carbohydrates_total_g'] as num?)?.toDouble() ?? 0.0;
      final f = (raw['fat_total_g'] as num?)?.toDouble() ?? 0.0;

      subItems.add(
        FoodSubItem(
          name: capitalized,
          portion: '${servingG}g',
          calories: cals,
          proteinG: p,
          carbsG: c,
          fatG: f,
        ),
      );

      totalCal += cals;
      totalP += p;
      totalC += c;
      totalF += f;
    }

    String titleName = query.trim();
    if (items.length == 1) {
      titleName = subItems.first.name;
    } else if (titleName.isEmpty) {
      titleName = subItems.map((s) => s.name).join(' & ');
    }

    return FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mealType: mealType,
      name: titleName,
      calories: totalCal,
      proteinG: totalP,
      carbsG: totalC,
      fatG: totalF,
      portionDescription: '${subItems.length} Komponen Terdeteksi',
      items: subItems,
      notes: 'Dianalisis melalui CalorieNinjas NLP Engine.',
      confidenceScore: 0.96,
    );
  }

  // =========================================================================
  // FALLBACK ENGINE #3: Google Gemini AI (Generative Model)
  // =========================================================================
  Future<FoodEntry?> _analyzeFoodTextWithGemini(String textDescription, String mealType) async {
    final prompt = '''
Analisis deskripsi makanan berikut untuk aplikasi pelacak nutrisi "Kalore":
Deskripsi: "$textDescription"

Keluarkan output JSON dengan format:
{
  "food_name": "Nama Hidangan Utama",
  "confidence_score": 0.95,
  "total_calories": 520,
  "total_protein": 28.0,
  "total_carbs": 60.0,
  "total_fat": 16.0,
  "portion_description": "1 Porsi Standar",
  "items": [
    {
      "name": "Komponen A",
      "portion": "1 porsi",
      "calories": 250,
      "proteinG": 15.0,
      "carbsG": 35.0,
      "fatG": 6.0
    }
  ],
  "health_notes": "Ringkasan edukatif singkat mengenai nutrisi hidangan ini."
}
''';

    for (final modelName in _modelCandidates) {
      try {
        final model = _getModel(modelName);
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text != null && text.isNotEmpty) {
          final cleaned = _cleanJsonString(text);
          final Map<String, dynamic> json = jsonDecode(cleaned);
          return _mapJsonToFoodEntry(json, mealType);
        }
      } catch (e) {
        debugPrint('Gemini text analysis error on $modelName: $e');
      }
    }
    return null;
  }

  // =========================================================================
  // UNIFIED PUBLIC ENTRYPOINT: Text Description Analysis
  // =========================================================================
  /// Analyzes text description of meals using multi-tier API fallback hierarchy:
  /// 1. CalorieAPI (Primary Database #1)
  /// 2. CalorieNinjas (Primary NLP #2)
  /// 3. Google Gemini AI (Fallback Model #3)
  /// 4. Smart On-Device Offline Heuristics (Offline Fallback #4)
  Future<FoodEntry> analyzeFoodText({
    required String textDescription,
    String mealType = 'lunch',
  }) async {
    final cleanQuery = textDescription.trim();
    if (cleanQuery.isEmpty) {
      return _generateSmartOfflineFoodEntry('Makanan', mealType);
    }

    // Tier 1: CalorieAPI (Primary #1)
    try {
      final calorieApiResult = await _fetchFromCalorieApi(cleanQuery, mealType);
      if (calorieApiResult != null && calorieApiResult.calories > 0) {
        debugPrint('Successfully analyzed food using CalorieAPI: ${calorieApiResult.name}');
        return calorieApiResult;
      }
    } catch (e) {
      debugPrint('CalorieAPI error, falling back to CalorieNinjas: $e');
    }

    // Tier 2: CalorieNinjas (Primary #2)
    try {
      final calorieNinjasResult = await _fetchFromCalorieNinjas(cleanQuery, mealType);
      if (calorieNinjasResult != null && calorieNinjasResult.calories > 0) {
        debugPrint('Successfully analyzed food using CalorieNinjas: ${calorieNinjasResult.name}');
        return calorieNinjasResult;
      }
    } catch (e) {
      debugPrint('CalorieNinjas error, falling back to Gemini AI: $e');
    }

    // Tier 3: Gemini Generative AI (Fallback #3)
    if (hasApiKey) {
      try {
        final geminiResult = await _analyzeFoodTextWithGemini(cleanQuery, mealType);
        if (geminiResult != null) {
          debugPrint('Successfully analyzed food using Gemini AI: ${geminiResult.name}');
          return geminiResult;
        }
      } catch (e) {
        debugPrint('Gemini AI error, falling back to offline heuristics: $e');
      }
    }

    // Tier 4: On-Device Smart Nutrition Heuristics (Fallback #4)
    return _generateSmartOfflineFoodEntry(cleanQuery, mealType);
  }

  // =========================================================================
  // MULTIMODAL PHOTO VISION ANALYSIS
  // =========================================================================
  /// Multimodal Vision: Deeply inspects food photo with visual cues, cooking methods,
  /// ingredient breakdown, and athlete macro recommendations.
  Future<FoodEntry> analyzeFoodImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String? userNote,
    String mealType = 'lunch',
  }) async {
    final resolvedMime = mimeType == 'image/jpeg'
        ? detectMimeType(imageBytes)
        : mimeType;

    if (hasApiKey) {
      final prompt = '''
Anda adalah Master Nutritionist & Culinary Visual Specialist untuk aplikasi pelacak kalori & nutrisi "Kalore".
Tugas Anda: Periksa foto hidangan makanan ini secara teliti, detail, dan mendalam. DILARANG KERAS memberikan nama generik seperti "Makanan", "Piring Makanan", atau deskripsi umum yang tidak spesifik.

Instruksi Analisis Visual:
1. IDENTIFIKASI NAMA HIDANGAN LENGKAP:
   - Sebutkan nama masakan/hidangan secara spesifik, autentik, dan akurat (contoh: "Nasi Ayam Bakar Bumbu Rujak & Sambal Terasi", "Salmon Mentai Rice Bowl", "Gado-Gado Siram Telur Rebus", "Dada Ayam Panggang Herb & Roasted Potatoes", "Mie Goreng Spesial Telur Ceplok").
2. RINCIAN KOMPONEN KASAT MATA:
   - Identifikasi setiap komponen bahan yang terlihat di piring/wadah secara terpisah:
     * Karbohidrat pokok (nama spesifik, estimasi gram/porsi, kalori, makronutrisi)
     * Sumber protein utama (daging, ayam, ikan, telur, tahu, tempe, keju)
     * Sayuran & Serat (lalapan, salad, tumisan)
     * Saus, sambal, kuah, minyak/santan tersembunyi
3. CIRI VISUAL & METODE PENGOLAHAN:
   - Sebutkan metode pengolahan yang terlihat jelas (contoh: "Dibakar Karamelisasi Bumbu Kecap", "Deep Fried / Goreng Renyah", "Ditumis Sedikit Minyak", "Kukus Sehat", "Rebus Kaldu").
   - Cantumkan 2-4 ciri visual spesifik yang Anda amati di gambar (contoh: "Permukaan ayam memiliki glaze kecap karamel berkilau", "Nasi putih pulen porsi sedang bertabur bawang goreng", "Sambal merah terasi dengan minyak cabai alami").
4. ANALISIS NUTRISI & REKOMENDASI ATLET:
   - Berikan analisis mendalam mengenai densitas protein vs kalori, estimasi sodium/natrium, dan apakah hidangan ini ramah untuk cutting agresif (defisit), bulking bersih (surplus), atau pemulihan otot (post-workout).
Catatan tambahan dari pengguna: ${userNote ?? '-'}

Format output HARUS JSON murni valid:
{
  "food_name": "Nama Spesifik Masakan",
  "confidence_score": 0.95,
  "cooking_method": "Metode Pengolahan Spesifik",
  "visual_cues": [
    "Ciri visual 1 yang teramati di foto",
    "Ciri visual 2 yang teramati di foto",
    "Ciri visual 3 yang teramati di foto"
  ],
  "total_calories": 560,
  "total_protein": 32.0,
  "total_carbs": 62.0,
  "total_fat": 18.0,
  "portion_description": "1 Porsi Lengkap (~380g)",
  "items": [
    {
      "name": "Komponen A",
      "portion": "1 potong (120g)",
      "calories": 240,
      "proteinG": 26.0,
      "carbsG": 2.0,
      "fatG": 14.0
    },
    {
      "name": "Komponen B",
      "portion": "1 piring (180g)",
      "calories": 220,
      "proteinG": 4.0,
      "carbsG": 48.0,
      "fatG": 0.5
    }
  ],
  "dietary_advice": "Analisis mendalam mengenai nilai nutrisi untuk diet/atlet, kepadatan protein, dan saran porsi.",
  "health_notes": "Ringkasan edukatif mikronutrisi, serat, dan tips konsumsi."
}
''';

      final base64Image = base64Encode(imageBytes);

      for (final modelName in _modelCandidates) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey',
          );
          final requestBody = jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                  {
                    'inline_data': {
                      'mime_type': resolvedMime,
                      'data': base64Image,
                    }
                  }
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.2,
            }
          });

          final response = await _httpClient
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
              )
              .timeout(const Duration(seconds: 12));

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            final candidates = decoded['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = candidates.first['content']?['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts.first['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  final cleaned = _cleanJsonString(text);
                  final Map<String, dynamic> json = jsonDecode(cleaned);
                  final parsed = _mapJsonToFoodEntry(json, mealType);
                  if (parsed.items.isNotEmpty || parsed.calories > 0) {
                    debugPrint('Gemini REST Vision success on $modelName: ${parsed.name} (${parsed.calories} kcal)');
                    return parsed;
                  }
                }
              }
            }
          } else {
            debugPrint('Gemini REST vision status ${response.statusCode} on $modelName: ${response.body}');
          }
        } catch (e) {
          debugPrint('Gemini REST vision error on $modelName: $e');
        }
      }
    }

    // Fallback #1: If user provided a note or text, run it through the CalorieAPI / CalorieNinjas chain
    if (userNote != null && userNote.trim().isNotEmpty) {
      final textResult = await analyzeFoodText(textDescription: userNote, mealType: mealType);
      return textResult.copyWith(
        cookingMethod: 'Dianalisis dari catatan hidangan',
        visualCues: ['Komponen disesuaikan dengan deskripsi pengguna'],
        dietaryAdvice: 'Nutrisi dihitung akurat berdasarkan database CalorieAPI & CalorieNinjas.',
      );
    }

    // Fallback #2: CalorieNinjas OCR image recognition (detects menus, recipes, nutrition labels)
    final ninjaImageResult = await _fetchFromCalorieNinjasImage(imageBytes, mealType);
    if (ninjaImageResult != null && ninjaImageResult.calories > 0) {
      return ninjaImageResult;
    }

    // Fallback #3: Rather than returning a silent fake generic 480 kcal entry, throw a descriptive
    // Exception that triggers the instant dish-name prompt in the UI
    throw Exception('Foto belum teridentifikasi otomatis oleh AI Vision (antrean server sedang padat). Silakan masukkan nama hidangan untuk kalkulasi instan via CalorieAPI.');
  }

  // =========================================================================
  // ATHLETE DIET BLUEPRINT GENERATION
  // =========================================================================
  /// Generates a personalized Athlete Diet Blueprint & daily macro targets from User Profile.
  Future<UserProfile> generateDietPlan(UserProfile profile) async {
    final baseTargets = UserProfile.calculateDynamicNutritionalTargets(
      gender: profile.gender,
      currentWeightKg: profile.currentWeightKg,
      targetWeightKg: profile.targetWeightKg,
      heightCm: profile.heightCm,
      age: profile.age,
      activityLevel: profile.activityLevel,
      goal: profile.goal,
      targetWeeks: profile.targetWeeks,
    );

    if (!hasApiKey) {
      return _applyDynamicTargets(profile, baseTargets);
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

    final prompt = '''
Bertindaklah sebagai ahli gizi klinis dan sport nutritionist berstandar internasional untuk atlet dan penggiat kebugaran.
Hitung dan susun modul diet harian yang dipersonalisasi dan masuk akal untuk profil berikut:
- Gender: ${profile.gender}
- Usia: ${profile.age} tahun
- Tinggi: ${profile.heightCm} cm
- Berat Badan Saat Ini: ${profile.currentWeightKg} kg
- Target Berat Badan: ${profile.targetWeightKg} kg
- Target Waktu Selesai: ${profile.targetWeeks} minggu (${(profile.targetWeeks / 4).toStringAsFixed(1)} bulan)
- Tingkat Aktivitas: ${profile.activityLevel} (BMR dasar: ${bmr.round()} kkal, TDEE dasar: ${tdee.round()} kkal)
- Tujuan Utama: ${profile.goal}
  * Jika cutting_aggressive: defisit agresif terukur (fase penurunan berat badan cepat/atlet tanding), protein tinggi (2.2-2.5 g/kg) untuk cegah katabolisme otot.
  * Jika cutting_standard: defisit bertahap 350-500 kkal.
  * Jika maintenance: isokalori TDEE.
  * Jika bulking_aggressive: surplus tinggi 500-750 kkal untuk hipertrofi & tenaga maksimal.
  * Jika bulking_standard: surplus moderat 300-400 kkal.
- Preferensi Makanan: ${profile.dietaryPreferences.isEmpty ? 'Umum / Tanpa pantangan' : profile.dietaryPreferences.join(', ')}

Keluarkan JSON dengan format persis:
{
  "target_calories": ${baseTargets['targetCalories']},
  "protein_grams": ${baseTargets['targetProteinG']},
  "carbs_grams": ${baseTargets['targetCarbsG']},
  "fat_grams": ${baseTargets['targetFatG']},
  "water_ml": ${baseTargets['targetWaterMl']},
  "strategy_title": "${baseTargets['strategyTitle']}",
  "guidelines": [
    "Prioritaskan asupan protein tinggi pada setiap jadwal makan.",
    "Jaga konsistensi defisit/surplus sesuai target waktu ${profile.targetWeeks} minggu."
  ],
  "recommended_foods": [
    "Dada ayam tanpa kulit",
    "Telur utuh & putih telur",
    "Tempe & tahu kukus / panggang",
    "Sayuran hijau dan buah segar"
  ]
}
''';

    for (final modelName in _modelCandidates) {
      try {
        final model = _getModel(modelName);
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text != null && text.isNotEmpty) {
          final cleaned = _cleanJsonString(text);
          final Map<String, dynamic> json = jsonDecode(cleaned);
          return profile.copyWith(
            targetCalories: (json['target_calories'] as num?)?.toInt() ?? (baseTargets['targetCalories'] as int),
            targetProteinG: (json['protein_grams'] as num?)?.toInt() ?? (baseTargets['targetProteinG'] as int),
            targetCarbsG: (json['carbs_grams'] as num?)?.toInt() ?? (baseTargets['targetCarbsG'] as int),
            targetFatG: (json['fat_grams'] as num?)?.toInt() ?? (baseTargets['targetFatG'] as int),
            targetWaterMl: (json['water_ml'] as num?)?.toInt() ?? (baseTargets['targetWaterMl'] as int),
            strategyTitle: json['strategy_title'] as String? ?? (baseTargets['strategyTitle'] as String),
            guidelines: (json['guidelines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? (baseTargets['guidelines'] as List<String>),
            recommendedFoods: (json['recommended_foods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? (baseTargets['recommendedFoods'] as List<String>),
          );
        }
      } catch (e) {
        debugPrint('Gemini Diet Plan error on $modelName: $e');
      }
    }

    return _applyDynamicTargets(profile, baseTargets);
  }

  UserProfile _applyDynamicTargets(UserProfile profile, Map<String, dynamic> base) {
    return profile.copyWith(
      targetCalories: base['targetCalories'] as int,
      targetProteinG: base['targetProteinG'] as int,
      targetCarbsG: base['targetCarbsG'] as int,
      targetFatG: base['targetFatG'] as int,
      targetWaterMl: base['targetWaterMl'] as int,
      strategyTitle: base['strategyTitle'] as String,
      guidelines: (base['guidelines'] as List<String>),
      recommendedFoods: (base['recommendedFoods'] as List<String>),
    );
  }

  FoodEntry _mapJsonToFoodEntry(Map<String, dynamic> json, String mealType) {
    final List<dynamic> rawItems = (json['items'] as List<dynamic>?) ?? [];
    final items = rawItems.map((item) {
      final m = item as Map<String, dynamic>;
      return FoodSubItem(
        name: m['name'] as String? ?? 'Bahan',
        portion: m['portion'] as String? ?? '1 porsi',
        calories: (m['calories'] as num?)?.toInt() ?? 0,
        proteinG: (m['proteinG'] as num?)?.toDouble() ?? 0.0,
        carbsG: (m['carbsG'] as num?)?.toDouble() ?? 0.0,
        fatG: (m['fatG'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final visualCues = (json['visual_cues'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        const [];

    return FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mealType: mealType,
      name: json['food_name'] as String? ?? 'Makanan',
      calories: (json['total_calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['total_protein'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['total_carbs'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['total_fat'] as num?)?.toDouble() ?? 0.0,
      portionDescription: json['portion_description'] as String? ?? '1 porsi',
      items: items,
      notes: json['health_notes'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.9,
      cookingMethod: json['cooking_method'] as String?,
      visualCues: visualCues,
      dietaryAdvice: json['dietary_advice'] as String?,
    );
  }

  // =========================================================================
  // FALLBACK ENGINE #4: Smart On-Device Nutrition Heuristics
  // =========================================================================
  /// On-Device Smart Nutrition Heuristic Engine (100% Offline Capability).
  /// Parses user text descriptions against common dietary patterns & Indonesian dishes.
  FoodEntry _generateSmartOfflineFoodEntry(String description, String mealType) {
    final lower = description.toLowerCase();
    final items = <FoodSubItem>[];

    int totalCals = 0;
    double totalP = 0;
    double totalC = 0;
    double totalF = 0;

    // Helper matcher
    void addItem(String name, String portion, int c, double p, double carb, double f) {
      items.add(FoodSubItem(name: name, portion: portion, calories: c, proteinG: p, carbsG: carb, fatG: f));
      totalCals += c;
      totalP += p;
      totalC += carb;
      totalF += f;
    }

    // 1. Carbs
    if (lower.contains('nasi goreng')) {
      addItem('Nasi Goreng', '1 piring sedang (200g)', 380, 8.0, 58.0, 14.0);
    } else if (lower.contains('nasi uduk') || lower.contains('nasi kuning')) {
      addItem('Nasi Gurih / Uduk', '1 piring (180g)', 280, 5.0, 48.0, 8.0);
    } else if (lower.contains('nasi')) {
      addItem('Nasi Putih', '1 centong/piring (150g)', 195, 3.8, 44.0, 0.4);
    } else if (lower.contains('mie') || lower.contains('bakmi') || lower.contains('bihun')) {
      addItem('Mie / Bihun', '1 porsi (180g)', 310, 7.0, 52.0, 9.0);
    } else if (lower.contains('roti')) {
      addItem('Roti Tawar / Gandum', '2 lembar', 160, 6.0, 28.0, 2.5);
    } else if (lower.contains('oatmeal') || lower.contains('oat')) {
      addItem('Oatmeal', '1 mangkok (50g kering)', 180, 6.5, 32.0, 3.0);
    } else if (lower.contains('kentang')) {
      addItem('Kentang Rebus / Panggang', '1 buah sedang (150g)', 130, 3.0, 29.0, 0.2);
    }

    // 2. Proteins
    if (lower.contains('dada ayam') || lower.contains('chicken breast')) {
      addItem('Dada Ayam Fillet', '150 gram', 240, 46.0, 0.0, 5.0);
    } else if (lower.contains('ayam bakar') || lower.contains('ayam panggang') || lower.contains('grilled chicken')) {
      addItem('Ayam Bakar', '1 potong (120g)', 230, 26.0, 2.0, 13.0);
    } else if (lower.contains('ayam goreng') || lower.contains('fried chicken') || lower.contains('chicken sandwich')) {
      addItem('Ayam & Sandwich', '1 porsi (150g)', 320, 24.0, 22.0, 16.0);
    } else if (lower.contains('ayam') || lower.contains('chicken')) {
      addItem('Ayam', '1 potong (120g)', 250, 24.0, 4.0, 15.0);
    }

    if (lower.contains('telur dadar')) {
      addItem('Telur Dadar', '1 butir besar', 120, 7.5, 1.2, 9.5);
    } else if (lower.contains('telur ceplok') || lower.contains('telur')) {
      addItem('Telur Ceplok / Rebus', '1 butir', 90, 6.8, 0.6, 6.5);
    }

    if (lower.contains('tempe')) {
      addItem('Tempe Goreng / Bacem', '2 potong sedang', 140, 10.0, 8.0, 8.0);
    }
    if (lower.contains('tahu')) {
      addItem('Tahu', '2 potong', 90, 8.0, 3.0, 5.0);
    }
    if (lower.contains('daging') || lower.contains('rendang') || lower.contains('sapi')) {
      addItem('Daging Sapi / Rendang', '1 potong (80g)', 240, 20.0, 4.0, 16.0);
    }
    if (lower.contains('ikan') || lower.contains('salmon') || lower.contains('lele')) {
      addItem('Ikan Bakar / Goreng', '1 ekor/potong (120g)', 210, 22.0, 2.0, 12.0);
    }
    if (lower.contains('whey') || lower.contains('susu')) {
      addItem('Susu / Whey Protein', '1 gelas / 1 scoop', 140, 24.0, 5.0, 2.0);
    }

    // 3. Vegetables & Extras
    if (lower.contains('sayur') || lower.contains('bayam') || lower.contains('kangkung') || lower.contains('capcay') || lower.contains('salad')) {
      addItem('Sayuran & Serat', '1 mangkok sedang', 75, 2.5, 12.0, 2.0);
    }
    if (lower.contains('sambal')) {
      addItem('Sambal', '1 sendok makan', 35, 0.5, 3.0, 2.5);
    }
    if (lower.contains('buah') || lower.contains('pisang') || lower.contains('apel') || lower.contains('apple')) {
      addItem('Buah Apel / Segar', '1 porsi sedang (150g)', 95, 0.5, 25.0, 0.3);
    }
    if (lower.contains('carrot') || lower.contains('wortel')) {
      addItem('Wortel Segar', '1 porsi (100g)', 41, 0.9, 9.6, 0.2);
    }

    // Fallback if no matching keywords were recognized
    if (items.isEmpty) {
      addItem(description.isEmpty ? 'Porsi Hidangan Seimbang' : description, '1 Porsi Standar', 480, 24.0, 58.0, 16.0);
    }

    String titleName = description.trim();
    if (titleName.length > 36) {
      titleName = '${titleName.substring(0, 33)}...';
    }
    if (titleName.isEmpty) {
      titleName = 'Catatan Makanan';
    }

    return FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mealType: mealType,
      name: titleName,
      calories: totalCals,
      proteinG: totalP,
      carbsG: totalC,
      fatG: totalF,
      portionDescription: '${items.length} Komponen Hidangan',
      items: items,
      notes: 'Kalkulasi cerdas offline. Anda dapat mengedit gramatur atau komponen di lembar tinjauan.',
      confidenceScore: 0.88,
    );
  }
}
