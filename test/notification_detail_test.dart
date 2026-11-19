import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/home/home_dashboard_view.dart';
import 'package:finds/presentation/views/notifications/notification_detail_view.dart';
import 'package:finds/presentation/views/notifications/notifications_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _titre = 'Maintenance prévue samedi';
const _corps =
    'Bonjour à tous, le service Finds sera en maintenance samedi de 8h à 10h. '
    'Pendant ce temps, vous ne pourrez pas publier de déclaration. Les '
    'correspondances déjà trouvées restent visibles. Merci de votre patience. '
    'FIN-DU-MESSAGE';

class _Link extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    final q = request.toString();
    final data = <String, dynamic>{'__typename': 'Query'};
    if (request.operation.operationName == 'MyNotifications' ||
        q.contains('myNotifications')) {
      data['myNotifications'] = {
        '__typename': 'PaginatedNotifications',
        'data': [
          {
            '__typename': 'Notification',
            'id': 'n1',
            // Les messages de l'admin web n'ont pas de type propre.
            'type': 'RAPPEL_DECLARATION',
            'statut': 'NON_LUE',
            'titre': _titre,
            'corps': _corps,
            'createdAt': '2026-11-12T09:30:00.000Z',
            'lueAt': null,
            'donnees': null,
          },
        ],
        'meta': {
          '__typename': 'PaginationMeta',
          'total': 1,
          'page': 1,
          'pageSize': 50,
          'totalPages': 1,
        },
      };
    }
    if (q.contains('myDeclarations')) {
      data['myDeclarations'] = {
        '__typename': 'PaginatedDeclarations',
        'data': [],
        'meta': {
          '__typename': 'PaginationMeta',
          'total': 0,
          'page': 1,
          'pageSize': 100,
          'totalPages': 1,
        },
      };
    }
    if (q.contains('markNotificationRead')) {
      data['markNotificationRead'] = {
        '__typename': 'MutationResponse',
        'success': true,
        'message': 'ok',
      };
    }
    return Stream.value(Response(response: const {}, data: data));
  }
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: home));
  for (var i = 0; i < 20 && find.text(_titre).evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.initialize(linkOverride: _Link());
    FindsApiClient.authToken.value = 'test-token';
  });

  test('types qui s\'ouvrent en entier', () {
    for (final t in [null, '', 'BIENVENUE', 'RAPPEL_DECLARATION', 'AUTRE']) {
      expect(NotificationDetailView.isInformational(t), isTrue, reason: t);
    }
    for (final t in ['MATCH_TROUVE', 'NOUVEAU_MESSAGE', 'EVALUATION_RECUE']) {
      expect(NotificationDetailView.isInformational(t), isFalse, reason: t);
    }
  });

  testWidgets('page Notifications : ouvre le message en entier', (
    tester,
  ) async {
    final tabs = <int>[];
    await _pump(tester, NotificationsListView(onNavigateToTab: tabs.add));
    expect(find.text(_titre), findsOneWidget);

    await tester.tap(find.text(_titre));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationDetailView), findsOneWidget);
    expect(find.textContaining('FIN-DU-MESSAGE'), findsOneWidget);
    expect(tabs, isEmpty, reason: 'ne doit pas ouvrir un onglet');
    expect(tester.takeException(), isNull);
  });

  testWidgets('accueil : activité récente ouvre le message en entier', (
    tester,
  ) async {
    final tabs = <int>[];
    await _pump(tester, HomeDashboardView(onNavigateToTab: tabs.add));
    expect(find.text(_titre), findsOneWidget);

    await tester.ensureVisible(find.text(_titre));
    await tester.tap(find.text(_titre));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationDetailView), findsOneWidget);
    expect(find.textContaining('FIN-DU-MESSAGE'), findsOneWidget);
    expect(tabs, isEmpty, reason: 'ne doit pas ouvrir Déclarations');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
