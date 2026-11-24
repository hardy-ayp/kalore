import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_config.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../../features/food_logging/models/food_entry.dart';
import '../../features/onboarding/models/user_profile.dart';

// Singletons / Services
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// App Theme Mode Provider (System / Light / Dark)
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final saved = storage.getThemeMode();
      switch (saved) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final storage = ref.read(storageServiceProvider);
      String modeStr = 'system';
      if (mode == ThemeMode.light) modeStr = 'light';
      if (mode == ThemeMode.dark) modeStr = 'dark';
      await storage.setThemeMode(modeStr);
    } catch (_) {}
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final customKey = storage.getCustomApiKey();
  final activeKey = (customKey != null && customKey.trim().isNotEmpty)
      ? customKey.trim()
      : ApiConfig.defaultGeminiApiKey;
  return GeminiService(apiKey: activeKey);
});

// Currently selected dashboard date (default = today)
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = date;
}

// User Profile Notifier
final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveProfile(profile);
    state = profile;
  }
}

// Food Entries for Selected Date
final dailyFoodEntriesProvider =
    NotifierProvider<DailyFoodEntriesNotifier, List<FoodEntry>>(
      DailyFoodEntriesNotifier.new,
    );

class DailyFoodEntriesNotifier extends Notifier<List<FoodEntry>> {
  @override
  List<FoodEntry> build() {
    final storage = ref.watch(storageServiceProvider);
    final date = ref.watch(selectedDateProvider);
    return storage.getFoodEntriesForDate(date);
  }

  Future<void> addEntry(FoodEntry entry) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveFoodEntry(entry);
    ref.invalidateSelf();
  }

  Future<void> removeEntry(String id) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteFoodEntry(id);
    ref.invalidateSelf();
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

// All Food Entries Provider (Full Historical Log for History / Recap)
final allFoodEntriesProvider = Provider<List<FoodEntry>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  // Re-read whenever daily entries are updated
  ref.watch(dailyFoodEntriesProvider);
  return storage.getAllFoodEntries();
});

// Main Navigation Tab Index Provider
final mainNavIndexProvider = NotifierProvider<MainNavIndexNotifier, int>(
  MainNavIndexNotifier.new,
);

class MainNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

// Water Intake Provider
final dailyWaterProvider = NotifierProvider<DailyWaterNotifier, int>(
  DailyWaterNotifier.new,
);

class DailyWaterNotifier extends Notifier<int> {
  @override
  int build() {
    final storage = ref.watch(storageServiceProvider);
    final date = ref.watch(selectedDateProvider);
    return storage.getWaterIntake(date);
  }

  Future<void> addWater(int ml) async {
    final storage = ref.read(storageServiceProvider);
    final date = ref.read(selectedDateProvider);
    await storage.addWater(date, ml);
    ref.invalidateSelf();
  }

  Future<void> setWater(int ml) async {
    final storage = ref.read(storageServiceProvider);
    final date = ref.read(selectedDateProvider);
    await storage.setWater(date, ml);
    ref.invalidateSelf();
  }

  Future<void> reset() async {
    final storage = ref.read(storageServiceProvider);
    final date = ref.read(selectedDateProvider);
    await storage.resetWater(date);
    ref.invalidateSelf();
  }
}
