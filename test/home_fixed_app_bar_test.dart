import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/home/home_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) =>
      Stream.value(const Response(response: {}, data: {}));
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.initialize(linkOverride: _EmptyLink());
  });

  for (final width in [320.0, 411.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('app bar fixe $width@$scale', (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const HomeDashboardView(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);

        final greeting = find.textContaining('Hello');
        final search = find.byIcon(Icons.search_rounded);
        final bell = find.byIcon(Icons.notifications_none_rounded);
        expect(greeting, findsOneWidget);
        final before = tester.getTopLeft(greeting);
        final searchBefore = tester.getTopLeft(search);

        // On fait défiler tout le contenu vers le bas.
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        // Le contenu a bien défilé…
        final scroll = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .firstWhere((st) => st.axisDirection == AxisDirection.down);
        expect(scroll.position.pixels, greaterThan(100));
        // … mais l'en-tête n'a pas bougé et reste visible.
        expect(tester.getTopLeft(greeting), before);
        expect(tester.getTopLeft(search), searchBefore);
        expect(bell.hitTestable(), findsOneWidget);
        expect(search.hitTestable(), findsOneWidget);

        // Démonte la page pour arrêter le rafraîchissement automatique.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
