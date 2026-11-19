import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';

/// Une catégorie de la FAQ (titre, icône et liste de questions/réponses).
class _FaqSection {
  final String title;
  final IconData icon;
  final List<List<String>> items;

  const _FaqSection(this.title, this.icon, this.items);
}

/// Page « FAQ » : questions fréquentes groupées par catégorie,
/// sous forme d’accordéons (inspirée de la page FAQ Finds).
class FaqView extends StatelessWidget {
  const FaqView({super.key});

  static const List<_FaqSection> _sections = [
    _FaqSection('Général', Icons.info_rounded, [
      [
        'Qu’est-ce que Finds ?',
        'Finds est une plateforme citoyenne gratuite qui aide les '
            'personnes ayant perdu un document d’identité à le retrouver. Elle met '
            'en relation les déclarants de perte avec ceux qui ont trouvé des documents.',
      ],
      [
        'Finds est-il gratuit ?',
        'Oui, Finds est 100 % gratuit pour les citoyens. La plateforme est '
            'financée par des partenaires B2B et les dons de la communauté.',
      ],
    ]),
    _FaqSection('Déclarations', Icons.description_rounded, [
      [
        'Comment déclarer un document perdu ?',
        'Rendez-vous dans l’onglet Déclarations, choisissez « Document perdu », '
            'puis remplissez le formulaire en 3 étapes : identification du '
            'document, informations du propriétaire et vérification avant publication.',
      ],
      [
        'J’ai trouvé un document, que faire ?',
        'C’est formidable ! Rendez-vous dans « Déclarer » et choisissez '
            '« Document trouvé ». Renseignez les informations visibles sur le '
            'document. Notre algorithme se chargera de trouver le propriétaire.',
      ],
      [
        'Combien de temps ma déclaration reste-t-elle active ?',
        'Les déclarations restent actives pendant 90 jours. Passé ce délai, elles '
            'expirent automatiquement. Vous pouvez les renouveler depuis votre profil.',
      ],
      [
        'Puis-je modifier ma déclaration après soumission ?',
        'Oui, vous pouvez modifier votre déclaration à tout moment depuis votre '
            'profil, tant qu’elle est encore active. Sur la fiche de vérification, '
            'le bouton « Modifier les informations » vous ramène à l’étape concernée.',
      ],
    ]),
    _FaqSection('Correspondances', Icons.handshake_rounded, [
      [
        'Comment fonctionne la recherche de correspondances ?',
        'Notre algorithme compare automatiquement les déclarations de perte avec '
            'celles de trouvaille en se basant sur plusieurs critères : type de '
            'document, nom du propriétaire, numéro du document et ville.',
      ],
      [
        'Qu’est-ce que le score de concordance ?',
        'Le score de concordance (en pourcentage) indique la probabilité que deux '
            'déclarations correspondent au même document. Plus le score est élevé, '
            'plus la correspondance est probable.',
      ],
      [
        'Que faire quand je reçois une correspondance ?',
        'Vous recevrez une notification. Vérifiez les détails de la correspondance, et si '
            'c’est bien votre document, confirmez la correspondance pour ouvrir une '
            'conversation avec la personne qui l’a trouvé.',
      ],
      [
        'Comment contacter l’autre déclarant ?',
        'Une fois la concordance confirmée, vous échangez via la messagerie '
            'interne de Finds. L’un de vous peut ensuite proposer '
            'WhatsApp ou un appel : votre numéro reste masqué tant que vous ne '
            'l’autorisez pas.',
      ],
    ]),
    _FaqSection('Sécurité', Icons.shield_rounded, [
      [
        'Mes données personnelles sont-elles protégées ?',
        'Nous ne vendons jamais vos informations personnelles. Les échanges avec '
            'le serveur passent par une connexion sécurisée (HTTPS), les numéros de '
            'documents sont partiellement masqués dans l’application et votre '
            'numéro de téléphone n’apparaît pas dans la messagerie.',
      ],
      [
        'Comment vérifier l’identité du propriétaire ?',
        'Lors de la restitution, le propriétaire doit prouver son identité. Nous '
            'recommandons de demander une pièce d’identité complémentaire et de '
            'vérifier les informations du document.',
      ],
      [
        'Que faire en cas de fraude ?',
        'Si vous suspectez une fraude, signalez-la depuis le profil ou la '
            'conversation (bouton « Signaler ») : notre équipe de modération '
            'traitera votre signalement sous 24 h. Vous pouvez aussi contacter le '
            'support depuis l’onglet Assistance.',
      ],
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSizes.paddingPage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: AppSizes.spaceL),
                    for (final section in _sections) ...[
                      _buildSectionHeader(section),
                      ...section.items.map(
                        (item) => _buildFaqItem(item[0], item[1]),
                      ),
                      const SizedBox(height: AppSizes.spaceSm + 2),
                    ],
                    _buildSupportCard(context),
                    const SizedBox(height: AppSizes.spaceXl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceMd,
        vertical: AppSizes.spaceSm - 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: const Row(
        children: [
          AppBackButton(),
          SizedBox(width: AppSizes.spaceSm),
          Text(
            'FAQ',
            style: TextStyle(
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  /// En-tête centré façon « Questions fréquentes ».
  Widget _buildHero() {
    return Center(
      child: Column(
        children: [
          Container(
            width: AppSizes.buttonHeightL,
            height: AppSizes.buttonHeightL,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            ),
            child: const Icon(
              Icons.quiz_rounded,
              color: AppColors.primary,
              size: AppSizes.iconL,
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          const Text(
            'Questions fréquentes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSizes.spaceXxsm),
          const Text(
            'Tout ce que vous devez savoir sur Finds',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(_FaqSection section) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: AppSizes.spaceSm - 2),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm - 3),
            ),
            child: Icon(
              section.icon,
              color: AppColors.primary,
              size: AppSizes.iconSm - 1,
            ),
          ),
          const SizedBox(width: AppSizes.spaceSm - 3),
          Text(
            section.title,
            style: const TextStyle(
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceSm - 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceMd - 2,
            vertical: AppSizes.spaceXxsm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSizes.spaceMd - 2,
            0,
            AppSizes.spaceMd - 2,
            AppSizes.spaceMd - 2,
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSubtle,
          title: Text(
            question,
            style: const TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
              height: 1.35,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  height: 1.5,
                  color: AppColors.textBody,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSizes.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              Icons.contact_support_rounded,
              color: AppColors.primary,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(width: AppSizes.spaceSm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Une autre question ?',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Notre équipe vous répond depuis l’onglet Assistance.',
                  style: TextStyle(
                    fontSize: AppSizes.fontXsm,
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showSupportDialog(context),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd - 2,
                vertical: AppSizes.spaceXsm,
              ),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Contacter',
              style: TextStyle(
                fontSize: AppSizes.fontXsm,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: const Text(
          'Contacter le support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontL,
          ),
        ),
        content: const Text(
          'Ouvrez l’onglet Assistance pour joindre notre équipe via la '
          'messagerie interne Finds.',
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            height: 1.45,
            color: AppColors.textBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Fermer',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
