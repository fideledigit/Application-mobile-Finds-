import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';

/// Page « À propos de Finds » : mission, fonctionnement et engagements.
class AboutView extends StatelessWidget {
  const AboutView({super.key});

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

                    _buildSectionHeader('NOTRE MISSION'),
                    _buildCard(
                      child: const Text(
                        'Finds est née d’un constat simple : chaque année, '
                        'des milliers de pièces officielles sont perdues au Togo, tandis '
                        'que beaucoup d’autres sont retrouvées sans jamais revenir à '
                        'leurs propriétaires. Notre mission est de relier ces deux '
                        'parcours en un seul geste citoyen, en toute sécurité.',
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          height: 1.55,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceMd),

                    _buildSectionHeader('COMMENT ÇA MARCHE'),
                    _buildCard(
                      child: Column(
                        children: [
                          _buildStepRow(
                            step: '1',
                            title: 'Déclarez',
                            text:
                                'Perdu ou trouvé, en 3 étapes rapides depuis votre téléphone.',
                          ),
                          _buildStepDivider(),
                          _buildStepRow(
                            step: '2',
                            title: 'Nous mettons en relation',
                            text:
                                'L’algorithme détecte les concordances dans votre rayon de recherche.',
                          ),
                          _buildStepDivider(),
                          _buildStepRow(
                            step: '3',
                            title: 'Restituez',
                            text:
                                'Échangez par la messagerie Finds et restituez la pièce en confiance.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceMd),

                    _buildSectionHeader('NOS ENGAGEMENTS'),
                    _buildCard(
                      child: Column(
                        children: [
                          _buildCommitmentRow('Connexion sécurisée (HTTPS)'),
                          _buildCommitmentRow(
                            'Numéros de document partiellement masqués',
                          ),
                          _buildCommitmentRow(
                            'Service civique 100 % gratuit, sans publicité',
                          ),
                          _buildCommitmentRow(
                            'Faux signalements passibles des sanctions prévues par la loi',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceL),

                    // Footer
                    const Center(
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
                              Flexible(
                                child: Text(
                                  'Finds v1.2.0 • Plateforme civique',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: AppSizes.fontXxsm + 1,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.spaceXxsm),
                          Text(
                            'Connexion sécurisée (HTTPS) • Numéros de document masqués',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppSizes.fontXxsm,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
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
            'À propos de Finds',
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

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF4EC), Color(0xFFF8FBF9)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: const Color(0xFFE3EDE6)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.primary,
              size: AppSizes.iconXl,
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          const Text(
            'Finds',
            style: TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSizes.spaceXxsm),
          const Text(
            'La plateforme civique de restitution de documents',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeroBadge('v1.2.0', Icons.verified_rounded),
              const SizedBox(width: AppSizes.spaceXsm),
              _buildHeroBadge('Togo & UEMOA', Icons.public_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceSm,
        vertical: AppSizes.spaceXxsm + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconXxsm, color: AppColors.primary),
          const SizedBox(width: AppSizes.spaceXxsm),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.fontXxsm + 0.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.spaceXxsm,
        bottom: AppSizes.spaceXsm,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppSizes.fontXxsm + 1,
          fontWeight: FontWeight.bold,
          color: AppColors.textSubtle,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
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
      child: child,
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.spaceXl + 2,
          height: AppSizes.spaceXl + 2,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              fontSize: AppSizes.fontXsm,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: AppSizes.fontXsm,
                  height: 1.4,
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return const Padding(
      padding: EdgeInsets.only(
        left: 38,
        top: AppSizes.spaceSm - 2,
        bottom: AppSizes.spaceSm - 2,
      ),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }

  Widget _buildCommitmentRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceXxsm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: AppSizes.iconSm,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppSizes.fontSm,
                height: 1.4,
                color: AppColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
