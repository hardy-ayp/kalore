import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/theme/apple_colors.dart';
import '../../../core/theme/apple_typography.dart';
import '../../../core/widgets/apple_button.dart';
import '../../../core/widgets/apple_card.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../models/food_entry.dart';
import 'portion_review_sheet.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final String initialMealType;

  const ScanScreen({
    super.key,
    this.initialTab = 0,
    this.initialMealType = 'lunch',
  });

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  late int _selectedTab; // 0 = Foto, 1 = Teks AI, 2 = Manual
  late String _manualMealType;
  bool _isAnalyzing = false;
  String _statusMessage = 'Menyiapkan pemindai AI...';

  // Text AI & Photo Note controllers
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _photoNoteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Manual inputs controllers
  final TextEditingController _manualNameController = TextEditingController();
  final TextEditingController _manualPortionController = TextEditingController(text: '1 Porsi (150g)');
  final TextEditingController _manualCaloriesController = TextEditingController();
  final TextEditingController _manualProteinController = TextEditingController();
  final TextEditingController _manualCarbsController = TextEditingController();
  final TextEditingController _manualFatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _manualMealType = widget.initialMealType;
  }

  @override
  void dispose() {
    _textController.dispose();
    _photoNoteController.dispose();
    _manualNameController.dispose();
    _manualPortionController.dispose();
    _manualCaloriesController.dispose();
    _manualProteinController.dispose();
    _manualCarbsController.dispose();
    _manualFatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Kompresi 70% untuk foto kamera & galeri
        maxWidth: 1024,   // Skalakan resolusi maksimal 1024px
        maxHeight: 1024,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final sizeKb = (bytes.length / 1024).round();
      final sourceLabel = source == ImageSource.camera ? 'Kamera Langsung' : 'Galeri';

      setState(() {
        _isAnalyzing = true;
        _statusMessage = 'Foto $sourceLabel dikompres ($sizeKb KB).\nAI sedang memindai piring makanan...';
      });

      final mimeType = GeminiService.detectMimeType(bytes);
      final gemini = ref.read(geminiServiceProvider);
      final userNote = _photoNoteController.text.trim().isNotEmpty
          ? _photoNoteController.text.trim()
          : null;

      final entry = await gemini.analyzeFoodImage(
        imageBytes: bytes,
        mimeType: mimeType,
        userNote: userNote,
        mealType: _manualMealType,
      );

      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showReviewSheet(entry);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _promptForDishNameAfterFailedPhoto();
      }
    }
  }

  void _promptForDishNameAfterFailedPhoto() {
    final controller = TextEditingController(text: _photoNoteController.text);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Identifikasi Hidangan'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Server visual AI sedang padat. Masukkan nama hidangan (contoh: Nasi Ayam Bakar, Salmon Mentai, Mie Goreng) untuk kalkulasi instan via CalorieAPI & CalorieNinjas:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: 'Nama hidangan...',
              autofocus: true,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Analisis Sekarang'),
            onPressed: () async {
              final query = controller.text.trim();
              Navigator.of(ctx).pop();
              if (query.isNotEmpty) {
                setState(() {
                  _isAnalyzing = true;
                  _statusMessage = 'Mencari nutrisi di CalorieAPI & CalorieNinjas...';
                });
                try {
                  final gemini = ref.read(geminiServiceProvider);
                  final entry = await gemini.analyzeFoodText(
                    textDescription: query,
                    mealType: _manualMealType,
                  );
                  if (mounted) {
                    setState(() => _isAnalyzing = false);
                    _showReviewSheet(entry);
                  }
                } catch (err) {
                  if (mounted) {
                    setState(() => _isAnalyzing = false);
                    _showErrorSnackBar(err.toString());
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeText() async {
    HapticFeedback.lightImpact();
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'AI sedang menganalisis porsi makanan...';
    });

    try {
      final gemini = ref.read(geminiServiceProvider);
      final entry = await gemini.analyzeFoodText(
        textDescription: text,
        mealType: _manualMealType,
      );

      if (mounted) {
        setState(() => _isAnalyzing = false);
        _textController.clear();
        _showReviewSheet(entry);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showErrorSnackBar(e.toString());
      }
    }
  }

  void _calculateCaloriesFromMacros() {
    HapticFeedback.lightImpact();
    final p = double.tryParse(_manualProteinController.text.trim()) ?? 0.0;
    final c = double.tryParse(_manualCarbsController.text.trim()) ?? 0.0;
    final f = double.tryParse(_manualFatController.text.trim()) ?? 0.0;

    final cals = (p * 4.0 + c * 4.0 + f * 9.0).round();
    _manualCaloriesController.text = cals.toString();
  }

  void _saveManualEntry() {
    HapticFeedback.mediumImpact();
    final name = _manualNameController.text.trim();
    if (name.isEmpty) {
      _showErrorSnackBar('Mohon masukkan nama makanan');
      return;
    }

    final cals = int.tryParse(_manualCaloriesController.text.trim()) ?? 0;
    final p = double.tryParse(_manualProteinController.text.trim()) ?? 0.0;
    final c = double.tryParse(_manualCarbsController.text.trim()) ?? 0.0;
    final f = double.tryParse(_manualFatController.text.trim()) ?? 0.0;
    final portion = _manualPortionController.text.trim().isEmpty
        ? '1 Porsi'
        : _manualPortionController.text.trim();

    final entry = FoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mealType: _manualMealType,
      name: name,
      calories: cals,
      proteinG: p,
      carbsG: c,
      fatG: f,
      portionDescription: portion,
      items: [
        FoodSubItem(
          name: name,
          portion: portion,
          calories: cals,
          proteinG: p,
          carbsG: c,
          fatG: f,
        ),
      ],
      notes: 'Dicatat manual oleh pengguna.',
      confidenceScore: 1.0,
    );

    ref.read(dailyFoodEntriesProvider.notifier).addEntry(entry);

    _manualNameController.clear();
    _manualCaloriesController.clear();
    _manualProteinController.clear();
    _manualCarbsController.clear();
    _manualFatController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name berhasil dicatat!'),
        backgroundColor: AppleColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showReviewSheet(FoodEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PortionReviewSheet(
        initialEntry: entry,
        onSave: (savedEntry) {
          ref.read(dailyFoodEntriesProvider.notifier).addEntry(savedEntry);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${savedEntry.name} berhasil dicatat!'),
              backgroundColor: AppleColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pemberitahuan: $msg'),
        backgroundColor: CupertinoColors.destructiveRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppleColors.backgroundDark
          : AppleColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Catat Nutrisi & Kalori',
          style: AppleTypography.headline(isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: EdgeInsets.symmetric(
            horizontal: ScreenBreakpoints.horizontalPadding(context),
            vertical: 12,
          ),
          child: Column(
            children: [
              // Segmented Control (Apple 3-Way Selector)
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedTab,
                  backgroundColor: isDark
                      ? AppleColors.surfaceSecondaryDark
                      : AppleColors.surfaceSecondaryLight,
                  thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.camera_fill, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              'Foto Kamera',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedTab == 0
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.sparkles, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              'Deskripsi AI',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedTab == 1
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    2: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              'Input Manual',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedTab == 2
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
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

              // Dynamic Island Loading Banner
              if (_isAnalyzing) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppleColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isDark
                        ? Border.all(
                            color: AppleColors.cardBorderDark,
                            width: 0.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppleColors.primaryGreen.withValues(alpha: 0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CupertinoActivityIndicator(
                        radius: 10,
                        color: isDark
                            ? AppleColors.primaryGreenDark
                            : AppleColors.primaryGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: AppleTypography.callout(isDark: isDark)
                              .copyWith(
                                color: isDark
                                    ? AppleColors.primaryGreenDark
                                    : AppleColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Expanded(
                child: _buildCurrentTab(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(bool isDark) {
    switch (_selectedTab) {
      case 0:
        return _buildPhotoTab(isDark);
      case 1:
        return _buildTextTab(isDark);
      case 2:
        return _buildManualTab(isDark);
      default:
        return _buildPhotoTab(isDark);
    }
  }

  Widget _buildPhotoTab(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        AppleCard(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppleColors.primaryGreen.withValues(
                    alpha: isDark ? 0.22 : 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.camera_fill,
                  size: 42,
                  color: isDark
                      ? AppleColors.primaryGreenDark
                      : AppleColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Foto Piring Makananmu',
                style: AppleTypography.title2(isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Pemindai visual AI mengenali nama hidangan spesifik, rincian komponen kasat mata, metode masak, serta estimasi porsi & bumbu tersembunyi.',
                  textAlign: TextAlign.center,
                  style: AppleTypography.callout(isDark: isDark),
                ),
              ),
              const SizedBox(height: 18),
              // Optional note input for photo
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppleColors.surfaceSecondaryDark
                      : AppleColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppleColors.cardBorderDark
                        : AppleColors.separatorLight,
                    width: 0.5,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.chat_bubble_text,
                      size: 16,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _photoNoteController,
                        style: AppleTypography.body(isDark: isDark)
                            .copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'Catatan opsional (misal: paha bakar, tanpa kulit)',
                          hintStyle: AppleTypography.caption(isDark: isDark),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: AppleButton(
                backgroundColor: isDark
                    ? AppleColors.primaryGreenDark
                    : AppleColors.primaryGreen,
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.camera, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Buka Kamera',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppleButton(
                isSecondary: true,
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.photo, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Dari Galeri',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextTab(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ketik Menu Makanan Bebas',
                style: AppleTypography.headline(isDark: isDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Contoh: "Makan siang nasi uduk 1 porsi, telur balado 1 butir, bihun goreng, sambal, es jeruk tanpa gula"',
                style: AppleTypography.caption(isDark: isDark),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _textController,
                maxLines: 4,
                placeholder: 'Ketik apa saja yang baru kamu makan...',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppleColors.surfaceSecondaryDark
                      : AppleColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: isDark
                      ? Border.all(
                          color: AppleColors.cardBorderDark,
                          width: 0.5,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 18),
              AppleButton(
                backgroundColor: isDark
                    ? AppleColors.primaryGreenDark
                    : AppleColors.primaryGreen,
                onPressed: _analyzeText,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Analisis Kalori dengan AI',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 3: INPUT MANUAL MAKANAN
  Widget _buildManualTab(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        AppleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entri Makanan Mandiri',
                style: AppleTypography.headline(isDark: isDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Catat kalori & makronutrisi secara langsung tanpa pemindai AI.',
                style: AppleTypography.caption(isDark: isDark),
              ),
              const SizedBox(height: 16),

              // Meal Category Selector
              Text('JADWAL MAKAN', style: AppleTypography.caption2(isDark: isDark)),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _manualMealType,
                  backgroundColor: isDark
                      ? AppleColors.surfaceSecondaryDark
                      : AppleColors.surfaceSecondaryLight,
                  thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
                  children: {
                    'breakfast': _buildMealSegmentItem('🍳 Sarapan', isDark),
                    'lunch': _buildMealSegmentItem('🍗 Siang', isDark),
                    'dinner': _buildMealSegmentItem('🍲 Malam', isDark),
                    'snack': _buildMealSegmentItem('☕ Camilan', isDark),
                  },
                  onValueChanged: (val) {
                    if (val != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _manualMealType = val);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Food Name Field
              Text('NAMA MAKANAN', style: AppleTypography.caption2(isDark: isDark)),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _manualNameController,
                placeholder: 'Misal: Dada Ayam Panggang + Nasi Merah',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                padding: const EdgeInsets.all(12),
                decoration: _fieldDecoration(isDark),
              ),
              const SizedBox(height: 12),

              // Portion Field
              Text('TAKASAN / PORSI', style: AppleTypography.caption2(isDark: isDark)),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _manualPortionController,
                placeholder: 'Misal: 1 Porsi (200g)',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                padding: const EdgeInsets.all(12),
                decoration: _fieldDecoration(isDark),
              ),
              const SizedBox(height: 16),

              // Nutrition Fields Grid
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KALORI (KKAL)', style: AppleTypography.caption2(isDark: isDark)),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _manualCaloriesController,
                          keyboardType: TextInputType.number,
                          placeholder: '0',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: _fieldDecoration(isDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROTEIN (G)', style: AppleTypography.caption2(isDark: isDark)),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _manualProteinController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          placeholder: '0.0',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          padding: const EdgeInsets.all(12),
                          decoration: _fieldDecoration(isDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KARBOHIDRAT (G)', style: AppleTypography.caption2(isDark: isDark)),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _manualCarbsController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          placeholder: '0.0',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          padding: const EdgeInsets.all(12),
                          decoration: _fieldDecoration(isDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LEMAK (G)', style: AppleTypography.caption2(isDark: isDark)),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: _manualFatController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          placeholder: '0.0',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          padding: const EdgeInsets.all(12),
                          decoration: _fieldDecoration(isDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Auto-Calculate button
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _calculateCaloriesFromMacros,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.wand_stars, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Hitung Kalori dari Makro',
                        style: AppleTypography.caption(isDark: isDark).copyWith(
                          color: isDark
                              ? AppleColors.primaryGreenDark
                              : AppleColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              AppleButton(
                backgroundColor: isDark
                    ? AppleColors.primaryGreenDark
                    : AppleColors.primaryGreen,
                onPressed: _saveManualEntry,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Simpan ke Buku Harian',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMealSegmentItem(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark
          ? AppleColors.surfaceSecondaryDark
          : AppleColors.surfaceSecondaryLight,
      borderRadius: BorderRadius.circular(12),
      border: isDark
          ? Border.all(
              color: AppleColors.cardBorderDark,
              width: 0.5,
            )
          : null,
    );
  }
}
