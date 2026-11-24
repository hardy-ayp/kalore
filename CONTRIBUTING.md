# Contributing to Kalore

Thank you for your interest in contributing to Kalore! We welcome contributions to make healthy calorie and macro tracking accessible, accurate, and beautifully designed.

---

## Code of Conduct

All contributors and community members are expected to maintain a friendly, welcoming, and respectful environment. Please provide constructive feedback and collaborate with kindness.

---

## Development Setup

### Prerequisites
- Flutter SDK `^3.10.4` or higher
- Dart SDK `^3.10.4`
- Android Studio / VS Code with Flutter extension
- An Android device or emulator, iOS simulator, or Chrome browser

### Quick Start
1. Fork and clone the repository:
   ```bash
   git clone https://github.com/your-username/kalore.git
   cd kalore/kalore
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure optional API keys:
   Copy `env.json.example` to `env.json` and fill in your keys, or run without keys using the built-in offline engine:
   ```bash
   cp env.json.example env.json
   ```

4. Run the application:
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

---

## Architecture & Coding Standards

1. **Apple Human Interface Guidelines (HIG)**:
   - Use fluid physics springs, Cupertino-inspired haptics, and OLED true-black dark modes.
   - Maintain clean visual hierarchy, generous touch targets (minimum 44x44pt), and smooth page transitions.

2. **Clean Layered Architecture**:
   - `core/`: Constants, shared services (AI & nutrition pipelines), theme styles, storage.
   - `features/`: Feature modules (onboarding, home/dashboard, meals, history, settings, legal) containing presentation screens, widgets, and state providers.

3. **Multi-Tier Nutrition Pipeline**:
   - Primary: CalorieAPI & CalorieNinjas NLP engines.
   - Secondary: Google Gemini Vision & Generative AI.
   - Offline Heuristics: Zero-cloud on-device nutrition calculation.

---

## Testing & Quality Assurance

Before submitting a Pull Request, verify that all static checks and automated tests pass:

```bash
# 1. Run static analysis (0 warnings expected)
flutter analyze

# 2. Run automated test suite
flutter test test/unit_test.dart test/gemini_service_test.dart test/widget_test.dart
```

---

## Pull Request Guidelines

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Keep commits concise and descriptive.
3. Update versioning in `pubspec.yaml` and `api_config.dart` if introducing significant changes.
4. Ensure no private keys, passwords, or machine-specific paths are included in the diff.
5. Open a Pull Request with a clear description of the problem solved and screenshots/GIFs for UI changes.
