import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../widgets/app_back_button.dart';

/// Affiche une notification en entier : titre, date et texte complet.
///
/// Utilisée pour les notifications d'information (messages envoyés depuis
/// l'admin web, bienvenue, rappels…) qui ne mènent ni à une correspondance,
/// ni à une conversation.
class NotificationDetailView extends StatelessWidget {
  const NotificationDetailView({
    super.key,
    required this.title,
    required this.body,
    this.type,
    this.createdAt,
  });

  final String title;
  final String body;
  final String? type;
  final String? createdAt;

  /// Types qui ouvrent un autre écran (correspondances, messagerie,
  /// restitution). Tous les autres s'affichent avec cette page.
  static const _actionTypes = {
    'MATCH_TROUVE',
    'MATCH_ACCEPTE',
    'MATCH_REJETE',
    'NOUVEAU_MESSAGE',
    'CONVERSATION_RESOLUE',
    'REMERCIEMENT_TROUVEUR',
    'EVALUATION_RECUE',
  };

  /// `true` quand la notification doit s'ouvrir en entier ici.
  static bool isInformational(String? type) =>
      !_actionTypes.contains(type ?? '');

  static Future<void> open(BuildContext context, Map<String, dynamic> n) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationDetailView(
          title: (n['titre'] ?? n['title']) as String? ?? '',
          body: (n['corps'] ?? n['description']) as String? ?? '',
          type: n['type'] as String?,
          createdAt: n['createdAt'] as String?,
        ),
      ),
    );
  }

  String get _sourceLabel => switch (type) {
    'BIENVENUE' => 'Bienvenue',
    'RAPPEL_DECLARATION' => 'Rappel',
    _ => 'Message de l\'équipe Finds',
  };

  String? get _fullDate {
    final d = createdAt == null ? null : DateTime.tryParse(createdAt!);
    if (d == null) return null;
    final l = d.toLocal();
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '${l.day} ${months[l.month - 1]} ${l.year} à ${hh}h$mm';
  }

  @override
  Widget build(BuildContext context) {
    final date = _fullDate;
    final ago = relativeTime(createdAt);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Notification',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _sourceLabel,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (ago.isNotEmpty)
                                  Text(
                                    ago,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSubtle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SelectableText(
                        title.isEmpty ? 'Notification' : title,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textStrong,
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Reçue le $date',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 14),
                      SelectableText(
                        body.isEmpty ? 'Aucun contenu.' : body,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
