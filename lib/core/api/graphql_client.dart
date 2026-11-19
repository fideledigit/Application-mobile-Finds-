import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'graphql_queries.dart';
import '../utils/name_utils.dart';

/// Configuration du client GraphQL pour l'application mobile Finds
///
/// L'URL de l'API est définie dans `lib/core/config/api_config.dart`.
class FindsApiClient {
  FindsApiClient._();

  /// URL de base, déléguée à [ApiConfig.graphqlEndpoint].
  static String get defaultEndpoint => ApiConfig.graphqlEndpoint;

  /// URL réellement utilisée par le client (après initialisation).
  static String _endpoint = '';

  /// URL active — utile pour l'afficher dans un log ou un écran de debug.
  static String get endpoint => _isInitialized ? _endpoint : defaultEndpoint;

  /// Jeton JWT d'accès conservé en mémoire pour authentifier les requêtes
  static final ValueNotifier<String?> authToken = ValueNotifier<String?>(null);

  /// Jeton de rafraîchissement JWT (pour prolonger la session automatiquement)
  static final ValueNotifier<String?> refreshToken = ValueNotifier<String?>(
    null,
  );

  /// Informations de l'utilisateur actuellement connecté
  static final ValueNotifier<Map<String, dynamic>?> currentUser =
      ValueNotifier<Map<String, dynamic>?>(null);

  /// Photo de profil ou avatar personnalisé (URL ou nom d'avatar)
  static final ValueNotifier<String?> userAvatar = ValueNotifier<String?>(null);

  /// Contenu binaire de l'avatar choisi localement (affichage immédiat).
  static final ValueNotifier<Uint8List?> userAvatarBytes =
      ValueNotifier<Uint8List?>(null);

  /// Compteur réactif incrémenté lors de toute création de déclaration
  /// pour forcer le rafraîchissement immédiat de "Mes Déclarations".
  static final ValueNotifier<int> declarationsRevision = ValueNotifier<int>(0);

  /// Badges de la barre de navigation (mis à jour par les écrans
  /// Matches et Messages après chaque chargement).
  static final ValueNotifier<int> pendingMatchesCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> unreadMessagesCount = ValueNotifier<int>(0);

  /// Prénom de l'utilisateur connecté (dynamique)
  static String get userFirstName {
    final user = currentUser.value;
    if (user == null) return 'Citoyen';
    final name = greetingFirstName(
      user['prenom'] as String?,
      user['nom'] as String?,
    );
    if (name.isNotEmpty) return name;
    final fullName = user['fullName'] as String? ?? '';
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Citoyen';
    return trimmed.split(' ').first;
  }

  /// Prénom à afficher dans « Bonjour, … ».
  ///
  /// Les comptes créés avec l'ancien champ unique « Nom et prénom » ont
  /// souvent le nom de famille enregistré comme prénom (ex. prénom « MENSAH »).
  /// Le nom de famille s'écrit en MAJUSCULES : si le prénom est tout en
  /// majuscules et pas le nom, les deux sont inversés et on affiche le nom.
  /// Le résultat est mis en forme : « ama » → « Ama ».
  @visibleForTesting
  static String greetingFirstName(String? prenom, String? nom) {
    final p = (prenom ?? '').trim();
    final n = (nom ?? '').trim();
    bool isUpper(String s) =>
        s.length > 1 && s == s.toUpperCase() && s != s.toLowerCase();
    final chosen = (isUpper(p) && n.isNotEmpty && !isUpper(n)) ? n : p;
    return formatFirstName(chosen);
  }

