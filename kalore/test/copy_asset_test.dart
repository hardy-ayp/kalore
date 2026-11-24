import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kalore logo asset exists and is valid', () {
    final logo = File(r'assets/images/kalore_logo.png');
    expect(
      logo.existsSync(),
      isTrue,
      reason: 'Kalore logo must exist in assets',
    );
    expect(logo.lengthSync(), greaterThan(1000));
  });
}
