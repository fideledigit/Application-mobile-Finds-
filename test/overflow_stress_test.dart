import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finds/presentation/views/declaration/lost_document_step1_view.dart';
import 'package:finds/presentation/views/declaration/lost_document_step2_view.dart';
import 'package:finds/presentation/views/declaration/lost_document_step3_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step1_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step2_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step3_view.dart';

/// Jeux de données "pire cas" (textes longs) sur plusieurs largeurs.
Widget wrap(Widget child, double width) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 700),
      ).copyWith(textScaler: const TextScaler.linear(1.15)),
      child: child,
    ),
  );
}

LostDeclarationModel lostModel() => LostDeclarationModel()
  ..documentType = 'GRISE'
  ..documentNumber = 'TG-CAR-2024-99887766'
  ..lastName = 'KOUASSI-AGBODJANFOE'
  ..firstName = 'Jean-Baptiste Koffi Olivier'
  ..birthDate = '14/06/1992'
  ..birthPlace = 'Lomé, Golfe-3, Quartier Akodésséwa'
  ..lossDate = '24/10/2024'
  ..lossLocation =
      'Lomé, Marché d\'Adawlato (Grand Marché de Lomé), entrée principale'
  ..description =
      'Perdu dans un portefeuille en cuir marron foncé avec plusieurs cartes de transport et des reçus.'
  ..photoName = 'photo_cartegrise_verso_hd.jpg'
  ..photoSize = '2.4 Mo';

FoundDeclarationModel foundModel() => FoundDeclarationModel()
  ..documentType = 'GRISE'
  ..documentNumber = 'TG-CAR-2024-99887766'
  ..lastName = 'KOUASSI-AGBODJANFOE'
  ..firstName = 'Jean-Baptiste Koffi Olivier'
  ..birthDate = '14/06/1992'
  ..birthPlace = 'Lomé, Golfe-3'
  ..foundDate = '24/10/2024'
  ..foundLocation =
      'Lomé, Station Total Aéroport Gnassingbé Eyadéma, parking niveau 2'
  ..description =
      'Trouvé dans le hall de l\'aéroport près des bornes d\'enregistrement.'
  ..photoName = 'photo_document_trouve_verso.jpg'
  ..photoSize = '2.4 Mo';

Future<void> scrollAll(WidgetTester tester) async {
  final finder = find.byType(Scrollable).first;
  for (var i = 0; i < 14; i++) {
    await tester.drag(finder, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('lost step1 @$width', (tester) async {
      await tester.pumpWidget(wrap(const LostDocumentStep1View(), width));
      // Ouvre l'option "Autre" pour afficher le champ supplémentaire.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Autre document officiel…').last);
      await tester.pumpAndSettle();
      await scrollAll(tester);
    });

    testWidgets('lost step2 @$width', (tester) async {
      await tester.pumpWidget(
        wrap(LostDocumentStep2View(declaration: lostModel()), width),
      );
      await scrollAll(tester);
    });

    testWidgets('lost step3 @$width', (tester) async {
      await tester.pumpWidget(
        wrap(LostDocumentStep3View(declaration: lostModel()), width),
      );
      await scrollAll(tester);
      await tester.tap(find.text('Confirmer et publier'));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('found step1 @$width', (tester) async {
      await tester.pumpWidget(wrap(const FoundDocumentStep1View(), width));
      await scrollAll(tester);
    });

    testWidgets('found step2 @$width', (tester) async {
      await tester.pumpWidget(
        wrap(FoundDocumentStep2View(declaration: foundModel()), width),
      );
      await scrollAll(tester);
    });

    testWidgets('found step3 @$width', (tester) async {
      await tester.pumpWidget(
        wrap(FoundDocumentStep3View(declaration: foundModel()), width),
      );
      await scrollAll(tester);
      await tester.tap(find.text('Confirmer et publier'));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 400));
    });
  }
}