  /// Nom de famille de l'utilisateur connecté (dynamique)
  static String get userLastName {
    final user = currentUser.value;
    if (user == null) return '';
    final nom = user['nom'] as String?;
    if (nom != null && nom.trim().isNotEmpty) return nom.trim();
    final fullName = user['fullName'] as String? ?? '';
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  /// Nom complet de l'utilisateur connecté (dynamique)
  static String get userFullName {
    final user = currentUser.value;
    if (user == null) return 'Citoyen Finds';
    final prenom = user['prenom'] as String? ?? '';
    final nom = user['nom'] as String? ?? '';
    final full = '$prenom $nom'.trim();
    if (full.isNotEmpty) return full;
    final fullName = user['fullName'] as String? ?? '';
    return fullName.trim().isNotEmpty ? fullName.trim() : 'Citoyen Finds';
  }

  /// Adresse e-mail de l'utilisateur connecté (dynamique)
  static String get userEmail {
    return currentUser.value?['email'] as String? ?? 'citoyen@finds.tg';
  }

  /// Numéro de téléphone de l'utilisateur connecté (dynamique)
  static String get userPhone {
    final user = currentUser.value;
    return user?['telephone'] as String? ??
        user?['phone'] as String? ??
        '+228 90 00 00 00';
  }

  /// Adresse de résidence de l'utilisateur connecté (dynamique)
  static String get userAddress {
    final user = currentUser.value;
    return user?['adresse'] as String? ??
        user?['adresseResidence'] as String? ??
        user?['ville'] as String? ??
        user?['address'] as String? ??
        '';
  }

  /// Points de réputation civique de l'utilisateur
  static int get userReputation {
    final user = currentUser.value;
    return user?['scoreReputation'] as int? ??
        user?['reputationPoints'] as int? ??
        150;
  }

  /// Initiale pour l'avatar (ex: 'K' pour Koffi, 'B' pour Bénédicte)
  static String get userInitial {
    // Même source que « Bonjour, … » : l'initiale correspond au prénom affiché.
    final name = userFirstName;
    return name.isNotEmpty ? name[0].toUpperCase() : 'C';
  }

  /// Client GraphQL configuré
  static late GraphQLClient _client;

  /// Client sans AuthLink, utilisé uniquement pour rafraîchir le token
  /// (comme le `fetch` brut de citizen-connect-mobile/lib/apollo.ts).
  static late GraphQLClient _bareClient;

  /// Indique si le client a été initialisé
  static bool _isInitialized = false;

  // Mêmes clés que AsyncStorage dans citizen-connect-mobile (AuthContext.tsx)
  static const String _kAccessToken = '@auth_access_token';
  static const String _kRefreshToken = '@auth_refresh_token';
  static const String _kUser = '@auth_user';
  static const String _kAvatar = '@auth_avatar';
  static const String _kAvatarName = '@auth_avatar_name';

  /// Appelé quand la session est invalide (refresh échoué, compte
  /// désactivé…). `main.dart` s'en sert pour renvoyer vers la connexion.
  static VoidCallback? onSessionExpired;

  static bool get isAuthenticated =>
      authToken.value != null && authToken.value!.isNotEmpty;

  /// Initialise le client GraphQL
  static void initialize({
    String? customEndpoint,
    @visibleForTesting Link? linkOverride,
  }) {
    final endpoint = customEndpoint ?? defaultEndpoint;
    _endpoint = endpoint;
    final Link httpLink = linkOverride ?? HttpLink(endpoint);

    final AuthLink authLink = AuthLink(
      getToken: () async {
        final token = authToken.value;
        return (token != null && token.isNotEmpty) ? 'Bearer $token' : null;
      },
    );

    _client = GraphQLClient(
      link: authLink.concat(httpLink),
      cache: GraphQLCache(store: InMemoryStore()),
    );
    _bareClient = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );

    _isInitialized = true;
    debugPrint(
      '[FindsApiClient] Client GraphQL initialisé '
      '(${ApiConfig.environmentLabel}) vers $endpoint',
    );
  }

  /// Accès au client GraphQL
  static GraphQLClient get client {
    if (!_isInitialized) {
      initialize();
    }
    return _client;
  }

