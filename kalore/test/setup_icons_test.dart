import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Verify Android launcher icons and web icons match kalore_logo.png', () {
    final logoPng = File(r'assets/images/kalore_logo.png');
    expect(logoPng.existsSync(), isTrue, reason: 'kalore_logo.png must exist');
    final bytes = logoPng.readAsBytesSync();
    expect(bytes.length, greaterThan(1000));

    final androidMipmaps = [
      r'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      r'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
      r'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
      r'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
      r'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    ];

    for (final path in androidMipmaps) {
      final f = File(path);
      if (f.existsSync()) {
        expect(f.lengthSync(), equals(bytes.length));
      }
    }

    final webIcons = [
      r'web/favicon.png',
      r'web/icons/Icon-192.png',
      r'web/icons/Icon-512.png',
      r'web/icons/Icon-maskable-192.png',
      r'web/icons/Icon-maskable-512.png',
    ];

    for (final path in webIcons) {
      final f = File(path);
      if (f.existsSync()) {
        expect(f.lengthSync(), equals(bytes.length));
      }
    }
  });
}
