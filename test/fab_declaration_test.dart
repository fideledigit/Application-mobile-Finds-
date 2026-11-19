import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finds/presentation/views/declaration/declaration_type_choice_view.dart';
import 'package:finds/presentation/views/home/main_screen.dart';

void main() {
  void ignoreListTileWarnings() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('ListTile background color')) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);
  }

  testWidgets('Le bouton + en bas ouvre les options de déclaration', (
    tester,
  ) async {
    ignoreListTileWarnings();
    await tester.pumpWidget(const MaterialApp(home: MainScreen()));
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.byType(DeclarationTypeChoiceView), findsOneWidget);
    expect(find.text('Document perdu'), findsWidgets);
    expect(find.text('Document trouvé'), findsWidgets);
  });

  testWidgets(
    'Le bouton + est masqué sur les onglets Correspondances et Profil',
    (tester) async {
      ignoreListTileWarnings();
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);

      // Onglet Accueil : visible.
      expect(fab, findsOneWidget);

      // Onglet Correspondances : masqué.
      await tester.tap(find.text('Matchs').last);
      await tester.pumpAndSettle();
      expect(fab, findsNothing);

      // Onglet Profil : masqué.
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      expect(fab, findsNothing);

      // Onglet Déclarations : visible à nouveau.
      await tester.tap(find.text('Déclarations').last);
      await tester.pumpAndSettle();
      expect(fab, findsOneWidget);
    },
  );
}
