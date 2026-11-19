import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/presentation/views/declaration/lost_document_step1_view.dart';
import 'package:finds/presentation/views/declaration/lost_document_step2_view.dart';
import 'package:finds/presentation/views/declaration/lost_document_step3_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step1_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step2_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step3_view.dart';
import 'package:finds/presentation/views/declaration/declaration_type_choice_view.dart';

/// Reproduit la config de main.dart (textScaler 1.15) sur un petit écran
/// et détecte les dépassements (bandes jaune/noir en debug).
Widget wrap(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(360, 640),
        padding: EdgeInsets.only(top: 24),
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
  ..birthPlace = 'Lomé'
  ..lossDate = '24/10/2024'
  ..lossLocation = 'Lomé, Marché d\'Adawlato (Grand Marché de Lomé)'
  ..description =
      'Perdu dans un portefeuille en cuir marron avec plusieurs cartes.'
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
  ..description = 'Trouvé dans le hall de l\'aéroport.'
  ..photoName = 'carte_trouvee.jpg'
  ..photoSize = '1.2 Mo';

Future<void> scrollAll(WidgetTester tester) async {
  final finder = find.byType(Scrollable).first;
  for (var i = 0; i < 12; i++) {
    await tester.drag(finder, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  // Les écrans de publication nécessitent une session authentifiée.
  setUp(() => FindsApiClient.authToken.value = 'test-token');
  tearDown(() => FindsApiClient.authToken.value = null);

  testWidgets('Lost step 1 (Identification) sans dépassement', (tester) async {
    await tester.pumpWidget(wrap(const LostDocumentStep1View()));
    await scrollAll(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lost step 2 sans dépassement', (tester) async {
    await tester.pumpWidget(
      wrap(LostDocumentStep2View(declaration: lostModel())),
    );
    await scrollAll(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Lost step 3 (Vérification) : échec API signalé, sans faux succès ni dépassement',
    (tester) async {
      await tester.pumpWidget(
        wrap(LostDocumentStep3View(declaration: lostModel())),
      );
      await scrollAll(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Confirmer et publier'));
      await tester.pump(const Duration(milliseconds: 1600));
      expect(tester.takeException(), isNull);
      // Sans serveur joignable : pas de faux « publié », un message d'erreur.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );

  testWidgets('Found step 1 sans dépassement', (tester) async {
    await tester.pumpWidget(wrap(const FoundDocumentStep1View()));
    await scrollAll(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Found step 2 sans dépassement', (tester) async {
    await tester.pumpWidget(
      wrap(FoundDocumentStep2View(declaration: foundModel())),
    );
    await scrollAll(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Found step 3 (Vérification) : échec API signalé, sans faux succès ni dépassement',
    (tester) async {
      await tester.pumpWidget(
        wrap(FoundDocumentStep3View(declaration: foundModel())),
      );
      await scrollAll(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Confirmer et publier'));
      await tester.pump(const Duration(milliseconds: 1600));
      expect(tester.takeException(), isNull);
      expect(find.text('Merci pour votre civisme !'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );

  testWidgets('Choice type sans dépassement', (tester) async {
    await tester.pumpWidget(wrap(const DeclarationTypeChoiceView()));
    await scrollAll(tester);
    expect(tester.takeException(), isNull);
  });
}
