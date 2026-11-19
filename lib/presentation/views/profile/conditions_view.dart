import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';

/// Un article des Conditions Générales d'Utilisation.
class _Article {
  final String title;
  final String body;

  const _Article(this.title, this.body);
}

/// Page « Conditions Générales d'Utilisation » : liste compacte des articles.
/// Chaque article s'ouvre dans sa propre page (ConditionsArticleView).
class ConditionsView extends StatelessWidget {
  const ConditionsView({super.key});

  static const String _version = '1.2.0';
  static const String _updatedAt = '22 octobre 2026';

  static const List<_Article> _articles = [
    _Article(
      'Objet et acceptation',
      'Finds est une plateforme d’utilité civique destinée à faciliter la '
          'restitution des documents perdus ou trouvés. En utilisant '
          'l’application, vous acceptez les présentes conditions. Tout faux '
          'signalement est passible des sanctions prévues par la législation en vigueur.',
    ),
    _Article(
      'Service et compte',
      'Finds est gratuit, sans publicité et accessible 24 h sur 24, sauf '
          'maintenance. Vous vous engagez à fournir des informations exactes et '
          'à garder vos identifiants confidentiels.',
    ),
    _Article(
      'Vos déclarations',
      'Chaque déclaration doit refléter une situation réelle et vous en '
          'certifiez l’exactitude. Elle reste active 90 jours et peut être '
          'modifiée ou renouvelée depuis votre profil.',
    ),
    _Article(
      'Comportements interdits',
      'Sont interdits : les faux signalements, l’usurpation d’identité, le '
          'harcèlement, les contenus illicites, l’extraction automatisée des '
          'données et tout usage commercial du service.',
    ),
    _Article(
      'Mise en relation',
      'La restitution s’effectue directement entre utilisateurs : Finds '
          'n’intervient jamais physiquement. Vérifiez toujours l’identité du '
          'propriétaire avant de remettre une pièce.',
    ),
    _Article(
      'Données et responsabilité',
      'Vos données transitent par une connexion sécurisée, ne sont jamais '
          'vendues et vos numéros sont partiellement masqués. Le service est '
          'fourni « en l’état » : la récupération d’un document n’est pas garantie.',
    ),
    _Article(
      'Modifications et contact',
      'Les conditions peuvent évoluer (date de mise à jour en tête de page). '
          'Pour toute question, contactez-nous via l’onglet Assistance.',
    ),
    _Article(
      'Droit applicable',
      'Les présentes conditions sont régies par la législation togolaise. Tout '
          'litige fera l’objet d’une résolution amiable avant toute action '
          'devant les juridictions de Lomé.',
    ),
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
                    _buildHeroCard(),
                    const SizedBox(height: AppSizes.spaceMd),
                    _buildArticlesCard(context),
                    const SizedBox(height: AppSizes.spaceMd),
                    _buildAcceptanceNote(),
                    const SizedBox(height: AppSizes.spaceL),
                    _buildFooter(),
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
            'Conditions Générales d’Utilisation',
            style: TextStyle(
              fontSize: AppSizes.fontDefault,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: AppSizes.paddingCard,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF4EC), Color(0xFFF8FBF9)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: const Color(0xFFE3EDE6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.gavel_rounded,
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
                  'Conditions Générales d’Utilisation',
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: AppSizes.spaceXxsm),
                Text(
                  'Version $_version • Mise à jour : $_updatedAt',
                  style: TextStyle(
                    fontSize: AppSizes.fontXxsm + 1,
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < _articles.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 56, color: AppColors.divider),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd - 2,
              ),
              leading: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXsm),
                ),
                child: Text(
                  '${i + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: AppSizes.fontXxsm + 0.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              title: Text(
                _articles[i].title,
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSubtle,
                size: AppSizes.iconMd,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConditionsArticleView(index: i),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAcceptanceNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_rounded,
            size: AppSizes.iconSm,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: Text(
              'En utilisant Finds, vous acceptez l’intégralité des présentes conditions.',
              style: TextStyle(
                fontSize: AppSizes.fontXsm,
                height: 1.45,
                color: AppColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_rounded,
                size: AppSizes.iconXsm,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSizes.spaceXxsm + 2),
              Text(
                'Finds v$_version • Document contractuel',
                style: TextStyle(
                  fontSize: AppSizes.fontXxsm + 1,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.spaceXxsm),
          Text(
            'Dernière mise à jour : 22 octobre 2026',
            style: TextStyle(
              fontSize: AppSizes.fontXxsm,
              color: AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page dédiée d'un article : affiche le texte complet + navigation
/// vers l'article suivant.
class ConditionsArticleView extends StatelessWidget {
  final int index;

  const ConditionsArticleView({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final article = ConditionsView._articles[index];
    final hasNext = index < ConditionsView._articles.length - 1;
    final next = hasNext ? ConditionsView._articles[index + 1] : null;

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
                    _buildHeader(index, article.title),
                    const SizedBox(height: AppSizes.spaceSm + 2),
                    _buildBodyCard(article.body),
                    const SizedBox(height: AppSizes.spaceSm + 2),
                    if (hasNext)
                      _buildNextCard(context, index + 1, next!.title),
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
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: AppSizes.spaceSm),
          Text(
            'Article ${index + 1} sur ${ConditionsView._articles.length}',
            style: const TextStyle(
              fontSize: AppSizes.fontDefault,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int index, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceSm - 3,
            vertical: AppSizes.spaceXxsm + 1,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSizes.radiusXsm),
          ),
          child: Text(
            'ARTICLE ${index + 1}',
            style: const TextStyle(
              fontSize: AppSizes.fontXxsm,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spaceSm),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyCard(String body) {
    return Container(
      width: double.infinity,
      padding: AppSizes.paddingCard,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        body,
        style: const TextStyle(
          fontSize: AppSizes.fontSm,
          height: 1.65,
          color: AppColors.textBody,
        ),
      ),
    );
  }

  Widget _buildNextCard(BuildContext context, int nextIndex, String nextTitle) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConditionsArticleView(index: nextIndex),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceMd - 2,
            vertical: AppSizes.spaceSm + 1,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: const Color(0xFFE3EDE6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Article suivant',
                      style: TextStyle(
                        fontSize: AppSizes.fontXxsm + 0.5,
                        color: AppColors.textSubtle,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nextTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: AppSizes.iconSm,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
