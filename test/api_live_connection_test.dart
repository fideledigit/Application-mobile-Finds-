import 'package:flutter_test/flutter_test.dart';
import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/api/graphql_queries.dart';
import 'package:finds/core/config/api_config.dart';

void main() {
  test(
    'FindsApiClient connects to live API and fetches publicStats and searchDeclarations',
    () async {
      // Vérification de la configuration
      expect(ApiConfig.baseUrl, 'https://nye-agbale.vercel.app');
      expect(
        ApiConfig.graphqlEndpoint,
        'https://nye-agbale.vercel.app/api/graphql',
      );
      expect(
        ApiConfig.uploadEndpoint,
        'https://nye-agbale.vercel.app/api/upload-mobile',
      );

      FindsApiClient.initialize();

      // 1. Test Query publicStats
      final statsResult = await FindsApiClient.query(
        GraphQLQueries.publicStatsQuery,
      );
      expect(
        statsResult.hasException,
        false,
        reason: statsResult.exception.toString(),
      );
      expect(statsResult.data?['publicStats'], isNotNull);
      final stats = statsResult.data!['publicStats'];
      expect(stats['villesCouvertes'], isNotNull);
      expect(stats['utilisateursActifs'], isNotNull);

      // 2. Test Query searchDeclarations
      final searchResult = await FindsApiClient.query(
        GraphQLQueries.searchDeclarationsQuery,
        variables: const {
          'filter': null,
          'pagination': {'page': 1, 'pageSize': 3},
        },
      );
      expect(
        searchResult.hasException,
        false,
        reason: searchResult.exception.toString(),
      );
      expect(searchResult.data?['searchDeclarations'], isNotNull);
      final searchData = searchResult.data!['searchDeclarations']['data'];
      expect(searchData, isA<List>());
      expect(searchData.length, greaterThanOrEqualTo(1));
    },
  );
}
