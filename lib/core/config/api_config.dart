import 'package:flutter/foundation.dart';

/// ════════════════════════════════════════════════════════════════════════
///  CONFIGURATION DE L'API FINDS / RETROUVETOUT
/// ════════════════════════════════════════════════════════════════════════
///
/// Règle d'or : **une seule URL de base dans toute l'application**.
/// Aucun autre fichier ne doit coder en dur « http://… » ou « https://… ».
///
/// ─────────────────────────────────────────────────────────────────────
///  URL ACTUELLE vs DÉPLOIEMENT
/// ─────────────────────────────────────────────────────────────────────
///  - Actuellement : https://nye-agbale.vercel.app (API active)
///  - Après ton déploiement : remplace simplement [defaultBaseUrl] ci-dessous
///    par l'URL de ton propre serveur (ex: https://mon-api.vercel.app).
///  - Ou passe --dart-define=API_URL=https://... au moment du build.
///
class ApiConfig {
  ApiConfig._();

  // =======================================================================
  //  1. URL DE BASE DU BACKEND  ←  À REMPLACER APRÈS TON DÉPLOIEMENT
  // =======================================================================
  /// URL de base actuelle pointant vers l'API Vercel live.
  /// Le jour où tu déploies ta propre instance de l'API, change cette ligne :
  static const String defaultBaseUrl = 'https://nye-agbale.vercel.app';

  // =======================================================================
  //  2. SURCHARGE PAR LIGNE DE COMMANDE (Optionnel en CI / Build)
  // =======================================================================
  /// Rempli si tu lances : flutter run --dart-define=API_URL=https://...
  static const String _envUrl = String.fromEnvironment('API_URL');

  /// URL de base active
  static String get baseUrl => _envUrl.isNotEmpty ? _envUrl : defaultBaseUrl;

  // =======================================================================
  //  3. POINTS D'ENTRÉE (GRAPHQL & UPLOAD MULTIPART)
  // =======================================================================
  /// Point d'accès GraphQL principal
  static String get graphqlEndpoint => '$baseUrl/api/graphql';

  /// Point d'accès pour l'upload d'images (multipart POST)
  static String get uploadEndpoint => '$baseUrl/api/upload-mobile';

  /// `true` si l'app communique en HTTPS sécurisé
  static bool get isSecure => graphqlEndpoint.startsWith('https://');

  /// Nom lisible de l'environnement (pour logs ou badge de debug)
  static String get environmentLabel {
    if (_envUrl.isNotEmpty) return 'dart-define ($baseUrl)';
    if (kReleaseMode) return 'production';
    return 'cloud ($baseUrl)';
  }
}
