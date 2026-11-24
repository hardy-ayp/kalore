import 'package:flutter_test/flutter_test.dart';
import 'package:kalore/core/constants/api_config.dart';
import 'package:kalore/core/services/gemini_service.dart';

void main() {
  test('Test GeminiService text analysis with online and offline fallback', () async {
    final service = GeminiService(apiKey: ApiConfig.defaultGeminiApiKey);
    final entry = await service.analyzeFoodText(textDescription: 'Nasi goreng telur dan dada ayam');
    // ignore: avoid_print
    print('ENTRY: ${entry.name}, ${entry.calories} kcal, ${entry.proteinG}g protein, items=${entry.items.length}');
    expect(entry.calories, greaterThan(0));
    expect(entry.items, isNotEmpty);

    // Test offline service (no key)
    final offlineService = GeminiService(apiKey: null);
    final offlineEntry = await offlineService.analyzeFoodText(textDescription: '2 telur rebus dan oatmeal');
    // ignore: avoid_print
    print('OFFLINE: ${offlineEntry.name}, ${offlineEntry.calories} kcal, ${offlineEntry.proteinG}g protein');
    expect(offlineEntry.calories, greaterThan(0));
    expect(offlineEntry.items, isNotEmpty);
  });
}
