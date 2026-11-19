import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Carte d'illustration pour l'écran d'Onboarding
class OnboardingIllustration extends StatelessWidget {
  final int slideIndex;
  final String? assetPath;

  const OnboardingIllustration({
    super.key,
    required this.slideIndex,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 290,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F4),
        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusXxl),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arrière-plan graphique décoratif
            _buildBackgroundGradients(),

            // Contenu de l'illustration selon le slide
            if (slideIndex == 0) _buildSlide1Content(),
            if (slideIndex == 1) _buildSlide2Content(),
            if (slideIndex == 2) _buildSlide3Content(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGradients() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SLIDE 1 : Personne retrouvant son document
  Widget _buildSlide1Content() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Silhouette stylisée
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: AppSizes.iconXxl,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            // Carte d'identité stylisée avec check vert
            Container(
              width: 190,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd,
                vertical: AppSizes.spaceSm,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                border: Border.all(color: AppColors.borderLight, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      color: AppColors.primary,
                      size: AppSizes.iconL,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceXxsm),
                        Container(
                          width: 85,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: AppSizes.iconXsm,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Badge flottant en bas à droite : "Document retrouvé"
        Positioned(
          bottom: AppSizes.spaceMd,
          right: AppSizes.spaceMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceMd,
              vertical: AppSizes.spaceXsm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSizes.spaceXsm,
                  height: AppSizes.spaceXsm,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.spaceXxsm + 2),
                const Text(
                  'Document retrouvé',
                  style: TextStyle(
                    fontSize: AppSizes.fontXsm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // SLIDE 2 : Matching intelligent IA (98%)
  Widget _buildSlide2Content() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Carte Perte (Gauche)
            _buildMiniDocCard(
              title: 'PERTE',
              code: 'CNI-TG-2024',
              color: AppColors.primary,
              icon: Icons.search_rounded,
            ),

            // Bouclier Score au centre
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXsm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceSm,
                vertical: AppSizes.spaceSm,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: AppSizes.iconMd,
                  ),
                  SizedBox(height: AppSizes.spaceXxsm),
                  Text(
                    '98%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'SCORE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: AppSizes.fontXxsm - 2,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Carte Trouvaille (Droite)
            _buildMiniDocCard(
              title: 'TROUVÉ',
              code: 'CNI-TG-2024',
              color: const Color(0xFF10B981),
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniDocCard({
    required String title,
    required String code,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(AppSizes.spaceSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: AppSizes.fontXxsm,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, size: AppSizes.iconXxsm, color: color),
            ],
          ),
          const SizedBox(height: AppSizes.spaceXsm),
          Container(
            height: 4,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSizes.spaceXxsm),
          Container(
            height: 4,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSizes.spaceXxsm + 2),
          Text(
            code,
            style: const TextStyle(
              fontSize: AppSizes.fontXxsm,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // SLIDE 3 : Échange sécurisé & restitution
  Widget _buildSlide3Content() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouclier vert lumineux
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.shield_rounded,
                  size: AppSizes.iconXl,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            // Illustration de deux acteurs échangeant
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActorAvatar(Icons.person, 'Trouveur'),
                const SizedBox(width: AppSizes.spaceXsm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceSm,
                    vertical: AppSizes.spaceXxsm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white,
                        size: AppSizes.iconSm,
                      ),
                      SizedBox(width: AppSizes.spaceXxsm),
                      Icon(
                        Icons.credit_card_rounded,
                        color: Colors.white,
                        size: AppSizes.iconSm,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.spaceXsm),
                _buildActorAvatar(Icons.person_pin, 'Propriétaire'),
              ],
            ),
          ],
        ),

        // Badge flottant en bas : 🛡️ Échange vérifié & sécurisé
        Positioned(
          bottom: AppSizes.spaceMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceMd,
              vertical: AppSizes.spaceXsm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: AppSizes.iconXsm,
                  color: AppColors.primary,
                ),
                SizedBox(width: AppSizes.spaceXxsm + 2),
                Text(
                  'Échange vérifié & sécurisé',
                  style: TextStyle(
                    fontSize: AppSizes.fontXsm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActorAvatar(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: AppSizes.iconDefault,
          ),
        ),
        const SizedBox(height: AppSizes.spaceXxsm),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.fontXxsm,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
