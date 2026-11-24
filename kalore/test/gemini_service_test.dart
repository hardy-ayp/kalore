import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalore/core/constants/api_config.dart';
import 'package:kalore/core/services/gemini_service.dart';
import 'package:kalore/features/onboarding/models/user_profile.dart';

void main() {
  group('GeminiService & Nutrition Tests', () {
    test('ApiConfig provides secure environment defaults and application version', () {
      expect(ApiConfig.appVersion, '1.3.0+5');
      expect(ApiConfig.appVersionName, '1.3.0');
      expect(ApiConfig.appBuildNumber, 5);
      expect(ApiConfig.defaultCalorieApiKey, isA<String>());
      expect(ApiConfig.defaultCalorieNinjasKey, isA<String>());
      expect(ApiConfig.defaultGeminiApiKey, isA<String>());
    });

    test('GeminiService analyzes food via CalorieAPI primary engine', () async {
      final service = GeminiService();
      final entry = await service.analyzeFoodText(textDescription: 'apple');
      expect(entry.calories, greaterThan(0));
      expect(entry.items, isNotEmpty);
    });

    test('GeminiService analyzes food via CalorieNinjas multi-item engine', () async {
      final service = GeminiService();
      final entry = await service.analyzeFoodText(textDescription: 'carrots and chicken sandwich');
      expect(entry.calories, greaterThan(0));
      expect(entry.items, isNotEmpty);
    });

    test('GeminiService text analysis with offline fallback', () async {
      final offlineService = GeminiService(apiKey: null);
      final offlineEntry =
          await offlineService.analyzeFoodText(textDescription: '2 telur rebus dan oatmeal');
      expect(offlineEntry.calories, greaterThan(0));
      expect(offlineEntry.items, isNotEmpty);
    });

    test('GeminiService analyzeFoodImage returns rich visual fields on offline/fallback', () async {
      final offlineService = GeminiService(apiKey: null);
      final sampleBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]);
      final entry = await offlineService.analyzeFoodImage(
        imageBytes: sampleBytes,
        userNote: 'Ayam bakar madu dan nasi merah',
      );

      expect(entry.calories, greaterThan(0));
      expect(entry.cookingMethod, isNotNull);
      expect(entry.visualCues, isNotEmpty);
      expect(entry.dietaryAdvice, isNotNull);
    });

    test('GeminiService analyzeFoodImage throws Exception instead of returning silent generic data', () async {
      final offlineService = GeminiService(apiKey: null);
      final sampleBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]);
      expect(
        () => offlineService.analyzeFoodImage(imageBytes: sampleBytes),
        throwsA(isA<Exception>()),
      );
    });

    test('UserProfile dynamic athlete calculation - Aggressive Cutting (65kg -> 55kg in 4 weeks)', () {
      final targets = UserProfile.calculateDynamicNutritionalTargets(
        gender: 'male',
        currentWeightKg: 65.0,
        targetWeightKg: 55.0,
        heightCm: 172.0,
        age: 24,
        activityLevel: 'moderate',
        goal: 'cutting_aggressive',
        targetWeeks: 4,
      );

      // Deficit is calculated dynamically, should NEVER be generic 2000 kcal!
      expect(targets['targetCalories'], lessThan(2000));
      expect(targets['targetCalories'], greaterThanOrEqualTo(1400)); // Male metabolic floor
      // High protein sparing for athlete (>= 2.2 g/kg -> 65 * 2.3 = 150g)
      expect(targets['targetProteinG'], greaterThanOrEqualTo(140));
      expect(targets['targetWaterMl'], greaterThanOrEqualTo(3000));
      expect((targets['strategyTitle'] as String).contains('Agresif'), isTrue);
    });

    test('UserProfile dynamic athlete calculation - Aggressive Bulking', () {
      final targets = UserProfile.calculateDynamicNutritionalTargets(
        gender: 'male',
        currentWeightKg: 65.0,
        targetWeightKg: 72.0,
        heightCm: 172.0,
        age: 24,
        activityLevel: 'moderate',
        goal: 'bulking_aggressive',
        targetWeeks: 6,
      );

      // Should be in high caloric surplus
      expect(targets['targetCalories'], greaterThan(2500));
      expect(targets['targetProteinG'], greaterThanOrEqualTo(140));
      expect((targets['strategyTitle'] as String).contains('Bulking Agresif'), isTrue);
    });
  });
}
