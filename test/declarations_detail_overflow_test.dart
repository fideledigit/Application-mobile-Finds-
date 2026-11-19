import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/declarations/declarations_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _types = [
  'CNI',
  'PASSEPORT',
  'PERMIS_CONDUIRE',
  'CARTE_GRISE',
  'CARTE_ETUDIANT',
  'CARTE_PROFESSIONNELLE',
  'ACTE_NAISSANCE',
  'CARTE_CONSULAIRE',
  'CERTIFICAT_NATIONALITE',
  'AUTRE',
];
const _statuts = ['ACTIVE', 'MATCHEE', 'RESOLUE', 'EXPIREE'];

Map<String, dynamic> _decl(int i) => {
  '__typename': 'Declaration',
  'id': 'cmd8x7q2a0000abcdefghij$i',
  'type': i.isEven ? 'PERTE' : 'TROUVAILLE',
  'typeDocument': _types[i % _types.length],
  'nomProprietaire': 'KOUASSI-AGBODJANFOE-AMEGANVI',
  'prenomProprietaire': 'Jean-Baptiste Koffi Olivier Emmanuel',
  'numeroDocument': 'TG-CAR-2024-99887766-$i',
  'descriptionLibre': 'Portefeuille en cuir marron avec plusieurs cartes.',
  'ville': 'Lomé (Golfe) Préfecture du Grand Lomé',
  'quartier': 'Marché d\'Adawlato entrée principale côté lagune',
  'statut': _statuts[i % _statuts.length],
  'photoUrl': null,
  'photoFlouteeUrl': null,
  'pdfUrl': null,
  'matchesCount': i % 3,
  'createdAt': '2026-03-14T10:00:00.000Z',
  'updatedAt': '2026-03-14T10:00:00.000Z',
};

class _Link extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) =>
      Stream.value(
        Response(
          response: const {},
          data: {
            '__typename': 'Query',
            'myDeclarations': {
              '__typename': 'PaginatedDeclarations',
              'data': List.generate(8, _decl),
              'meta': {
                '__typename': 'PaginationMeta',
                'page': 1,
                'pageSize': 50,
                'total': 8,
                'totalPages': 1,
              },
            },
          },
        ),
      );
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.initialize(linkOverride: _Link());
    FindsApiClient.authToken.value = 'test-token';
  });

  for (final width in [320.0, 360.0, 411.0]) {
    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final index in [0, 1, 2, 3]) {
        testWidgets('fiche déclaration #$index $width@$scale', (tester) async {
          tester.view.physicalSize = Size(width, 760);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          final errors = <String>[];
          final old = FlutterError.onError;
          FlutterError.onError = (d) => errors.add(
            d
                .toString()
                .split('\n')
                .where(
                  (l) => l.contains('overflowed') || l.contains('file:///'),
                )
                .join(' | '),
          );
          var opened = false;
          try {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.lightTheme,
                builder: (c, child) => MediaQuery(
                  data: MediaQuery.of(
                    c,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: DeclarationsListView(onNavigateToTab: (_) {}),
                ),
              ),
            );
            for (var i = 0; i < 10; i++) {
              await tester.runAsync(
                () => Future.delayed(const Duration(milliseconds: 20)),
              );
              await tester.pump(const Duration(milliseconds: 50));
            }
            final cards = find.textContaining('TG');
            if (cards.evaluate().length > index) {
              await tester.ensureVisible(cards.at(index));
              await tester.pump();
              await tester.tap(cards.at(index), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 600));
              opened = find.byType(BottomSheet).evaluate().isNotEmpty;
            }
          } finally {
            FlutterError.onError = old;
          }
          expect(opened, isTrue, reason: 'la fiche doit s\'ouvrir');
          expect(errors, isEmpty, reason: errors.join('\n'));
        });
      }
    }
  }
}
