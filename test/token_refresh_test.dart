import 'dart:convert';

import 'package:finds/core/api/graphql_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Construit un faux JWT (non signé) avec la date d'expiration donnée.
String _jwt(DateTime expiry) {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final payload = {
    'userId': 'user-1',
    'exp': expiry.millisecondsSinceEpoch ~/ 1000,
  };
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part(payload)}.signature';
}

/// Simule le serveur : répond `INTERNAL_SERVER_ERROR` quand le jeton
/// d'accès courant est expiré (comportement réel de l'API).
class _FakeAuthLink extends Link {
  _FakeAuthLink({required this.freshToken, this.refreshFails = false});

  final String freshToken;
  final bool refreshFails;
  final List<String> operations = [];

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    // Le client n'envoie pas d'`operationName` : on reconnaît la mutation de
    // rafraîchissement à ses variables (`input.refreshToken`).
    final input = request.variables['input'];
    final isRefresh = input is Map && input.containsKey('refreshToken');
    operations.add(isRefresh ? 'refresh' : 'query');

    if (isRefresh) {
      if (refreshFails) {
        return Stream.value(
          Response(
            response: const {},
            errors: [const GraphQLError(message: 'refresh indisponible')],
          ),
        );
      }
      return Stream.value(
        Response(
          response: const {},
          data: {
            '__typename': 'Mutation',
            'refreshToken': {
              '__typename': 'AuthPayload',
              'accessToken': freshToken,
              'refreshToken': 'refresh-2',
              'expiresIn': 604800,
            },
          },
        ),
      );
    }

    final token = FindsApiClient.authToken.value ?? '';
    if (_isExpired(token)) {
      return Stream.value(
        Response(
          response: const {},
          errors: [
            const GraphQLError(
              message: 'Erreur interne du serveur',
              extensions: {'code': 'INTERNAL_SERVER_ERROR'},
            ),
          ],
        ),
      );
    }
    return Stream.value(
      Response(
        response: const {},
        data: {
          '__typename': 'Query',
          'me': {'__typename': 'MeResponse', 'id': 'user-1'},
        },
      ),
    );
  }

  bool _isExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map<String, dynamic>;
    final exp = payload['exp'] as int;
    return DateTime.fromMillisecondsSinceEpoch(
      exp * 1000,
      isUtc: true,
    ).isBefore(DateTime.now().toUtc());
  }
}

const _query = r'''
  query Me {
    me {
      id
    }
  }
''';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.authToken.value = null;
    FindsApiClient.refreshToken.value = null;
  });

  test('rafraîchit le jeton expiré avant la requête', () async {
    final expired = _jwt(
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    final fresh = _jwt(DateTime.now().toUtc().add(const Duration(days: 7)));
    final link = _FakeAuthLink(freshToken: fresh);

    FindsApiClient.initialize(linkOverride: link);
    FindsApiClient.authToken.value = expired;
    FindsApiClient.refreshToken.value = 'refresh-1';

    final res = await FindsApiClient.query(_query);

    expect(res.exception, isNull);
    expect(res.data?['me'], isNotNull);
    expect(link.operations, ['refresh', 'query']);
    expect(FindsApiClient.authToken.value, fresh);
    expect(FindsApiClient.refreshToken.value, 'refresh-2');
  });

  test('ne rafraîchit pas un jeton encore valide', () async {
    final valid = _jwt(DateTime.now().toUtc().add(const Duration(days: 7)));
    final link = _FakeAuthLink(freshToken: valid);

    FindsApiClient.initialize(linkOverride: link);
    FindsApiClient.authToken.value = valid;
    FindsApiClient.refreshToken.value = 'refresh-1';

    final res = await FindsApiClient.query(_query);

    expect(res.exception, isNull);
    expect(link.operations, ['query']);
  });

  test('ne déconnecte pas si le rafraîchissement échoue hors-ligne', () async {
    final expired = _jwt(
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    final link = _FakeAuthLink(freshToken: expired, refreshFails: true);

    FindsApiClient.initialize(linkOverride: link);
    FindsApiClient.authToken.value = expired;
    FindsApiClient.refreshToken.value = 'refresh-1';

    final res = await FindsApiClient.query(_query);

    expect(res.exception, isNotNull);
    expect(FindsApiClient.authToken.value, expired);
    expect(FindsApiClient.isAuthenticated, isTrue);
  });
}
