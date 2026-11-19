import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/home/home_dashboard_view.dart';
import 'package:finds/presentation/views/matches/matches_list_view.dart';
import 'package:finds/presentation/views/messages/conversations_list_view.dart';
import 'package:finds/presentation/views/notifications/notifications_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _long = 'Jean-Baptiste Koffi Olivier Emmanuel';
const _longNom = 'KOUASSI-AGBODJANFOE-AMEGANVI';
const _date = '2026-03-14T10:00:00.000Z';
Map<String, dynamic> _meta(int n) => {
  '__typename': 'PaginationMeta',
  'page': 1,
  'pageSize': 50,
  'total': n,
  'totalPages': 1,
};
Map<String, dynamic> _user(int i) => {
  '__typename': 'UserBrief',
  'id': 'u$i',
  'nom': _longNom,
  'prenom': _long,
};
const _notifTypes = [
  'MATCH_TROUVE',
  'MATCH_ACCEPTE',
  'NOUVEAU_MESSAGE',
  'CONVERSATION_RESOLUE',
  'REMERCIEMENT_TROUVEUR',
  'BIENVENUE',
];

Map<String, dynamic> _decl(int i) => {
  '__typename': 'Declaration',
  'id': 'cmd8x7q2a0000abcdefghij$i',
  'type': i.isEven ? 'PERTE' : 'TROUVAILLE',
  'typeDocument': [
    'CNI',
    'CERTIFICAT_NATIONALITE',
    'CARTE_PROFESSIONNELLE',
  ][i % 3],
  'nomProprietaire': _longNom,
  'prenomProprietaire': _long,
  'numeroDocument': 'TG-CAR-2024-99887766-$i',
  'descriptionLibre': 'x',
  'ville': 'Lomé (Golfe) Préfecture du Grand Lomé',
  'quartier': 'Marché d\'Adawlato entrée principale côté lagune',
  'statut': ['ACTIVE', 'MATCHEE', 'RESOLUE'][i % 3],
  'photoUrl': null,
  'photoFlouteeUrl': null,
  'pdfUrl': null,
  'matchesCount': 2,
  'createdAt': _date,
  'updatedAt': _date,
};

class _Link extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    final q = request.toString();
    final d = <String, dynamic>{'__typename': 'Query'};
    if (q.contains('myNotifications')) {
      d['myNotifications'] = {
        '__typename': 'PaginatedNotifications',
        'data': [
          for (var i = 0; i < 6; i++)
            {
              '__typename': 'Notification',
              'id': 'n$i',
              'type': _notifTypes[i],
              'statut': i.isEven ? 'NON_LUE' : 'LUE',
              'titre':
                  'Nouveau match trouvé pour votre Certificat de nationalité au nom de $_longNom',
              'corps':
                  'Correspondance à 100% avec un document signalé à Lomé, quartier Adawlato, entrée principale côté lagune.',
              'createdAt': _date,
              'lueAt': null,
              'donnees': null,
            },
        ],
        'meta': _meta(6),
      };
    }
    if (q.contains('myConversations')) {
      d['myConversations'] = {
        '__typename': 'PaginatedConversations',
        'data': [
          for (var i = 0; i < 4; i++)
            {
              '__typename': 'Conversation',
              'id': 'c$i',
              'matchId': 'm$i',
              'statut': ['OUVERTE', 'RESOLUE', 'FERMEE', 'SIGNALEE'][i],
              'nombreMessages': 3,
              'updatedAt': _date,
              'participants': [
                {
                  '__typename': 'ConversationParticipant',
                  'userId': 'me',
                  'nombreNonLus': 120,
                  'user': _user(0),
                },
                {
                  '__typename': 'ConversationParticipant',
                  'userId': 'u$i',
                  'nombreNonLus': 0,
                  'user': _user(i + 1),
                },
              ],
              'messages': [
                {
                  '__typename': 'Message',
                  'id': 'msg$i',
                  'contenu':
                      'Bonjour, je pense avoir trouvé votre document près du grand marché, pouvons-nous convenir d\'un rendez-vous ?',
                  'createdAt': _date,
                  'expediteurId': 'u$i',
                  'estSysteme': false,
                },
              ],
            },
        ],
        'meta': {
          '__typename': 'PaginationMeta',
          'total': 4,
          'page': 1,
          'totalPages': 1,
        },
      };
    }
    if (q.contains('myDeclarations')) {
      d['myDeclarations'] = {
        '__typename': 'PaginatedDeclarations',
        'data': List.generate(3, _decl),
        'meta': _meta(3),
      };
    }
    if (q.contains('declarationMatches')) {
      d['declarationMatches'] = [
        for (var i = 0; i < 2; i++)
          {
            '__typename': 'Match',
            'id': 'cmatch000abcdefgh${q.hashCode}$i',
            'perteId': 'p',
            'trouvailleId': 't',
            'score': 97.5,
            'scoreNom': 40,
            'scoreType': 30,
            'scoreNumero': 20,
            'scoreVille': 7.5,
            'statut': i == 0 ? 'EN_ATTENTE' : 'ACCEPTE',
            'confirmeParDeclarant': false,
            'confirmeParTrouveur': true,
            'createdAt': _date,
          },
      ];
    }
    return Stream.value(Response(response: const {}, data: d));
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.initialize(linkOverride: _Link());
    FindsApiClient.authToken.value = 'test-token';
    FindsApiClient.currentUser.value = {
      'id': 'me',
      'nom': _longNom,
      'prenom': _long,
    };
  });

  final pages = <String, Widget Function()>{
    'matchs': () => const MatchesListView(),
    'messagerie': () => const ConversationsListView(),
    'notifications': () => NotificationsListView(onNavigateToTab: (_) {}),
    'accueil': () => const HomeDashboardView(),
  };

  for (final entry in pages.entries) {
    for (final width in [320.0, 360.0, 411.0]) {
      for (final scale in [1.0, 1.3, 1.5, 2.0]) {
        testWidgets('${entry.key} avec données $width@$scale', (tester) async {
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
                home: Scaffold(body: entry.value()),
              ),
            );
            for (var i = 0; i < 12; i++) {
              await tester.runAsync(
                () => Future.delayed(const Duration(milliseconds: 20)),
              );
              await tester.pump(const Duration(milliseconds: 50));
            }
            final scrollables = find.byType(Scrollable);
            if (scrollables.evaluate().isNotEmpty) {
              for (var i = 0; i < 10; i++) {
                await tester.drag(
                  scrollables.first,
                  const Offset(0, -300),
                  warnIfMissed: false,
                );
                await tester.pump();
              }
            }
          } finally {
            FlutterError.onError = old;
          }
          expect(errors, isEmpty, reason: errors.join('\n'));
        });
      }
    }
  }
}
