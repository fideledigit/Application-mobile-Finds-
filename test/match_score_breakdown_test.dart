import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/widgets/match_score_breakdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _match = {
  'scoreNom': 38.0, // Identique
  'scoreType': 30, // Identique
  'scoreNumero': 5.0, // Différent
  'scoreVille': null, // Non évalué
};

Future<void> _pump(WidgetTester tester, Widget child, double w, double s) {
  tester.view.physicalSize = Size(w, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (c, ch) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(s)),
        child: ch!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  test('barèmes et proportions', () {
    final c = MatchCriterion.fromMatch(_match);
    expect(c.map((e) => e.max), [40, 30, 20, 10]);
    expect(c[0].ratio, closeTo(0.95, 0.001));
    expect(c[2].ratio, 0.25);
    expect(c[3].ratio, isNull);
    expect(MatchCriterion.hasAny(_match), isTrue);
    expect(MatchCriterion.hasAny(const {}), isFalse);
  });

  for (final w in [320.0, 411.0]) {
    for (final s in [1.0, 2.0]) {
      testWidgets('détail $w@$s', (tester) async {
        await _pump(tester, const MatchScoreBreakdown(match: _match), w, s);
        expect(tester.takeException(), isNull);
        expect(find.text('38/40'), findsOneWidget);
        expect(find.text('30/30'), findsOneWidget);
        expect(find.text('5/20'), findsOneWidget);
        expect(find.text('–'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
      });

      testWidgets('puces $w@$s', (tester) async {
        await _pump(tester, const MatchScoreChips(match: _match), w, s);
        expect(tester.takeException(), isNull);
        for (final l in ['Nom', 'Type', 'Numéro', 'Ville']) {
          expect(find.text(l), findsOneWidget);
        }
      });
    }
  }
}
