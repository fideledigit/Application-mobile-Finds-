import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/matches/matches_list_view.dart';
import 'package:finds/presentation/views/notifications/notifications_list_view.dart';
import 'package:finds/presentation/views/search/document_search_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _empty(String typename) => {
  '__typename': typename,
  'data': <dynamic>[],
  'meta': {
    '__typename': 'PaginationMeta',
    'page': 1,
    'pageSize': 50,
    'total': 0,
    'totalPages': 1,
  },
};

class _EmptyLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    final q = request.toString();
    final data = <String, dynamic>{'__typename': 'Query'};
    if (q.contains('searchDeclarations')) {
      data['searchDeclarations'] = _empty('PaginatedDeclarations');
    }
    if (q.contains('myNotifications')) {
      data['myNotifications'] = _empty('PaginatedNotifications');
    }
    if (q.contains('myDeclarations')) {
      data['myDeclarations'] = _empty('PaginatedDeclarations');
    }
    return Stream.value(Response(response: const {}, data: data));
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.initialize(linkOverride: _EmptyLink());
    FindsApiClient.authToken.value = 'test-token';
  });

  final pages = <String, Widget Function()>{
    'recherche': () => const DocumentSearchView(),
    'notifications': () => NotificationsListView(onNavigateToTab: (_) {}),
    'matchs': () => const MatchesListView(),
  };

  for (final entry in pages.entries) {
    for (final width in [320.0, 411.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('état vide ${entry.key} $width@$scale', (tester) async {
          tester.view.physicalSize = Size(width, 700);
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
                home: entry.value(),
              ),
            );
            for (var i = 0; i < 10; i++) {
              await tester.runAsync(
                () => Future.delayed(const Duration(milliseconds: 20)),
              );
              await tester.pump(const Duration(milliseconds: 50));
            }
          } finally {
            FlutterError.onError = old;
          }
          expect(
            find.byWidgetPredicate((w) => w is ElevatedButton),
            findsWidgets,
            reason: 'le bouton d\'action de l\'état vide doit être visible',
          );
          expect(errors, isEmpty, reason: errors.join('\n'));
        });
      }
    }
  }
}
