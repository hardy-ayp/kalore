import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ensure no UI files contain user-facing Gemini or API Key mentions', () {
    final dir = Directory('lib/features');
    final files = dir.listSync(recursive: true).whereType<File>();
    final violations = <String>[];

    for (final file in files) {
      if (!file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lower = line.toLowerCase();
        // Check if user-facing strings contain gemini or api key
        if ((line.contains("'") || line.contains('"')) &&
            (lower.contains('gemini') ||
                lower.contains('api key') ||
                lower.contains('apikey'))) {
          // Allow internal provider references if any
          if (!line.contains('Provider') && !line.contains('import')) {
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'No UI screens should expose Gemini or API key jargon to users: $violations',
    );
  });
}
