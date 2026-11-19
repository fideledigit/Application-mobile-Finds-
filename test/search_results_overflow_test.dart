import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/search/document_search_view.dart';
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

Map<String, dynamic> _decl(int i) => {
  '__typename': 'Declaration',
  'id': 'decl-$i',
  'userId': 'user-$i',
  'type': i.isEven ? 'PERTE' : 'TROUVAILLE',
  'typeDocument': _types[i % _types.length],
  'nomProprietaire': 'KOUASSI-AGBODJANFOE-AMEGANVI',
  'prenomProprietaire': 'Jean-Baptiste Koffi Olivier Emmanuel',
  'numeroDocument': 'TG-CAR-2024-99887766-$i',
  'descriptionLibre': null,
  'ville': 'Lomé (Golfe) Préfecture du Grand Lomé',
  'quartier': 'Marché d\'Adawlato entrée principale côté lagune',
  'statut': ['ACTIVE', 'MATCHEE', 'RESOLUE'][i % 3],
  'photoUrl': null,
  'photoFlouteeUrl': null,
  'pdfUrl': null,
  'matchesCount': 0,
  'createdAt': DateTime.now()
      .subtract(Duration(days: [0, 1, 5, 20, 214, 800][i % 6]))
      .toIso8601String(),
};

class _FakeSearchLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    return Stream.value(
      Response(
        response: const {},
        data: {
          '__typename': 'Query',
          'searchDeclarations': {
            '__typename': 'PaginatedDeclarations',
            'data': List.generate(12, _decl),
            'meta': {
              '__typename': 'PaginationMeta',
              'page': 1,
              'pageSize': 100,
              'total': 12,
              'totalPages': 1,
            },
          },
        },
      ),
    );
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.initialize(linkOverride: _FakeSearchLink());
  });

  for (final width in [320.0, 360.0, 411.0]) {
    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      testWidgets('résultats recherche $width@$scale', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final errors = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(
          d
              .toString()
              .split('\n')
              .where((l) => l.contains('overflowed') || l.contains('file:///'))
              .join(' | '),
        );
        var loaded = 0;
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
              home: const DocumentSearchView(),
            ),
          );
          for (var i = 0; i < 20 && loaded == 0; i++) {
            await tester.runAsync(
              () => Future.delayed(const Duration(milliseconds: 20)),
            );
            await tester.pump(const Duration(milliseconds: 50));
            loaded = find.textContaining('KOUASSI').evaluate().length;
          }
          if (loaded > 0) {
            for (var i = 0; i < 12; i++) {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -300),
              );
              await tester.pump();
            }
            await tester.tap(find.textContaining('KOUASSI').first);
            await tester.pump(const Duration(milliseconds: 600));
          }
        } finally {
          FlutterError.onError = old;
        }
        expect(loaded, greaterThan(0), reason: 'résultats non affichés');
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }
  }
}
