import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finds/presentation/views/declaration/lost_document_step1_view.dart';
import 'package:finds/presentation/views/declaration/lost_document_step3_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step1_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step3_view.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 568),
      ).copyWith(textScaler: const TextScaler.linear(1.15)),
      child: child,
    ),
  );
}

LostDeclarationModel lostModel() => LostDeclarationModel()
  ..documentType = 'CNI'
  ..documentNumber = 'TG-0824-4567-492'
  ..lastName = 'KOUASSI'
  ..firstName = 'Koffi Jean'
  ..birthDate = '14/06/1992'
  ..lossDate = '24/10/2024'
  ..lossLocation = 'Lomé, Marché d\'Adawlato'
  ..description = 'Perdu dans un portefeuille.'
  ..photoName = 'copie_cni_perdue.jpg'
  ..photoSize = '1.2 Mo';

FoundDeclarationModel foundModel() => FoundDeclarationModel()
  ..documentType = 'CNI'
  ..documentNumber = 'TG-0824-4567-492'
  ..lastName = 'KOUASSI'
  ..firstName = 'Koffi Jean'
  ..birthDate = '14/06/1992'
  ..birthPlace = 'Lomé'
  ..foundDate = '24/10/2024'
  ..foundLocation = 'Lomé, Station Total Aéroport'
  ..description = 'Trouvé dans le hall.'
  ..photoName = 'carte.jpg'
  ..photoSize = '1.2 Mo';

void main() {
  testWidgets('dialogue perdu', (tester) async {
    await tester.pumpWidget(
      wrap(LostDocumentStep3View(declaration: lostModel())),
    );
    await tester.tap(find.text('Confirmer et publier'));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));
  });
  testWidgets('dialogue trouvé', (tester) async {
    await tester.pumpWidget(
      wrap(FoundDocumentStep3View(declaration: foundModel())),
    );
    await tester.tap(find.text('Confirmer et publier'));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
