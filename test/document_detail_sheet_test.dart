import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/search/widgets/document_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _doc({
  required String category,
  String? statut,
  int matchesCount = 0,
}) => {
  'id': 'x',
  'name': 'Jean-Baptiste Koffi Olivier Emmanuel KOUASSI-AGBODJANFOE',
  'type': 'Carte Nationale d\'Identité (CNI)',
  'typeShort': 'CNI',
  'typeDocument': 'CNI',
  'category': category,
  'timeAgo': 'Il y a 3 jours',
  'maskedNumber': 'TG•••••••••••483',
  'badge': 'Signalé',
  'place': 'Marché d\'Adawlato entrée principale, Lomé (Golfe)',
  'statut': statut,
  'description': 'Pochette bleue avec une carte bancaire et deux photos.',
  'photoFlouteeUrl': null,
  'createdAt': '2026-11-08T14:05:00Z',
  'matchesCount': matchesCount,
};

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required String category,
    required String statut,
    required VoidCallback onDeclare,
    VoidCallback? onContact,
    double width = 411.0,
    double scale = 1.0,
    int matchesCount = 0,
  }) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (c) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => DocumentDetailSheet.show(
                  c,
                  doc: _doc(
                    category: category,
                    statut: statut,
                    matchesCount: matchesCount,
                  ),
                  onDeclare: onDeclare,
                  onContact: onContact,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final category in ['lost', 'found']) {
    for (final statut in ['ACTIVE', 'MATCHEE', 'RESOLUE']) {
      for (final width in [320.0, 411.0]) {
        for (final scale in [1.0, 1.5, 2.0]) {
          testWidgets('fiche $category/$statut $width@$scale', (tester) async {
            var declared = 0;
            await openSheet(
              tester,
              category: category,
              statut: statut,
              width: width,
              scale: scale,
              onDeclare: () => declared++,
            );

            expect(tester.takeException(), isNull);
            final cta = category == 'lost'
                ? 'Je l\'ai trouvé'
                : 'C\'est mon document';
            if (statut == 'RESOLUE') {
              expect(find.text('Document déjà restitué'), findsOneWidget);
            } else {
              await tester.tap(find.text(cta));
              await tester.pumpAndSettle();
              expect(declared, 1);
            }
          });
        }
      }
    }
  }

  // Le bouton de messagerie doit rester lisible et cliquable sur petit écran
  // comme avec un texte agrandi, et disparaître une fois le document restitué.
  for (final category in ['lost', 'found']) {
    for (final statut in ['ACTIVE', 'MATCHEE']) {
      for (final width in [320.0, 411.0]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('contact $category/$statut $width@$scale', (
            tester,
          ) async {
            var declared = 0;
            var contacted = 0;
            await openSheet(
              tester,
              category: category,
              statut: statut,
              width: width,
              scale: scale,
              onDeclare: () => declared++,
              onContact: () => contacted++,
            );

            expect(tester.takeException(), isNull);
            final label = category == 'lost'
                ? 'Contacter le propriétaire'
                : 'Contacter la personne qui l\'a trouvé';
            expect(find.text(label), findsOneWidget);

            // La carte au-dessus du bouton doit désigner la bonne personne :
            // sur une perte, le nom affiché est celui du propriétaire ; sur
            // une trouvaille, c'est le nom inscrit sur le document, publié
            // par la personne qui l'a trouvé (la cible du message).
            final ownerLabel = category == 'lost'
                ? 'TITULAIRE DU DOCUMENT'
                : 'DOCUMENT AU NOM DE';
            expect(find.text(ownerLabel), findsOneWidget);
            if (category == 'found') {
              expect(
                find.text('Annonce publiée par la personne qui l\'a trouvé'),
                findsOneWidget,
              );
            } else {
              expect(
                find.text('Annonce publiée par la personne qui l\'a trouvé'),
                findsNothing,
              );
            }

            await tester.tap(find.text(label));
            await tester.pumpAndSettle();

            expect(contacted, 1);
            expect(declared, 0);
            // La fiche se referme avant d'ouvrir la conversation.
            expect(find.text(label), findsNothing);
          });
        }
      }
    }
  }

  testWidgets('pas de bouton contact quand le document est restitué', (
    tester,
  ) async {
    var contacted = 0;
    await openSheet(
      tester,
      category: 'lost',
      statut: 'RESOLUE',
      onDeclare: () {},
      onContact: () => contacted++,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Contacter le propriétaire'), findsNothing);
    expect(find.text('Fermer'), findsOneWidget);
  });

  for (final count in [0, 1, 3]) {
    testWidgets('badge correspondances ($count) 320@2.0', (tester) async {
      await openSheet(
        tester,
        category: 'lost',
        statut: 'ACTIVE',
        width: 320,
        scale: 2.0,
        matchesCount: count,
        onDeclare: () {},
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text('1 correspondance trouvée'),
        count == 1 ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('3 correspondances trouvées'),
        count == 3 ? findsOneWidget : findsNothing,
      );
      // Le score n'est jamais exposé publiquement.
      expect(find.textContaining('%'), findsNothing);
    });
  }

  testWidgets('pas de badge quand le document est restitué', (tester) async {
    await openSheet(
      tester,
      category: 'found',
      statut: 'RESOLUE',
      matchesCount: 1,
      onDeclare: () {},
    );
    expect(find.text('1 correspondance trouvée'), findsNothing);
  });
}
