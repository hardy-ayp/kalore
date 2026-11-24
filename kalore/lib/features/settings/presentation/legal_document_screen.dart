import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/apple_colors.dart';
import '../../../core/theme/apple_typography.dart';
import '../../../core/widgets/apple_card.dart';
import '../../../core/widgets/responsive_layout.dart';

/// Full Apple HIG Legal & Compliance Screen.
/// Shields developer and app from lawsuits with comprehensive Medical Disclaimer,
/// Terms of Service, and Privacy Policy.
class LegalDocumentScreen extends StatefulWidget {
  final int initialTabIndex; // 0: Medis, 1: Syarat, 2: Privasi

  const LegalDocumentScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Navigation Bar
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.chevron_back,
                          color: isDark
                              ? AppleColors.primaryGreenDark
                              : AppleColors.primaryGreen,
                          size: 26,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: 17,
                            color: isDark
                                ? AppleColors.primaryGreenDark
                                : AppleColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    size: 22,
                    color: isDark
                        ? AppleColors.primaryGreenDark
                        : AppleColors.primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                'Informasi Hukum',
                style: AppleTypography.largeTitle(isDark: isDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Penafian Medis, Ketentuan Layanan, & Kebijakan Privasi Kalore.',
                style: AppleTypography.caption(isDark: isDark),
              ),
              const SizedBox(height: 16),

