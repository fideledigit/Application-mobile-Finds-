import 'package:finds/core/api/graphql_client.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/auth/register_view.dart';
import 'package:finds/presentation/views/profile/edit_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Capture les variables envoyées au serveur.
final sent = <Map<String, dynamic>>[];

class _Link extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    sent.add(Map<String, dynamic>.from(request.variables));
    return Stream.value(
      const Response(response: {}, data: {'__typename': 'Mutation'}),
    );
  }
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: home));
  await tester.pump();
}

Finder _fieldAfter(String label) => find
    .descendant(
      of: find
          .ancestor(of: find.textContaining(label), matching: find.byType(Column))
          .first,
      matching: find.byType(TextField),
    )
    .first;

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    FindsApiClient.initialize(linkOverride: _Link());
  });
  setUp(sent.clear);

  testWidgets('inscription : prénom et nom envoyés séparément', (tester) async {
    await _pump(tester, const RegisterView());
    expect(find.textContaining('Prénom'), findsOneWidget);
    expect(find.textContaining('Nom de famille'), findsOneWidget);
    expect(find.text('Nom et prénom'), findsNothing);

    // Le champ Nom est au-dessus du champ Prénom.
    expect(
      tester.getTopLeft(find.textContaining('Nom de famille')).dy,
      lessThan(tester.getTopLeft(find.textContaining('Prénom')).dy),
    );
    await tester.enterText(_fieldAfter('Prénom'), 'AKOSSIWA');
    await tester.enterText(_fieldAfter('Nom de famille'), 'dofor');
    // Le nom s'affiche en majuscules pendant la saisie.
    expect(find.text('DOFOR'), findsOneWidget);
    await tester.enterText(_fieldAfter('Adresse e-mail'), 'test@exemple.com');
    await tester.enterText(_fieldAfter('Numéro de téléphone'), '90123456');
    final pwd = find.byType(TextField).evaluate().length;
    // Les deux derniers champs sont le mot de passe et sa confirmation.
    await tester.enterText(find.byType(TextField).at(pwd - 2), 'MotDePasse1!');
    await tester.enterText(find.byType(TextField).at(pwd - 1), 'MotDePasse1!');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump(const Duration(milliseconds: 200));

    final input = sent
        .map((v) => v['input'])
        .whereType<Map>()
        .firstWhere((i) => i.containsKey('prenom'));
    expect(input['prenom'], 'Akossiwa');
    expect(input['nom'], 'DOFOR');
  });

  testWidgets('profil : prénom et nom pré-remplis et enregistrés', (
    tester,
  ) async {
    FindsApiClient.currentUser.value = {
      'id': 'u1',
      'prenom': 'Akossiwa',
      'nom': 'DOFOR',
      'email': 'test@exemple.com',
    };
    await _pump(
      tester,
      const EditProfileView(
        initialName: 'Akossiwa DOFOR',
        initialEmail: 'test@exemple.com',
        initialPhone: '+22890000000',
      ),
    );
    expect(find.text('Akossiwa'), findsOneWidget);
    expect(find.text('DOFOR'), findsOneWidget);

    // Un compte inversé se corrige en échangeant les deux champs.
    expect(
      tester.getTopLeft(find.textContaining('Nom de famille')).dy,
      lessThan(tester.getTopLeft(find.textContaining('Prénom')).dy),
    );
    await tester.enterText(_fieldAfter('Prénom'), 'fulbertine');
    await tester.enterText(_fieldAfter('Nom de famille'), 'dofor');
    await tester.ensureVisible(find.text('Enregistrer les modifications'));
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pump(const Duration(milliseconds: 200));

    final input = sent
        .map((v) => v['input'])
        .whereType<Map>()
        .firstWhere((i) => i.containsKey('prenom'));
    expect(input['prenom'], 'Fulbertine');
    expect(input['nom'], 'DOFOR');
    await tester.pumpWidget(const SizedBox());
  });
}
