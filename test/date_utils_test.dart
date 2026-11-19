import 'package:flutter_test/flutter_test.dart';
import 'package:finds/core/utils/date_utils.dart';

void main() {
  final now = DateTime.utc(2026, 11, 9, 12);
  String ago(Duration d) =>
      relativeTime(now.subtract(d).toIso8601String(), now: now);

  test('paliers lisibles', () {
    expect(ago(const Duration(seconds: 20)), 'À l\'instant');
    expect(ago(const Duration(minutes: 5)), 'Il y a 5 min');
    expect(ago(const Duration(hours: 3)), 'Il y a 3 h');
    expect(ago(const Duration(days: 1)), 'Hier');
    expect(ago(const Duration(days: 5)), 'Il y a 5 jours');
    expect(ago(const Duration(days: 7)), 'Il y a 1 semaine');
    expect(ago(const Duration(days: 29)), 'Il y a 4 semaines');
    expect(ago(const Duration(days: 31)), 'Il y a 1 mois');
    expect(ago(const Duration(days: 32)), 'Il y a 1 mois');
    expect(ago(const Duration(days: 214)), 'Il y a 7 mois');
    expect(ago(const Duration(days: 364)), 'Il y a 11 mois');
    expect(ago(const Duration(days: 365)), 'Il y a 1 an');
    expect(ago(const Duration(days: 800)), 'Il y a 2 ans');
  });

  test('date absente ou invalide', () {
    expect(relativeTime(null), '');
    expect(relativeTime('pas une date'), '');
  });
}
