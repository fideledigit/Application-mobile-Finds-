import 'package:finds/core/api/graphql_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String g(String? p, String? n) => FindsApiClient.greetingFirstName(p, n);

  test('compte normal : affiche le prénom', () {
    expect(g('Akossiwa', 'DOFOR'), 'Akossiwa');
    expect(g('akossiwa', 'dofor'), 'Akossiwa');
    expect(g('Jean-baptiste', 'KOUASSI'), 'Jean-Baptiste');
  });

  test('ancien compte inversé : affiche le vrai prénom', () {
    // Cas réel : prénom « DOFOR », nom « fulbetine ».
    expect(g('DOFOR', 'fulbetine'), 'Fulbetine');
    expect(g('KOFFI', 'Ama'), 'Ama');
  });

  test('cas où on ne peut pas savoir : on garde le prénom', () {
    expect(g('DOFOR', 'AKOSSIWA'), 'Dofor'); // les deux en majuscules
    expect(g('DOFOR', ''), 'Dofor'); // pas de nom
    expect(g('', 'Ama'), ''); // pas de prénom → repli géré ailleurs
  });
}