              // Segmented Tab Selector
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedTab,
                  backgroundColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                  thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Penafian Medis',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedTab == 0
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Syarat Layanan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedTab == 1
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    2: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Kebijakan Privasi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedTab == 2
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = val);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable Document Content
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (_selectedTab == 0) _buildMedicalDisclaimer(isDark),
                    if (_selectedTab == 1) _buildTermsOfService(isDark),
                    if (_selectedTab == 2) _buildPrivacyPolicy(isDark),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Kalore v1.0.0 • Pembaruan Terakhir: Oktober 2026\nSeluruh hak cipta dilindungi undang-undang.',
                        textAlign: TextAlign.center,
                        style: AppleTypography.caption2(isDark: isDark),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. PENAFIAN MEDIS & KESEHATAN (CRITICAL LEGAL SHIELD)
  Widget _buildMedicalDisclaimer(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // High-Priority Alert Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppleColors.calorieOrange.withValues(
              alpha: isDark ? 0.20 : 0.12,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppleColors.calorieOrange.withValues(
                alpha: isDark ? 0.6 : 0.4,
              ),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: AppleColors.calorieOrange,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PEMBERITAHUAN MEDIS WAJIB',
                      style: AppleTypography.headline(isDark: isDark).copyWith(
                        color: AppleColors.calorieOrange,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kalore BUKAN merupakan perangkat medis, penyedia layanan kesehatan, dokter, atau ahli gizi berlisensi. Aplikasi ini dirancang murni sebagai alat bantu pencatatan gaya hidup dan edukasi nutrisi.',
                      style: AppleTypography.footnote(
                        isDark: isDark,
                      ).copyWith(fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '1. Sifat Estimasi Matematika & Algoritma',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Semua data angka di dalam Kalore—termasuk estimasi kalori harian, Basal Metabolic Rate (BMR), Total Daily Energy Expenditure (TDEE), target makronutrisi (karbohidrat, protein, dan lemak), serta hasil pengenalan citra makanan oleh sistem kecerdasan buatan—merupakan hasil estimasi teoritis dan formula standar populasi umum.\n\nNilai tersebut TIDAK BOLEH dianggap sebagai diagnosis, instruksi medis mutlak, atau resep terapi klinis.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '2. Peringatan untuk Kondisi Kesehatan Khusus',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Anda WAJIB berkonsultasi dengan dokter umum atau dokter spesialis gizi klinis sebelum menggunakan aplikasi ini jika Anda memiliki atau sedang dalam kondisi:',
                style: AppleTypography.body(isDark: isDark),
              ),
              const SizedBox(height: 10),
              _buildBulletPoint(
                'Sedang hamil, merencanakan kehamilan, atau menyusui.',
                isDark,
              ),
              _buildBulletPoint(
                'Mengidap diabetes mellitus (Tipe 1 atau Tipe 2).',
                isDark,
              ),
              _buildBulletPoint(
                'Memiliki riwayat penyakit ginjal, liver, kardiovaskular, atau hipertensi berat.',
                isDark,
              ),
              _buildBulletPoint(
                'Memiliki riwayat atau kecenderungan gangguan perilaku makan (eating disorders) seperti anoreksia nervosa, bulimia, atau binge eating disorder.',
                isDark,
              ),
              _buildBulletPoint(
                'Berusia di bawah 18 tahun atau lanjut usia.',
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '3. Pembebasan Tanggung Jawab Hukum Penuh',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Dengan mengunduh dan menggunakan Kalore, Anda secara sadar dan sukarela mengakui bahwa seluruh keputusan pola makan, restriksi kalori, asupan suplemen, serta program kebugaran adalah tanggung jawab pribadi Anda seutuhnya.\n\nPengembang aplikasi Kalore, mitra, serta kontributor dibebaskan sepenuhnya dari segala bentuk tuntutan hukum, klaim ganti rugi, tanggung jawab perdata maupun pidana, atas segala kerugian kesehatan fisik atau mental, malnutrisi, kelelahan, dehidrasi, cedera, komplikasi medis, atau perubahan berat badan yang dialami pengguna baik secara langsung maupun tidak langsung.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '4. Kondisi Kegawatdaruratan Medis',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Jika Anda mengalami pusing mendadak, pandangan kabur, lemas luar biasa, palpitasi jantung, pingsan, hipoglikemia, atau gejala darurat lainnya saat menjalankan diet, segera hentikan pembatasan kalori dan hubungi Unit Gawat Darurat (UGD) atau fasilitas kesehatan medis terdekat.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. SYARAT & KETENTUAN LAYANAN (TERMS OF SERVICE)
  Widget _buildTermsOfService(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '1. Penerimaan Syarat & Perjanjian',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Dengan mengakses, mengunduh, atau menggunakan aplikasi Kalore ("Layanan"), Anda menyatakan telah membaca, memahami, dan menyetujui untuk terikat secara hukum oleh Syarat dan Ketentuan ini. Jika Anda tidak menyetujui salah satu klausul dalam dokumen ini, Anda tidak diperkenankan menggunakan Layanan ini dan dipersilakan menghapus aplikasi dari perangkat Anda.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '2. Hak Kekayaan Intelektual & Lisensi Penggunaan',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Pengembang memberikan kepada Anda lisensi terbatas, non-eksklusif, tidak dapat dialihkan, dan dapat dibatalkan semata-mata untuk penggunaan pribadi dan non-komersial.\n\nSeluruh hak cipta desain antarmuka bergaya Apple HIG, grafis, arsitektur kode sumber, modul algoritma, dan merek dagang Kalore adalah milik sah pengembang Kalore dan dilindungi oleh regulasi hak cipta internasional. Dilarang merekayasa balik (reverse-engineering), menyalin, membongkar, atau mendistribusikan ulang kode tanpa izin tertulis.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '3. Akurasi Fitur Pemindai Citra & Nutrisi',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Fitur pemindai foto makanan dan estimasi deskripsi menu dioperasikan menggunakan model komputasi cerdas. Anda memahami bahwa:\n\n• Pengenalan visual sangat dipengaruhi oleh sudut pemotretan, pencahayaan, bumbu tersembunyi (seperti minyak goreng, margarin, santan, atau gula), serta variasi resep lokal.\n• Anda memiliki hak dan kewajiban penuh untuk meninjau dan menyesuaikan gramatur serta komponen hidangan di lembar Tinjauan Porsi (Portion Review) sebelum menyimpannya ke buku harian nutrisi.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading('4. Penafian Jaminan ("As Is")', isDark),
              const SizedBox(height: 8),
              Text(
                'Layanan disediakan atas dasar "SEBAGAIMANA ADANYA" (AS-IS) dan "SEBAGAIMANA TERSEDIA" (AS-AVAILABLE) tanpa jaminan apa pun, baik tersurat maupun tersirat, mengenai ketepatan waktu, ketiadaan kesalahan, atau ketercapaian target berat badan atau bentuk tubuh tertentu.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading('5. Hukum yang Berlaku', isDark),
              const SizedBox(height: 8),
              Text(
                'Syarat dan Ketentuan ini diatur dan ditafsirkan sesuai dengan hukum yang berlaku di yurisdiksi Republik Indonesia. Setiap perselisihan yang timbul akan diselesaikan secara musyawarah mufakat terlebih dahulu.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. KEBIJAKAN PRIVASI (PRIVACY POLICY)
  Widget _buildPrivacyPolicy(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Privacy Hero Badge
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppleColors.primaryGreen.withValues(
              alpha: isDark ? 0.20 : 0.12,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppleColors.primaryGreen.withValues(
                alpha: isDark ? 0.6 : 0.4,
              ),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.lock_shield_fill,
                color: isDark
                    ? AppleColors.primaryGreenDark
                    : AppleColors.primaryGreen,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KOMITMEN PRIVASI TERTINGGI',
                      style: AppleTypography.headline(isDark: isDark).copyWith(
                        color: isDark
                            ? AppleColors.primaryGreenDark
                            : AppleColors.primaryGreen,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Data makanan, kalori, dan berat badan Anda adalah milik Anda sepenuhnya. Kami menjunjung tinggi filosofi privasi Apple dengan arsitektur 100% Offline-First.',
                      style: AppleTypography.footnote(isDark: isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '1. Penyimpanan Data Lokal Mandiri',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Secara default saat menggunakan mode Tamu (Offline), seluruh catatan konsumsi makanan harian, profil fisik (tinggi, berat badan, usia), serta riwayat log nutrisi disimpan murni secara lokal di dalam penyimpanan terenkripsi perangkat (on-device local storage).\n\nKami TIDAK mengumpulkan, TIDAK melacak, dan TIDAK menjual data pribadi maupun data kesehatan Anda kepada pengiklan, pialang data, atau pihak ketiga mana pun.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '2. Pemrosesan Citra Kamera & Deskripsi Makanan',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Ketika Anda mengambil foto piring makanan atau mengetik menu hidangan untuk dianalisis:\n\n• Citra dan teks tersebut dikirimkan melalui jalur aman (HTTPS/TLS) semata-mata untuk membedah komposisi gizi dan memperkirakan takaran porsi.\n• Citra Anda tidak disimpan secara permanen di server publik dan tidak dikaitkan dengan identitas nama asli Anda.\n• Kalore tidak mengakses galeri atau kamera Anda di latar belakang (background) tanpa tindakan langsung dari Anda.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '3. Hak Pengguna: Ekspor & Pemulihan Cadangan',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Anda memiliki kebebasan penuh atas data Anda (Data Portability). Melalui fitur "Ekspor Data" di menu Pengaturan, Anda dapat mengunduh seluruh basis data Anda dalam format file JSON terbuka yang dapat dibaca kapan saja, dan memulihkannya kembali lewat fitur "Impor Data".',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '4. Hak Pengguna: Penghapusan Data Permanen',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Anda dapat menghapus seluruh riwayat konsumsi, profil, dan target kalori kapan pun Anda inginkan melalui menu "Hapus Semua Data & Reset" di menu Pengaturan. Tindakan ini akan melenyapkan seluruh database lokal tanpa jejak.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegalSubheading(
                '5. Nol Pelacak Iklan (Zero Ad-Trackers)',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                'Kalore tidak menyematkan Software Development Kit (SDK) pelacakan iklan invasif dari pihak ketiga. Aktivitas kebugaran Anda bersifat rahasia dan intim bagi diri Anda sendiri.',
                style: AppleTypography.body(isDark: isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSubheading(String title, bool isDark) {
    return Text(
      title,
      style: AppleTypography.headline(
        isDark: isDark,
      ).copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildBulletPoint(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7, right: 10),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppleColors.primaryGreenDark
                  : AppleColors.primaryGreen,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppleTypography.body(
                isDark: isDark,
              ).copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
