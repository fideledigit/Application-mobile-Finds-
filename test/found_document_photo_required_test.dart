import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finds/presentation/views/declaration/found_document_step1_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step2_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step3_view.dart';

void main() {
  testWidgets(
    'la photo est obligatoire pour passer à l\'étape 3 d\'une trouvaille',
    (tester) async {
      final declaration = FoundDeclarationModel()
        ..documentType = 'CNI'
        ..lastName = 'KOUASSI'
        ..firstName = 'Koffi Jean'
        ..birthDate = '14/06/1992'
        ..foundDate = '24/10/2024'
        ..foundLocation = 'Lomé, Station Total Aéroport';

      await tester.pumpWidget(
        MaterialApp(home: FoundDocumentStep2View(declaration: declaration)),
      );

      final continueButton = find.text('Continuer vers l\'étape 3');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(
        find.text('Veuillez ajouter une photo du document.'),
        findsOneWidget,
      );
      expect(find.byType(FoundDocumentStep2View), findsOneWidget);
      expect(find.byType(FoundDocumentStep3View), findsNothing);
    },
  );
}
