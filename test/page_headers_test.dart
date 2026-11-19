import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/declarations/declarations_list_view.dart';
import 'package:finds/presentation/views/matches/matches_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Link extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) =>
      Stream.value(const Response(response: {}, data: {}));
}

Future<void> _pump(WidgetTester tester, Widget page, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: page));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.initialize(linkOverride: _Link());
  });

  for (final width in [320.0, 411.0]) {
    testWidgets('Matchs : pastille « détectés » calée à droite ($width)', (
      tester,
    ) async {
      await _pump(tester, const MatchesListView(), width);
      final badge = find.textContaining('détectés');
      expect(badge, findsOneWidget);
      // Le bord droit de la pastille est collé à la marge droite (16 px),
      // et non plus au milieu de la barre.
      final pill = find
          .ancestor(of: badge, matching: find.byType(Container))
          .first;
      expect(tester.getTopRight(pill).dx, closeTo(width - 16, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Déclarations : plus de compteur ni de « Nouvelle » ($width)', (
      tester,
    ) async {
      await _pump(tester, const DeclarationsListView(), width);
      expect(find.text('Nouvelle'), findsNothing);
      expect(find.textContaining(RegExp(r'^\d+ déclaration')), findsNothing);
      expect(find.text('Déclarations'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
