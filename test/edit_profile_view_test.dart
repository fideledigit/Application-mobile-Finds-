import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/profile/edit_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Link extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) =>
      Stream.value(const Response(response: {}, data: {}));
}

Future<void> _open(
  WidgetTester tester, {
  Map<String, dynamic>? user,
  double width = 411,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  FindsApiClient.currentUser.value = user;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (c) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(c).push(
              MaterialPageRoute(
                builder: (_) => const EditProfileView(
                  initialName: '',
                  initialEmail: 'citoyen@exemple.com',
                  initialPhone: '',
                ),
              ),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.initialize(linkOverride: _Link());
  });

  testWidgets('champs vides : « Votre nom » / « Votre prénom »', (
    tester,
  ) async {
    await _open(tester, user: {'id': 'u1', 'prenom': '', 'nom': ''});
    expect(find.text('Votre prénom'), findsOneWidget);
    expect(find.text('Votre numéro de téléphone'), findsOneWidget);
    // « Votre nom » : indication du champ + aperçu sous la photo.
    expect(find.text('Votre nom'), findsWidgets);
    expect(find.textContaining('Ex.'), findsNothing);
  });

  testWidgets('Enregistrer actif seulement après une modification', (
    tester,
  ) async {
    await _open(tester, user: {'id': 'u1', 'prenom': 'Ama', 'nom': 'MENSAH'});
    expect(find.text('Aucune modification'), findsOneWidget);
    final btn = find.ancestor(
      of: find.text('Aucune modification'),
      matching: find.byType(ElevatedButton),
    );
    expect(tester.widget<ElevatedButton>(btn).onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'Ama'), 'Afi');
    await tester.pump();
    expect(find.text('Enregistrer les modifications'), findsOneWidget);
    // L'aperçu sous la photo suit la saisie.
    expect(find.text('Afi MENSAH'), findsOneWidget);
  });

  testWidgets('retour avec des changements : demande confirmation', (
    tester,
  ) async {
    await _open(tester, user: {'id': 'u1', 'prenom': 'Ama', 'nom': 'MENSAH'});
    await tester.enterText(find.widgetWithText(TextFormField, 'Ama'), 'Afi');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Quitter sans enregistrer ?'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileView), findsOneWidget);

    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitter'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileView), findsNothing);
  });

  for (final width in [320.0, 411.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('pas de débordement $width@$scale', (tester) async {
        await _open(
          tester,
          user: {
            'id': 'u1',
            'prenom': 'Jean-Baptiste Koffi Olivier',
            'nom': 'KOUASSI-AGBODJANFOE-AMEGANVI',
          },
          width: width,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -1500),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