  // ===================================================================
  //  SESSION (équivalent de AuthContext.tsx)
  // ===================================================================

  /// Restaure la session sauvegardée au démarrage de l'app.
  static Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final access = prefs.getString(_kAccessToken);
      final refresh = prefs.getString(_kRefreshToken);
      final userJson = prefs.getString(_kUser);
      if (access == null || refresh == null || userJson == null) return;

      authToken.value = access;
      refreshToken.value = refresh;
      currentUser.value = Map<String, dynamic>.from(
        jsonDecode(userJson) as Map,
      );

      // Photo de profil : conservée sur l'appareil pour survivre aux
      // redémarrages (l'API ne la renvoie pas dans `me`).
      final avatar = prefs.getString(_kAvatar);
      if (avatar != null) {
        try {
          userAvatarBytes.value = base64Decode(avatar);
          userAvatar.value = prefs.getString(_kAvatarName);
        } catch (_) {
          // Avatar illisible : on ignore, l'initiale sera affichée.
        }
      }

      debugPrint('[FindsApiClient] Session restaurée pour $userEmail');
    } catch (e) {
      debugPrint('[FindsApiClient] Restauration de session impossible : $e');
    }
  }

  /// Enregistre la session après `login` ou `register`.
  static Future<void> signIn({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    authToken.value = accessToken;
    FindsApiClient.refreshToken.value = refreshToken;
    currentUser.value = user;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kAccessToken, accessToken),
      prefs.setString(_kRefreshToken, refreshToken),
      prefs.setString(_kUser, jsonEncode(user)),
    ]);
  }

  /// Met à jour l'utilisateur en mémoire et sur le disque.
  static Future<void> updateCurrentUser(Map<String, dynamic> changes) async {
    final merged = {...?currentUser.value, ...changes};
    currentUser.value = merged;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(merged));
  }

  /// Enregistre la photo de profil en mémoire et sur l'appareil, pour
  /// qu'elle survive aux redémarrages de l'application.
  ///
  /// L'API ne renvoie pas l'avatar dans `me` : sans cette sauvegarde locale,
  /// la photo disparaît à chaque relance de l'app.
  static Future<void> setAvatar(Uint8List? bytes, {String? name}) async {
    userAvatarBytes.value = bytes;
    userAvatar.value = name;

    final prefs = await SharedPreferences.getInstance();
    if (bytes == null) {
      await Future.wait([
        prefs.remove(_kAvatar),
        prefs.remove(_kAvatarName),
      ]);
      return;
    }

    // SharedPreferences n'est pas prévu pour de très gros contenus : au-delà
    // de 2 Mo, on garde la photo en mémoire seulement (elle sera perdue au
    // redémarrage, mais l'app reste fluide).
    if (bytes.length > 2 * 1024 * 1024) {
      await Future.wait([
        prefs.remove(_kAvatar),
        prefs.remove(_kAvatarName),
      ]);
      debugPrint(
        '[FindsApiClient] Avatar trop volumineux : non enregistré sur '
        "l'appareil.",
      );
      return;
    }

    await prefs.setString(_kAvatar, base64Encode(bytes));
    if (name != null) {
      await prefs.setString(_kAvatarName, name);
    } else {
      await prefs.remove(_kAvatarName);
    }
  }

  static Future<void> _updateTokens(String access, String? refresh) async {
    authToken.value = access;
    if (refresh != null) refreshToken.value = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, access);
    if (refresh != null) await prefs.setString(_kRefreshToken, refresh);
  }

  /// Déconnexion : prévient le serveur, vide les jetons, le disque et le cache.
  static Future<void> logout() async {
    if (isAuthenticated) {
      try {
        await client
            .mutate(
              MutationOptions(document: gql(GraphQLQueries.logoutMutation)),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // La déconnexion locale doit réussir même hors-ligne.
      }
    }
    await _clearSession();
    debugPrint('[FindsApiClient] Déconnexion effectuée.');
  }

  static Future<void> _clearSession() async {
    authToken.value = null;
    refreshToken.value = null;
    currentUser.value = null;
    userAvatar.value = null;
    userAvatarBytes.value = null;
    pendingMatchesCount.value = 0;
    unreadMessagesCount.value = 0;
    client.cache.store.reset();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kAccessToken),
      prefs.remove(_kRefreshToken),
      prefs.remove(_kUser),
      prefs.remove(_kAvatar),
      prefs.remove(_kAvatarName),
      ...prefs
          .getKeys()
          .where((k) => k.startsWith(_kCachePrefix))
          .map(prefs.remove),
    ]);
  }

  static Future<void> _expireSession() async {
    await _clearSession();
    onSessionExpired?.call();
  }

  // ===================================================================
  //  REFRESH TOKEN + ERREURS (équivalent de errorLink dans apollo.ts)
  // ===================================================================

  static Future<String?>? _refreshing;

  /// Un seul rafraîchissement à la fois : les requêtes concurrentes
  /// attendent le même Future (comme `pendingRequests` dans apollo.ts).
  static Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  static Future<String?> _doRefresh() async {
    final refresh = refreshToken.value;
    if (refresh == null || refresh.isEmpty) return null;
    if (!_isInitialized) initialize();
    try {
      final res = await _bareClient.mutate(
        MutationOptions(
          document: gql(GraphQLQueries.refreshTokenMutation),
          variables: {
            'input': {'refreshToken': refresh},
          },
          fetchPolicy: FetchPolicy.noCache,
        ),
      );
      final data = res.data?['refreshToken'];
      final newAccess = data?['accessToken'] as String?;
      if (res.hasException || newAccess == null) return null;
      await _updateTokens(newAccess, data['refreshToken'] as String?);
      debugPrint('[FindsApiClient] Token rafraîchi.');
      return newAccess;
    } catch (e) {
      debugPrint('[FindsApiClient] Échec du rafraîchissement : $e');
      return null;
    }
  }

  static String? _firstErrorCode(OperationException? e) {
    if (e == null) return null;
    for (final err in e.graphqlErrors) {
      final code = err.extensions?['code'];
      if (code is String) return code;
    }
    return null;
  }

  static bool _isAuthError(OperationException? e) {
    if (e == null) return false;
    for (final err in e.graphqlErrors) {
      final code = err.extensions?['code'];
      final msg = err.message;
      if (code == 'UNAUTHENTICATED' ||
          code == 'FORBIDDEN' ||
          msg.contains('jwt expired') ||
          msg.contains('jwt malformed') ||
          msg.contains('Not authenticated') ||
          msg.contains('Non authentifié')) {
        return true;
      }
    }
    final link = e.linkException;
    if (link is ServerException) {
      return link.statusCode == 401 || link.statusCode == 403;
    }
    return false;
  }

  /// `true` si le jeton d'accès stocké est expiré (ou expire dans les
  /// secondes qui viennent).
  ///
  /// L'API répond `INTERNAL_SERVER_ERROR` — et non `401` — quand le JWT
  /// est expiré. On décode donc son champ `exp` localement pour rafraîchir
  /// la session *avant* d'envoyer la requête, au lieu d'attendre une
  /// erreur que l'app ne saurait pas reconnaître.
  static bool _isAccessTokenExpired({
    Duration leeway = const Duration(seconds: 30),
  }) {
    final token = authToken.value;
    if (token == null || token.isEmpty) return false;
    final parts = token.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return false;
      final exp = payload['exp'];
      if (exp is! int) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp * 1000,
        isUtc: true,
      );
      return DateTime.now().toUtc().isAfter(expiry.subtract(leeway));
    } catch (_) {
      // Jeton illisible : on laisse le serveur trancher.
      return false;
    }
  }

  static Future<QueryResult> _run(Future<QueryResult> Function() send) async {
    // Jeton expiré : l'API renverrait « Erreur interne du serveur ». On le
    // rafraîchit d'abord ; les requêtes concurrentes partagent le même
    // Future de rafraîchissement (voir [_refreshing]).
    if (isAuthenticated && _isAccessTokenExpired()) {
      await _refreshAccessToken();
    }

    final res = await send();
    final e = res.exception;

    final code = _firstErrorCode(e);
    if (code == 'ACCOUNT_DISABLED' || code == 'MODULE_DISABLED') {
      await _expireSession();
      return res;
    }

    // Filet de sécurité : si le jeton a expiré pendant la requête, l'API a
    // répondu 500. On tente un rafraîchissement puis on rejoue une fois.
    final expiredDuringRequest =
        code == 'INTERNAL_SERVER_ERROR' &&
        isAuthenticated &&
        _isAccessTokenExpired();

    if (!_isAuthError(e) && !expiredDuringRequest) return res;
    if (!isAuthenticated) return res;

    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      // En cas d'expiration détectée localement, on ne déconnecte pas :
      // le rafraîchissement a peut-être échoué faute de réseau.
      if (!expiredDuringRequest) await _expireSession();
      return res;
    }
    return send();
  }

  /// Exécute une requête (Query)
  static Future<QueryResult> query(
    String queryString, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
  }) {
    final options = QueryOptions(
      document: gql(queryString),
      variables: variables ?? const {},
      fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
    );
    return _run(
      () => client.query(options),
    ).then((res) => _withOfflineCache(res, options, queryString, variables));
  }

  // ===================================================================
  //  CACHE HORS-LIGNE (équivalent de apollo3-cache-persist dans citizen)
  // ===================================================================

  static const String _kCachePrefix = '@query_cache:';

  static String _cacheKey(String query, Map<String, dynamic>? variables) {
    final user = currentUser.value?['id'] ?? 'anon';
    final normalized = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    return '$_kCachePrefix$user:${normalized.hashCode}:${jsonEncode(variables ?? const {})}';
  }

  /// Sauvegarde chaque réponse réussie ; sans réseau, renvoie la dernière
  /// réponse connue (marquée `source: cache`).
  static Future<QueryResult> _withOfflineCache(
    QueryResult res,
    QueryOptions options,
    String query,
    Map<String, dynamic>? variables,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(query, variables);

      if (!res.hasException && res.data != null) {
        await prefs.setString(key, jsonEncode(res.data));
        return res;
      }

      final offline =
          res.exception?.linkException != null &&
          res.exception!.graphqlErrors.isEmpty;
      final cached = offline ? prefs.getString(key) : null;
      if (cached == null) return res;

      debugPrint('[FindsApiClient] Hors-ligne : données en cache utilisées.');
      return QueryResult(
        options: options,
        data: Map<String, dynamic>.from(jsonDecode(cached) as Map),
        source: QueryResultSource.cache,
      );
    } catch (_) {
      return res;
    }
  }

  /// `true` si le résultat vient du cache hors-ligne (pas du serveur).
  static bool isFromOfflineCache(QueryResult res) =>
      res.source == QueryResultSource.cache;

  /// Exécute une mutation
  static Future<QueryResult> mutate(
    String mutationString, {
    Map<String, dynamic>? variables,
  }) {
    final options = MutationOptions(
      document: gql(mutationString),
      variables: variables ?? const {},
    );
    return _run(() => client.mutate(options));
  }

  /// Message d'erreur lisible pour l'utilisateur.
  static String errorMessage(
    OperationException? e, {
    String fallback = 'Une erreur est survenue.',
  }) {
    if (e == null) return fallback;
    if (e.graphqlErrors.isNotEmpty) return e.graphqlErrors.first.message;
    if (e.linkException != null) {
      return 'Serveur injoignable. Vérifiez votre connexion internet.';
    }
    return fallback;
  }
}
