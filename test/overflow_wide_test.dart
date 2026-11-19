import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finds/presentation/views/declaration/lost_document_step1_view.dart';
import 'package:finds/presentation/views/declaration/lost_document_step2_view.dart';
import 'package:finds/presentation/views/declaration/lost_document_step3_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step1_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step2_view.dart';
import 'package:finds/presentation/views/declaration/found_document_step3_view.dart';
import 'package:finds/presentation/views/declaration/declaration_type_choice_view.dart';
import 'package:finds/presentation/views/declarations/declarations_list_view.dart';
import 'package:finds/presentation/views/home/main_screen.dart';

Widget wrap(Widget child, double width, double scale) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 700),
      ).copyWith(textScaler: TextScaler.linear(scale)),
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
      'Perdu dans un portefeuille en cuir marron foncé avec plusieurs cartes de transport.'
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
  ..foundLocation = 'Lomé, Station Total Aéroport, parking niveau 2'
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
  // Largeur réelle d'appareils + échelle de police élevée (config utilisateur).
  for (final config in [
    const [300.0, 1.3],
    const [360.0, 1.3],
    const [411.0, 1.3],
    const [360.0, 1.5],
  ]) {
    final width = config[0];
    final scale = config[1];
    final tag = '$width@$scale';

    testWidgets('lost step1 $tag', (tester) async {
      await tester.pumpWidget(
        wrap(const LostDocumentStep1View(), width, scale),
      );
      await scrollAll(tester);
    });

    testWidgets('lost step2 $tag', (tester) async {
      await tester.pumpWidget(
        wrap(LostDocumentStep2View(declaration: lostModel()), width, scale),
      );
      await scrollAll(tester);
    });

    testWidgets('lost step3 $tag', (tester) async {
      await tester.pumpWidget(
        wrap(LostDocumentStep3View(declaration: lostModel()), width, scale),
      );
      await scrollAll(tester);
      await tester.tap(find.text('Confirmer et publier'));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('found step1 $tag', (tester) async {
      await tester.pumpWidget(
        wrap(const FoundDocumentStep1View(), width, scale),
      );
      await scrollAll(tester);
    });

    testWidgets('found step2 $tag', (tester) async {
      await tester.pumpWidget(
        wrap(FoundDocumentStep2View(declaration: foundModel()), width, scale),
      );
      await scrollAll(tester);
    });

    testWidgets('found step3 $tag', (tester) async {
      await tester.pumpWidget(
        wrap(FoundDocumentStep3View(declaration: foundModel()), width, scale),
      );
      await scrollAll(tester);
      await tester.tap(find.text('Confirmer et publier'));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('choice $tag', (tester) async {
      await tester.pumpWidget(
        wrap(const DeclarationTypeChoiceView(), width, scale),
      );
      await scrollAll(tester);
    });

    testWidgets('declarations list $tag', (tester) async {
      await tester.pumpWidget(wrap(const DeclarationsListView(), width, scale));
      await scrollAll(tester);
    });

    testWidgets('main screen $tag', (tester) async {
      // Ignore les avertissements debug « ListTile invisible » (non visibles à l'écran).
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('ListTile background color')) {
          return;
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(wrap(const MainScreen(), width, scale));
      await scrollAll(tester);
      // Onglet Déclarations (dernier = libellé de la barre de navigation)
      await tester.tap(find.text('Déclarations').last);
      await tester.pump(const Duration(milliseconds: 300));
      await scrollAll(tester);
    });
  }
}
