# Kalore 🍏
### Premium Apple-Grade AI Calorie & Macro Tracker for Athletes & Fitness Enthusiasts

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.3.0%2B5-emerald.svg)](pubspec.yaml)
[![Tests](https://img.shields.io/badge/Tests-23%2F23%20Passed-brightgreen.svg)](test/)

---

## 📖 Overview

**Kalore** is a high-performance, privacy-first calorie and macronutrient tracking application built with Flutter. Inspired by Apple Fitness and iOS design principles, Kalore combines fluid gestures, true-black OLED aesthetics, and a multi-tiered nutritional intelligence pipeline to make daily nutrition tracking effortless and accurate.

Whether you are an athlete executing an aggressive cut, preparing for a competition, or simply maintaining a healthy lifestyle, Kalore gives you medical-grade precision calculations (Mifflin-St Jeor + dynamic surplus/deficit models) paired with computer vision food analysis.

---

## ✨ Key Features

### 1. 🍎 Apple Fitness-Grade UI & Motion
- **Concentric Activity Rings**: Visual progress rings for Calories, Protein, Carbohydrates, and Fats with glowing endpoints and spring physics.
- **Gesture-Driven Experience**: Interactive swiping between Daily Summary, AI Meal Planner, and History screens.
- **OLED Pure Black Dark Mode**: High-contrast, energy-efficient true-black interface crafted per Apple Human Interface Guidelines (HIG).

### 2. 📸 Multimodal Computer Vision & Nutrition Pipeline
- **Direct Visual Food Recognition**: Identifies culinary dishes, cooking methods (grilled, roasted, fried), visual cues, and athlete dietary advice from photos.
- **Smart Image Compression**: Automatic on-device compression and byte-budgeting for camera snapshots and gallery uploads to minimize latency and bandwidth.
- **Multi-Tier Engine with Automatic Fallback**:
  - **Tier 1**: CalorieAPI direct culinary search.
  - **Tier 2**: CalorieNinjas natural language processing & image text OCR.
  - **Tier 3**: Google Gemini Generative AI (multimodal vision & structured JSON).
  - **Tier 4**: On-Device Smart Nutrition Heuristics (100% offline, zero-network required).

### 3. ⚡ Dynamic Athlete Diet Engine
- **Aggressive Cutting & Bulking Formulas**: Custom target calorie and macro generation tailored to specific target durations (e.g., cutting 10 kg in 4 weeks with safe minimum metabolic thresholds).
- **Medical BMR & TDEE Calculations**: Accurate energy expenditure formulas based on user gender, age, height, weight, and activity multipliers.

### 4. 💧 Water Intake & Hydration Tracker
- Quick-tap water logging (250ml quick-add or custom manual input) with real-time hydration progress.

### 5. 📊 Interactive Recap & History
- Detailed transaction log of tracked meals, segmented day/week filters, and macro balance summaries.

### 6. 🛡️ Zero-Leak Open-Source Security
- **No Hardcoded Secrets**: Zero API keys or private credentials in the source code.
- **Runtime Environment Injection**: Full support for `--dart-define` and `--dart-define-from-file=env.json`.
- **In-App BYOK (Bring Your Own Key)**: Users can supply their personal API keys in settings, saved exclusively in secure local device storage.
- **Full Legal Readiness**: Built-in Terms of Service, Privacy Policy, and Medical Disclaimer screens.

---

## 🏗️ Project Architecture

```
lib/
├── core/
│   ├── constants/       # App constants, API config, environment bindings
│   ├── providers/       # Riverpod dependency injection providers
│   ├── services/        # GeminiService (multimodal vision, NLP tiers, offline engine)
│   ├── storage/         # Local persistence (SharedPreferences)
│   └── theme/           # Apple HIG theme, OLED dark colors, typography
├── features/
│   ├── auth/            # Guest mode & account authentication
│   ├── history/         # Daily recap, meal log, macro balance breakdown
│   ├── home/            # Dashboard, Apple Activity Rings, quick log actions
│   ├── legal/           # Terms of Service, Privacy Policy, Medical Disclaimer
│   ├── meals/           # Camera vision, manual input, portion adjustments
│   ├── onboarding/      # Athlete target setup, BMR/TDEE calculation
│   └── settings/        # Preferences, client-side API key configuration
└── main.dart            # Application entrypoint & initialization
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.10.4` or newer)
- Dart SDK `^3.10.4`
- Android Studio / Xcode / VS Code

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/kalore.git
   cd kalore/kalore
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Configure API Keys (Optional)**:
   Kalore runs completely offline without any keys! If you wish to enable cloud AI features:
   
   Copy `env.json.example` to `env.json`:
   ```bash
   cp env.json.example env.json
   ```
   Edit `env.json` with your credentials:
   ```json
   {
     "GEMINI_API_KEY": "your_gemini_api_key",
     "CALORIE_API_KEY": "your_calorie_api_key",
     "CALORIE_NINJAS_KEY": "your_calorie_ninjas_key"
   }
   ```

4. **Launch Application**:
   ```bash
   # With env.json:
   flutter run --dart-define-from-file=env.json

   # Or 100% offline (no keys required):
   flutter run
   ```

---

## 🧪 Testing

Kalore includes a comprehensive automated test suite covering medical algorithms, portion scaling, MIME detection, version tracking, and UI widget rendering:

```bash
# Run static analysis
flutter analyze

# Run all automated tests
flutter test test/unit_test.dart test/gemini_service_test.dart test/widget_test.dart
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
