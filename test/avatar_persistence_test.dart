import 'dart:convert';
import 'dart:typed_data';

import 'package:finds/core/api/graphql_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vérifie que la photo de profil survit à un redémarrage de l'app.
///
/// L'API ne renvoie pas `avatarUrl` dans `me` : sans sauvegarde locale, la
/// photo disparaissait à chaque `flutter run`.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.authToken.value = null;
    FindsApiClient.refreshToken.value = null;
    FindsApiClient.currentUser.value = null;
    FindsApiClient.userAvatarBytes.value = null;
    FindsApiClient.userAvatar.value = null;
  });

  test('la photo est restaurée au démarrage suivant', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    await FindsApiClient.setAvatar(bytes, name: 'profil.jpg');
    expect(FindsApiClient.userAvatarBytes.value, bytes);

    // Simule un redémarrage : tout l'état mémoire est perdu, seul le disque
    // reste.
    FindsApiClient.userAvatarBytes.value = null;
    FindsApiClient.userAvatar.value = null;
    FindsApiClient.authToken.value = null;
    FindsApiClient.refreshToken.value = null;
    FindsApiClient.currentUser.value = null;

    SharedPreferences.setMockInitialValues({
      '@auth_access_token': 'access',
      '@auth_refresh_token': 'refresh',
      '@auth_user': jsonEncode({'id': 'user-1'}),
      '@auth_avatar': base64Encode(bytes),
      '@auth_avatar_name': 'profil.jpg',
    });

    await FindsApiClient.restoreSession();

    expect(FindsApiClient.userAvatarBytes.value, bytes);
    expect(FindsApiClient.userAvatar.value, 'profil.jpg');
  });

  test('setAvatar(null) efface la photo enregistrée', () async {
    await FindsApiClient.setAvatar(
      Uint8List.fromList([9, 9, 9]),
      name: 'profil.jpg',
    );
    await FindsApiClient.setAvatar(null);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('@auth_avatar'), isNull);
    expect(prefs.getString('@auth_avatar_name'), isNull);
    expect(FindsApiClient.userAvatarBytes.value, isNull);
  });

  test('une photo trop lourde reste en mémoire sans être persistée', () async {
    final huge = Uint8List(2 * 1024 * 1024 + 1);

    await FindsApiClient.setAvatar(huge, name: 'huge.jpg');

    expect(FindsApiClient.userAvatarBytes.value, huge);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('@auth_avatar'), isNull);
  });

  test('la déconnexion efface la photo enregistrée', () async {
    await FindsApiClient.setAvatar(
      Uint8List.fromList([7, 7]),
      name: 'profil.jpg',
    );

    await FindsApiClient.logout();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('@auth_avatar'), isNull);
    expect(prefs.getString('@auth_avatar_name'), isNull);
    expect(FindsApiClient.userAvatarBytes.value, isNull);
  });
}
