# Security Policy & Zero-Leak Architecture

## Supported Versions

| Version | Supported          | Security Status |
| ------- | ------------------ | --------------- |
| 1.3.x   | :white_check_mark: | Active Support  |
| < 1.3.0 | :x:                | Deprecated      |

---

## Zero-Leak Credential Policy

Kalore is designed from the ground up to prevent secret leakage in open-source environments:

1. **No Hardcoded Secrets**:
   The repository does not contain production API keys, personal credentials, or local environment paths. All network services operate via secure runtime injection (`--dart-define` or `env.json`).

2. **Client-Side Key Management**:
   Users can supply their personal API keys directly within the application's Settings screen. These keys are stored solely on the user's local device using sandboxed platform storage (`SharedPreferences`) and are never sent to third-party tracking servers.

3. **Offline Fallback Engine**:
   When no cloud API keys are present, Kalore automatically activates its built-in on-device heuristic engine, ensuring calorie estimation, macro breakdowns, and athlete plan calculations remain fully functional without internet access.

4. **Strict Repository Ignore Rules**:
   The project `.gitignore` prevents tracking of:
   - Secret environment files (`.env`, `env.json`, `*.local.dart`)
   - Platform keystores and signing credentials (`*.keystore`, `*.jks`, `key.properties`)
   - Machine-specific configuration (`local.properties`, OS metadata)

---

## Reporting a Vulnerability

If you discover a security vulnerability within Kalore:

1. Please **do not** report security vulnerabilities via public GitHub issues.
2. Email your discovery and reproduction steps to the project maintainers or open a private security advisory through GitHub.
3. Include the affected platform (Android, iOS, Web), application build number, and steps to reproduce.
4. Maintainers will review the report and provide a response within 48 hours.
