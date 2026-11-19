import 'package:flutter/services.dart';

/// Nom de famille : toujours en MAJUSCULES (« mensah » → « MENSAH »).
String formatLastName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

/// Prénom : première lettre en majuscule, le reste en minuscules
/// (« AMA » → « Ama », « jean-baptiste » → « Jean-Baptiste »).
String formatFirstName(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .map(
      (w) => w
          .split('-')
          .map(
            (p) => p.isEmpty
                ? p
                : p[0].toUpperCase() + p.substring(1).toLowerCase(),
          )
          .join('-'),
    )
    .join(' ');

/// Met en majuscules pendant la saisie (champ « Nom de famille »).
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
