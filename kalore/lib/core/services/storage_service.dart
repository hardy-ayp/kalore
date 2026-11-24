import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/food_logging/models/food_entry.dart';
import '../../features/onboarding/models/user_profile.dart';

/// Offline-First Storage Service.
/// Persists data locally in JSON format with instant Export & Import capabilities.
class StorageService {
  static const String _profileKey = 'kalore_user_profile';
  static const String _foodEntriesFileName = 'kalore_food_entries.json';
  static const String _waterLogPrefix = 'kalore_water_';

  late SharedPreferences _prefs;
  File? _foodEntriesFile;
  List<FoodEntry> _cachedEntries = [];

  StorageService({SharedPreferences? prefs, List<FoodEntry>? initialEntries}) {
    if (prefs != null) _prefs = prefs;
    if (initialEntries != null) _cachedEntries = List.from(initialEntries);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _initFoodEntriesFile();
    await _loadFoodEntries();
  }

  Future<void> _initFoodEntriesFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _foodEntriesFile = File('${dir.path}/$_foodEntriesFileName');
      if (!await _foodEntriesFile!.exists()) {
        await _foodEntriesFile!.writeAsString(jsonEncode([]));
      }
    } catch (e) {
      debugPrint('Error initializing local food entries file: $e');
    }
  }

  Future<void> _loadFoodEntries() async {
    if (_foodEntriesFile == null || !await _foodEntriesFile!.exists()) return;
    try {
      final content = await _foodEntriesFile!.readAsString();
      final List<dynamic> decoded = jsonDecode(content);
      _cachedEntries = decoded
          .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading cached food entries: $e');
      _cachedEntries = [];
    }
  }

  Future<void> _saveAllFoodEntries() async {
    if (_foodEntriesFile == null) return;
    try {
      final data = _cachedEntries.map((e) => e.toJson()).toList();
      await _foodEntriesFile!.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving food entries to disk: $e');
    }
  }

  // --- Profile Operations ---
  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  UserProfile? getProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error parsing profile: $e');
      return null;
    }
  }

  // --- Food Entries Operations ---
  List<FoodEntry> getFoodEntriesForDate(DateTime date) {
    return _cachedEntries.where((entry) {
      return entry.loggedAt.year == date.year &&
          entry.loggedAt.month == date.month &&
          entry.loggedAt.day == date.day;
    }).toList();
  }

  List<FoodEntry> getAllFoodEntries() {
    return List.unmodifiable(_cachedEntries);
  }

  Future<void> saveFoodEntry(FoodEntry entry) async {
    // Remove if exists (replace) or prepend
    _cachedEntries.removeWhere((e) => e.id == entry.id);
    _cachedEntries.insert(0, entry);
    await _saveAllFoodEntries();
  }

  Future<void> deleteFoodEntry(String id) async {
    _cachedEntries.removeWhere((e) => e.id == id);
    await _saveAllFoodEntries();
  }

  // --- Water Intake Operations ---
  int getWaterIntake(DateTime date) {
    final key = '$_waterLogPrefix${date.year}_${date.month}_${date.day}';
    return _prefs.getInt(key) ?? 0;
  }

  Future<void> addWater(DateTime date, int ml) async {
    final key = '$_waterLogPrefix${date.year}_${date.month}_${date.day}';
    final current = _prefs.getInt(key) ?? 0;
    final updated = (current + ml).clamp(0, 20000);
    await _prefs.setInt(key, updated);
  }

  Future<void> setWater(DateTime date, int ml) async {
    final key = '$_waterLogPrefix${date.year}_${date.month}_${date.day}';
    await _prefs.setInt(key, ml.clamp(0, 20000));
  }

  Future<void> resetWater(DateTime date) async {
    final key = '$_waterLogPrefix${date.year}_${date.month}_${date.day}';
    await _prefs.setInt(key, 0);
  }

  // --- API Key & Settings ---
  String? getCustomApiKey() {
    return _prefs.getString('kalore_gemini_api_key');
  }

  Future<void> setCustomApiKey(String key) async {
    await _prefs.setString('kalore_gemini_api_key', key);
  }

  // --- Theme Mode Settings ('system', 'light', 'dark') ---
  static const String _themeModeKey = 'kalore_theme_mode';

  String getThemeMode() {
    return _prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  // --- EXPORT & IMPORT BACKUP SYSTEM ---
  /// Exports all data (Profile, Food Entries, Water logs) to a single JSON string
  String exportDataAsJson() {
    final profile = getProfile();
    final entries = _cachedEntries.map((e) => e.toJson()).toList();

    final backupPayload = {
      'app': 'Kalore',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'entries': entries,
    };

    return const JsonEncoder.withIndent('  ').convert(backupPayload);
  }

  /// Writes export JSON to a backup file ready for sharing or saving
  Future<File> exportToFile() async {
    final jsonString = exportDataAsJson();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/kalore_backup_$timestamp.json');
    return await file.writeAsString(jsonString);
  }

  /// Restores data from imported JSON string
  Future<bool> importDataFromJson(String jsonContent) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonContent);

      if (data['profile'] != null) {
        final profile = UserProfile.fromJson(
          data['profile'] as Map<String, dynamic>,
        );
        await saveProfile(profile);
      }

      if (data['entries'] != null) {
        final List<dynamic> entriesRaw = data['entries'] as List<dynamic>;
        final importedEntries = entriesRaw
            .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
            .toList();

        // Merge without duplicate IDs
        final existingIds = _cachedEntries.map((e) => e.id).toSet();
        for (final entry in importedEntries) {
          if (!existingIds.contains(entry.id)) {
            _cachedEntries.add(entry);
          }
        }
        await _saveAllFoodEntries();
      }

      return true;
    } catch (e) {
      debugPrint('Error during backup import: $e');
      return false;
    }
  }

  Future<void> clearAllData() async {
    _cachedEntries.clear();
    await _saveAllFoodEntries();
    await _prefs.clear();
  }
}
