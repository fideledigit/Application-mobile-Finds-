import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Un critère du score de correspondance calculé par le serveur.
/// Barèmes (schéma GraphQL `Match`) : nom /40, type /30, numéro /20, ville /10.
class MatchCriterion {
  const MatchCriterion(this.label, this.icon, this.value, this.max);

  final String label;
  final IconData icon;
  final double? value;
  final double max;

  /// Proportion obtenue (0–1), `null` si le serveur n'a rien renvoyé.
  double? get ratio => value == null ? null : (value! / max).clamp(0.0, 1.0);

  static List<MatchCriterion> fromMatch(Map<String, dynamic> m) {
    double? n(String k) => (m[k] as num?)?.toDouble();
    return [
      MatchCriterion('Nom', Icons.person_rounded, n('scoreNom'), 40),
      MatchCriterion('Type', Icons.badge_rounded, n('scoreType'), 30),
      MatchCriterion('Numéro', Icons.pin_rounded, n('scoreNumero'), 20),
      MatchCriterion('Ville', Icons.location_on_rounded, n('scoreVille'), 10),
    ];
  }

  static bool hasAny(Map<String, dynamic> m) =>
      fromMatch(m).any((c) => c.value != null);
}

enum _Level { full, partial, none, unknown }

_Level _levelOf(double? ratio) {
  if (ratio == null) return _Level.unknown;
  if (ratio >= 0.8) return _Level.full;
  if (ratio >= 0.35) return _Level.partial;
  return _Level.none;
}

(Color, Color, IconData, String) _style(_Level l) => switch (l) {
  _Level.full => (
    AppColors.successDeep,
    AppColors.primarySoft,
    Icons.check_circle_rounded,
    'Identique',
  ),
  _Level.partial => (
    const Color(0xFF8A5A00),
    const Color(0xFFFFF1D6),
    Icons.change_circle_rounded,
    'Proche',
  ),
  _Level.none => (
    AppColors.errorDark,
    AppColors.errorSoft,
    Icons.cancel_rounded,
    'Différent',
  ),
  _Level.unknown => (
    AppColors.textSubtle,
    AppColors.chipBackground,
    Icons.help_rounded,
    'Non évalué',
  ),
};

/// Détail du score : une ligne par critère avec une barre de progression.
class MatchScoreBreakdown extends StatelessWidget {
  const MatchScoreBreakdown({super.key, required this.match});

  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final criteria = MatchCriterion.fromMatch(match);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POURQUOI CETTE CORRESPONDANCE ?',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textSubtle,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          for (final c in criteria) _row(c),
        ],
      ),
    );
  }

  Widget _row(MatchCriterion c) {
    final (fg, bg, icon, word) = _style(_levelOf(c.ratio));
    final value = c.value == null
        ? '–'
        : '${c.value!.round()}/${c.max.round()}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: c.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  $word',
                        style: TextStyle(color: fg),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.ratio ?? 0,
              minHeight: 6,
              backgroundColor: bg,
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Version compacte pour les cartes : « ✓ Nom  ✓ Type  ✗ Numéro  ✓ Ville ».
class MatchScoreChips extends StatelessWidget {
  const MatchScoreChips({super.key, required this.match});

  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final c in MatchCriterion.fromMatch(match))
          Builder(
            builder: (_) {
              final (fg, bg, icon, word) = _style(_levelOf(c.ratio));
              return Semantics(
                label: '${c.label} : $word',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 13, color: fg),
                      const SizedBox(width: 4),
                      Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
