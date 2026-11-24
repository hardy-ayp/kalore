import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/apple_colors.dart';
import '../../../core/theme/apple_typography.dart';
import '../../../core/widgets/apple_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../onboarding/presentation/welcome_screen.dart';
import 'legal_document_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _handleExport() async {
    HapticFeedback.lightImpact();
    try {
      final storage = ref.read(storageServiceProvider);
      final file = await storage.exportToFile();

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject:
              'Cadangan Data Kalore (${DateTime.now().toLocal().toString().split(' ')[0]})',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor: $e'),
            backgroundColor: CupertinoColors.destructiveRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleImport() async {
    HapticFeedback.lightImpact();
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'kalore'],
      );

      if (files.isEmpty || files.first.path == null) return;

      final filePath = files.first.path!;
      final content = await File(filePath).readAsString();

      final storage = ref.read(storageServiceProvider);
      final success = await storage.importDataFromJson(content);

      if (mounted) {
        if (success) {
          // Refresh state
          ref.invalidate(userProfileProvider);
          ref.read(dailyFoodEntriesProvider.notifier).refresh();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Data berhasil dipulihkan dari cadangan!'),
              backgroundColor: AppleColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format file cadangan tidak valid.'),
              backgroundColor: CupertinoColors.destructiveRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengimpor: $e'),
            backgroundColor: CupertinoColors.destructiveRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmResetData() {
    HapticFeedback.mediumImpact();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text(
          'Tindakan ini akan menghapus semua riwayat makanan, profil, dan target kalori dari penyimpanan perangkat ini.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final storage = ref.read(storageServiceProvider);
              await storage.clearAllData();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppleColors.backgroundDark
          : AppleColors.backgroundLight,
      body: SafeArea(
        child: ResponsiveContainer(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenBreakpoints.horizontalPadding(context),
            vertical: 12,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Text(
                'Pengaturan',
                style: AppleTypography.largeTitle(isDark: isDark),
              ),
              const SizedBox(height: 18),

              // Account / Profile Status Card
              AppleCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppleColors.primaryGreen.withValues(
                          alpha: isDark ? 0.22 : 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.person_fill,
                        color: isDark
                            ? AppleColors.primaryGreenDark
                            : AppleColors.primaryGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.name ?? 'Tamu Kalore',
                            style: AppleTypography.headline(isDark: isDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile?.isGuest == true
                                ? 'Mode Tamu (Penyimpanan Offline Lokal)'
                                : 'Akun Terhubung (Cloud Sync)',
                            style: AppleTypography.caption(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION: TAMPILAN & TEMA (Apple HIG Dark Mode Switcher)
              _buildSectionHeader('TAMPILAN & TEMA', isDark),
              const SizedBox(height: 8),
              AppleCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSettingsIcon(
                          CupertinoIcons.circle_righthalf_fill,
                          const Color(0xFF5856D6), // Apple Purple
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode Tampilan',
                                style: AppleTypography.headline(isDark: isDark),
                              ),
                              Text(
                                currentThemeMode == ThemeMode.system
                                    ? 'Mengikuti pengaturan sistem HP'
                                    : (currentThemeMode == ThemeMode.dark
                                          ? 'Mode Gelap (OLED True Black aktif)'
                                          : 'Mode Terang aktif'),
                                style: AppleTypography.caption(isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<ThemeMode>(
                        groupValue: currentThemeMode,
                        backgroundColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        thumbColor: isDark
                            ? const Color(0xFF636366)
                            : Colors.white,
                        children: {
                          ThemeMode.system: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.device_phone_portrait,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sistem',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        currentThemeMode == ThemeMode.system
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ThemeMode.light: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.sun_max_fill,
                                  size: 16,
                                  color: AppleColors.carbsYellow,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Terang',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        currentThemeMode == ThemeMode.light
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ThemeMode.dark: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.moon_fill,
                                  size: 16,
                                  color: Color(0xFF5E5CE6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Gelap',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        currentThemeMode == ThemeMode.dark
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        },
                        onValueChanged: (mode) {
                          if (mode != null) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(mode);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION: Backup & Restore (Export / Import)
              _buildSectionHeader('CADANGKAN & PULIHKAN DATA', isDark),
              const SizedBox(height: 8),
              AppleCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: _buildSettingsIcon(
                        CupertinoIcons.share,
                        AppleColors.waterBlue,
                        isDark,
                      ),
                      title: Text(
                        'Ekspor Data (JSON Backup)',
                        style: AppleTypography.body(isDark: isDark),
                      ),
                      subtitle: Text(
                        'Simpan atau bagikan file cadangan lokal',
                        style: AppleTypography.caption(isDark: isDark),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_forward,
                        size: 14,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                      onTap: _handleExport,
                    ),
                    const Divider(height: 0.5, indent: 56),
                    ListTile(
                      leading: _buildSettingsIcon(
                        CupertinoIcons.tray_arrow_down,
                        AppleColors.calorieOrange,
                        isDark,
                      ),
                      title: Text(
                        'Impor Data (Pulihkan Cadangan)',
                        style: AppleTypography.body(isDark: isDark),
                      ),
                      subtitle: Text(
                        'Pilih file .json atau .kalore dari penyimpanan',
                        style: AppleTypography.caption(isDark: isDark),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_forward,
                        size: 14,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                      onTap: _handleImport,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION: AI Engine Status
              _buildSectionHeader('KECERDASAN BUATAN KALORE', isDark),
              const SizedBox(height: 8),
              AppleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSettingsIcon(
                          CupertinoIcons.sparkles,
                          AppleColors.primaryGreen,
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kalore AI Aktif',
                                style: AppleTypography.headline(isDark: isDark)
                                    .copyWith(
                                      color: isDark
                                          ? AppleColors.primaryGreenDark
                                          : AppleColors.primaryGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                'Terhubung & siap menganalisis porsi makanan',
                                style: AppleTypography.caption(isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppleColors.primaryGreen.withValues(
                              alpha: isDark ? 0.22 : 0.14,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'ONLINE',
                            style: AppleTypography.caption2(isDark: isDark)
                                .copyWith(
                                  color: isDark
                                      ? AppleColors.primaryGreenDark
                                      : AppleColors.primaryGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 0.5),
                    const SizedBox(height: 12),
                    _buildFeatureStatusRow(
                      icon: CupertinoIcons.camera_viewfinder,
                      title: 'Pemindai Visual Makanan',
                      status: 'Pindai Foto Piring & Resep',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureStatusRow(
                      icon: CupertinoIcons.chart_pie_fill,
                      title: 'Kalkulasi Nutrisi Pintar',
                      status: 'BMR, TDEE & Makronutrisi',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureStatusRow(
                      icon: CupertinoIcons.lock_shield_fill,
                      title: 'Privasi & Keamanan',
                      status: 'Pemrosesan Privat Terlindungi',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION: Legal & Compliance (Medical Disclaimer, Terms, Privacy)
              _buildSectionHeader('HUKUM & REGULASI', isDark),
              const SizedBox(height: 8),
              AppleCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: _buildSettingsIcon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        AppleColors.calorieOrange,
                        isDark,
                      ),
                      title: Text(
                        'Penafian Medis & Kesehatan',
                        style: AppleTypography.body(isDark: isDark),
                      ),
                      subtitle: Text(
                        'Pemberitahuan hukum & batasan tanggung jawab',
                        style: AppleTypography.caption(isDark: isDark),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_forward,
                        size: 14,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) =>
                                const LegalDocumentScreen(initialTabIndex: 0),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 0.5, indent: 56),
                    ListTile(
                      leading: _buildSettingsIcon(
                        CupertinoIcons.doc_text_fill,
                        AppleColors.waterBlue,
                        isDark,
                      ),
                      title: Text(
                        'Syarat & Ketentuan Layanan',
                        style: AppleTypography.body(isDark: isDark),
                      ),
                      subtitle: Text(
                        'Ketentuan penggunaan & lisensi aplikasi',
                        style: AppleTypography.caption(isDark: isDark),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_forward,
                        size: 14,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) =>
                                const LegalDocumentScreen(initialTabIndex: 1),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 0.5, indent: 56),
                    ListTile(
                      leading: _buildSettingsIcon(
                        CupertinoIcons.lock_shield_fill,
                        AppleColors.primaryGreen,
                        isDark,
                      ),
                      title: Text(
                        'Kebijakan Privasi',
                        style: AppleTypography.body(isDark: isDark),
                      ),
                      subtitle: Text(
                        'Penyimpanan lokal & perlindungan data',
                        style: AppleTypography.caption(isDark: isDark),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.chevron_forward,
                        size: 14,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) =>
                                const LegalDocumentScreen(initialTabIndex: 2),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 0.5, indent: 56),
                    ListTile(
                      leading: _buildSettingsIcon(
                        CupertinoIcons.info_circle_fill,
                        AppleColors.carbsYellow,
                        isDark,
                      ),
                      title: Text(
                        'Tentang Kalore',
                        style: AppleTypography.body(isDark: isDark),
                      ),
                      subtitle: Text(
                        'Dirancang dengan Apple Human Interface Guidelines',
                        style: AppleTypography.caption(isDark: isDark),
                      ),
                      trailing: Text(
                        'v${ApiConfig.appVersionName}',
                        style: AppleTypography.caption(
                          isDark: isDark,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECTION: Reset Data
              _buildSectionHeader('ZONA PENGATURAN DATA', isDark),
              const SizedBox(height: 8),
              AppleCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: _buildSettingsIcon(
                    CupertinoIcons.trash,
                    CupertinoColors.destructiveRed,
                    isDark,
                  ),
                  title: Text(
                    'Hapus Semua Data & Reset',
                    style: AppleTypography.body(isDark: isDark).copyWith(
                      color: CupertinoColors.destructiveRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 14,
                    color: CupertinoColors.tertiaryLabel,
                  ),
                  onTap: _confirmResetData,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: AppleTypography.caption2(
        isDark: isDark,
      ).copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildSettingsIcon(IconData icon, Color color, bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _buildFeatureStatusRow({
    required IconData icon,
    required String title,
    required String status,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark
              ? AppleColors.primaryGreenDark
              : AppleColors.primaryGreen,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppleTypography.footnote(
              isDark: isDark,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(status, style: AppleTypography.caption(isDark: isDark)),
      ],
    );
  }
}
