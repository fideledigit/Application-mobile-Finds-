import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';

/// Une section de la Politique de Confidentialité.
class _PolicySection {
  final String title;
  final String body;

  const _PolicySection(this.title, this.body);
}

/// Page « Politique de Confidentialité » : liste compacte des sections.
/// Chaque section s'ouvre dans sa propre page (PrivacySectionView).
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  static const String _version = '1.2.0';
  static const String _updatedAt = '22 octobre 2026';

  static const List<_PolicySection> _sections = [
    _PolicySection(
      'Données collectées',
      'Nous collectons uniquement les informations nécessaires au service : '
          'identité du propriétaire (nom, prénom(s), date et lieu de naissance), '
          'caractéristiques du document (type, numéro), photo optionnelle, '
          'position déclarée, e-mail, téléphone et messages échangés.',
    ),
    _PolicySection(
      'Utilisation des données',
      'Vos données servent exclusivement au fonctionnement du service : '
          'calcul des correspondances, alertes de correspondance, messagerie interne '
          'et statistiques anonymes d’amélioration.',
    ),
    _PolicySection(
      'Partage et visibilité',
      'Vos données ne sont jamais vendues à des tiers. Les déclarations '
          'publiées apparaissent dans la recherche avec le numéro de document '
          'partiellement masqué. La messagerie ne s’ouvre qu’après confirmation '
          'd’une correspondance par les deux parties.',
    ),
    _PolicySection(
      'Sécurité',
      'Les échanges entre l’application et le serveur passent par une '
          'connexion sécurisée (HTTPS). Votre session est protégée par un '
          'jeton d’accès et votre mot de passe peut être modifié à tout moment '
          'depuis votre profil.',
    ),
    _PolicySection(
      'Conservation des données',
      'Vos déclarations restent actives 90 jours, puis sont automatiquement '
          'purgées. Les informations de compte sont conservées jusqu’à votre '
          'suppression de compte, puis effacées sous 30 jours.',
    ),
    _PolicySection(
      'Vos droits',
      'Conformément au RGPD et à la loi APDP du Togo, vous disposez d’un droit '
          'd’accès, de rectification et de suppression de vos données. '
          'Exercez-les à tout moment via l’onglet Assistance.',
    ),
    _PolicySection(
      'Publicité et traceurs',
      'Finds est gratuit et sans publicité. Aucune donnée n’est revendue et '
          'aucun traceur publicitaire n’est utilisé.',
    ),
    _PolicySection(
      'Contact et réclamations',
      'Pour toute question sur vos données, contactez-nous via l’onglet '
          'Assistance. Vous pouvez également saisir l’autorité de protection '
          'des données (APDP) au Togo.',
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
                    _buildSectionsCard(context),
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
            'Politique de Confidentialité',
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
              Icons.privacy_tip_rounded,
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
                  'Politique de Confidentialité',
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

  Widget _buildSectionsCard(BuildContext context) {
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
          for (var i = 0; i < _sections.length; i++) ...[
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
                _sections[i].title,
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
                MaterialPageRoute(builder: (_) => PrivacySectionView(index: i)),
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
            Icons.lock_rounded,
            size: AppSizes.iconSm,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: Text(
              'Vos données vous appartiennent : Finds ne les vend jamais.',
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
                'Finds v$_version',
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

/// Page dédiée d'une section : affiche le texte complet + navigation
/// vers la section suivante.
class PrivacySectionView extends StatelessWidget {
  final int index;

  const PrivacySectionView({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final section = PrivacyView._sections[index];
    final hasNext = index < PrivacyView._sections.length - 1;
    final next = hasNext ? PrivacyView._sections[index + 1] : null;

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
                    _buildHeader(index, section.title),
                    const SizedBox(height: AppSizes.spaceSm + 2),
                    _buildBodyCard(section.body),
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
            'Section ${index + 1} sur ${PrivacyView._sections.length}',
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
            'SECTION ${index + 1}',
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
            builder: (_) => PrivacySectionView(index: nextIndex),
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
                      'Section suivante',
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
