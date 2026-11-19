import 'package:finds/core/utils/name_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nom de famille en MAJUSCULES', () {
    expect(formatLastName('dofor'), 'DOFOR');
    expect(formatLastName('  kouassi   agbodjan '), 'KOUASSI AGBODJAN');
  });

  test('prénom : majuscule au début, le reste en minuscules', () {
    expect(formatFirstName('AKOSSIWA'), 'Akossiwa');
    expect(formatFirstName('akossiwa'), 'Akossiwa');
    expect(formatFirstName('jean-baptiste  koffi'), 'Jean-Baptiste Koffi');
  });

  test('saisie du nom passée en majuscules', () {
    const f = UpperCaseTextFormatter();
    final out = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'dofor'),
    );
    expect(out.text, 'DOFOR');
  });
}
