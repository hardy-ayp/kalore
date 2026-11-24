import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/providers/app_providers.dart';
import 'core/services/storage_service.dart';
import 'core/theme/apple_theme.dart';
import 'features/onboarding/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for dates
  await initializeDateFormatting('id_ID', null);

  // Initialize Offline-first Storage Service
  final storageService = StorageService();
  await storageService.init();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const KaloreApp(),
    ),
  );
}

class KaloreApp extends ConsumerWidget {
  const KaloreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Kalore',
      debugShowCheckedModeBanner: false,
      theme: AppleTheme.lightTheme(),
      darkTheme: AppleTheme.darkTheme(),
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
