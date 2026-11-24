import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalore/core/constants/api_config.dart';
import 'package:kalore/core/services/gemini_service.dart';
import 'package:kalore/core/theme/apple_colors.dart';
import 'package:kalore/core/theme/apple_theme.dart';
import 'package:kalore/features/food_logging/models/food_entry.dart';
import 'package:kalore/features/onboarding/models/user_profile.dart';

void main() {
  group('UserProfile Calculations & Medical Formulas', () {
    test('Calculates male BMR correctly (Mifflin-St Jeor)', () {
      final bmr = UserProfile.calculateBmr(
        gender: 'male',
        weightKg: 70,
        heightCm: 175,
        age: 25,
      );
      // (10 * 70) + (6.25 * 175) - (5 * 25) + 5 = 700 + 1093.75 - 125 + 5 = 1673.75
      expect(bmr, closeTo(1673.75, 0.01));
    });

    test('Calculates female BMR correctly (Mifflin-St Jeor)', () {
      final bmr = UserProfile.calculateBmr(
        gender: 'female',
        weightKg: 55,
        heightCm: 160,
        age: 22,
      );
      // (10 * 55) + (6.25 * 160) - (5 * 22) - 161 = 550 + 1000 - 110 - 161 = 1279.0
      expect(bmr, closeTo(1279.0, 0.01));
    });

    test('Calculates TDEE correctly based on activity level', () {
      const bmr = 1600.0;
      final tdeeSedentary = UserProfile.calculateTdee(
        bmr: bmr,
        activityLevel: 'sedentary',
      );
      final tdeeModerate = UserProfile.calculateTdee(
        bmr: bmr,
        activityLevel: 'moderate',
      );

      expect(tdeeSedentary, 1600.0 * 1.2);
      expect(tdeeModerate, 1600.0 * 1.55);
    });
  });

  group('FoodEntry & Portion Scaling', () {
    test('Scales food ingredients accurately', () {
      final subItem = FoodSubItem(
        name: 'Ayam Goreng',
        portion: '1 potong (100g)',
        calories: 260,
        proteinG: 25.0,
        carbsG: 2.0,
        fatG: 17.0,
      );

      final scaledDouble = subItem.scale(2.0);
      expect(scaledDouble.calories, 520);
      expect(scaledDouble.proteinG, 50.0);
      expect(scaledDouble.fatG, 34.0);
    });

    test('Serializes and deserializes FoodEntry correctly', () {
      final entry = FoodEntry(
        id: 'test_123',
        mealType: 'lunch',
        name: 'Nasi Kuning Komplit',
        calories: 620,
        proteinG: 22.0,
        carbsG: 75.0,
        fatG: 24.0,
        items: [
          FoodSubItem(
            name: 'Nasi Kuning',
            portion: '1 piring',
            calories: 280,
            proteinG: 4,
            carbsG: 60,
            fatG: 2,
          ),
        ],
        notes: 'Enak dan gurih',
      );

      final jsonStr = jsonEncode(entry.toJson());
      final decoded = FoodEntry.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );

      expect(decoded.id, 'test_123');
      expect(decoded.name, 'Nasi Kuning Komplit');
      expect(decoded.calories, 620);
      expect(decoded.items.length, 1);
      expect(decoded.items.first.name, 'Nasi Kuning');
    });

    test('FoodEntry supports rich visual & culinary intelligence fields', () {
      final entry = FoodEntry(
        id: 'visual_001',
        mealType: 'lunch',
        name: 'Ayam Bakar Bumbu Rujak & Sambal',
        calories: 580,
        proteinG: 34.0,
        carbsG: 62.0,
        fatG: 18.0,
        cookingMethod: 'Dibakar Karamelisasi Kecap',
        visualCues: ['Kulit ayam kecokelatan meresap', 'Nasi putih pulen'],
        dietaryAdvice: 'Sangat tinggi protein (34g), cocok untuk cutting atlet.',
        confidenceScore: 0.96,
      );

      final jsonStr = jsonEncode(entry.toJson());
      final decoded = FoodEntry.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

      expect(decoded.cookingMethod, 'Dibakar Karamelisasi Kecap');
      expect(decoded.visualCues, contains('Kulit ayam kecokelatan meresap'));
      expect(decoded.dietaryAdvice, contains('34g'));
      expect(decoded.confidenceScore, 0.96);
    });

    test('GeminiService detects image MIME types from magic bytes', () {
      // PNG: 89 50 4E 47
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0]);
      expect(GeminiService.detectMimeType(pngBytes), 'image/png');

      // JPEG: FF D8 FF
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0]);
      expect(GeminiService.detectMimeType(jpegBytes), 'image/jpeg');

      // WEBP: RIFF....WEBP
      final webpBytes = Uint8List.fromList([0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50]);
      expect(GeminiService.detectMimeType(webpBytes), 'image/webp');
    });

    test('ApiConfig tracks updated app version 1.3.0+5', () {
      expect(ApiConfig.appVersion, '1.3.0+5');
      expect(ApiConfig.appVersionName, '1.3.0');
      expect(ApiConfig.appBuildNumber, 5);
    });

    test('ApiConfig supports safe compile-time and env injection', () {
      expect(ApiConfig.defaultGeminiApiKey, isA<String>());
      expect(ApiConfig.defaultCalorieApiKey, isA<String>());
      expect(ApiConfig.defaultCalorieNinjasKey, isA<String>());
    });
  });

  group('Apple HIG Theme System & Dark Mode', () {
    test('Light theme has correct background and brightness', () {
      final light = AppleTheme.lightTheme();
      expect(light.brightness, Brightness.light);
      expect(light.scaffoldBackgroundColor, AppleColors.backgroundLight);
      expect(light.splashFactory, NoSplash.splashFactory);
    });

    test('Dark theme has OLED pure black background and brightness', () {
      final dark = AppleTheme.darkTheme();
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, AppleColors.backgroundDark);
      expect(dark.colorScheme.surface, AppleColors.surfaceDark);
      expect(dark.splashFactory, NoSplash.splashFactory);
    });

    test('Apple semantic macro colors are properly defined', () {
      expect(AppleColors.calorieOrange, const Color(0xFFFF9500));
      expect(AppleColors.proteinCoral, const Color(0xFFFF2D55));
      expect(AppleColors.carbsYellow, const Color(0xFFFFCC00));
      expect(AppleColors.fatCyan, const Color(0xFF32ADE6));
      expect(AppleColors.waterBlue, const Color(0xFF007AFF));
    });
  });
}
