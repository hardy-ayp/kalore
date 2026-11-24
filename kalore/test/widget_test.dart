import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalore/core/providers/app_providers.dart';
import 'package:kalore/core/services/storage_service.dart';
import 'package:kalore/features/history/presentation/history_screen.dart';
import 'package:kalore/features/settings/presentation/legal_document_screen.dart';
import 'package:kalore/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Kalore app smoke test and splash transition', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: KaloreApp()));

    // Verify SplashScreen with Kalore branding renders
    expect(find.text('Kalore'), findsWidgets);

    // Advance time past the splash preload timer and transition
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump(const Duration(milliseconds: 600));

    // Verify it transitioned to WelcomeScreen
    expect(find.text('Mulai Sebagai Tamu (Offline)'), findsOneWidget);
    expect(find.textContaining('Penafian Medis Kalore'), findsOneWidget);
  });

  testWidgets('LegalDocumentScreen renders all 3 tabs properly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LegalDocumentScreen(initialTabIndex: 0)),
    );

    // Tab 0: Penafian Medis
    expect(find.text('Informasi Hukum'), findsOneWidget);
    expect(find.text('PEMBERITAHUAN MEDIS WAJIB'), findsOneWidget);
    expect(
      find.textContaining('BUKAN merupakan perangkat medis'),
      findsOneWidget,
    );

    // Switch to Tab 1: Syarat Layanan
    await tester.tap(find.text('Syarat Layanan'));
    await tester.pumpAndSettle();
    expect(find.text('1. Penerimaan Syarat & Perjanjian'), findsOneWidget);

    // Switch to Tab 2: Privasi
    await tester.tap(find.text('Kebijakan Privasi'));
    await tester.pumpAndSettle();
    expect(find.text('KOMITMEN PRIVASI TERTINGGI'), findsOneWidget);
    expect(find.text('1. Penyimpanan Data Lokal Mandiri'), findsOneWidget);
  });

  testWidgets('HistoryScreen renders recap cards and segmented filter', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs: prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storageService)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Riwayat & Rekap'), findsOneWidget);
    expect(find.text('7 Hari'), findsOneWidget);
    expect(find.text('30 Hari'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('RATA-RATA KALORI'), findsOneWidget);
    expect(find.text('Tren Kalori Harian'), findsOneWidget);
    expect(find.text('Rata-rata Sebaran Makronutrisi'), findsOneWidget);
  });
}
