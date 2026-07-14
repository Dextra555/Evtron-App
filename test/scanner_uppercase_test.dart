import 'package:evtron/View/Scanner/scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpperCaseTextFormatter', () {
    test('converts entered letters to uppercase', () {
      final formatter = UpperCaseTextFormatter();

      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: 'abc123'),
      );

      expect(result.text, 'ABC123');
    });
  });
}
