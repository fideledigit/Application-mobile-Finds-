import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finds/core/theme/app_theme.dart';
import 'package:finds/presentation/views/search/document_search_view.dart';

void main() {
  for (final width in [320.0, 360.0, 411.0]) {
    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final typed in [false, true]) {
        testWidgets('search $width@$scale typed=$typed', (tester) async {
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
                  (l) => l.contains('file:///') || l.contains('overflowed'),
                )
                .join(' | '),
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(
                  c,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const DocumentSearchView(),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          if (typed) {
            await tester.enterText(find.byType(TextField).first, 'CNI Lomé');
            await tester.pump(const Duration(seconds: 1));
          }
          FlutterError.onError = old;
          expect(errors, isEmpty, reason: 'Dépassement : ${errors.join('\n')}');
        });
      }
    }
  }
}
