import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';
import 'lost_document_step1_view.dart';
import 'found_document_step1_view.dart';

/// Écran de sélection : Déclarer un document perdu VS document trouvé
/// Conforme à la maquette findmydoc_nouvelle_d_claration_choix_du_type
class DeclarationTypeChoiceView extends StatelessWidget {
  final VoidCallback? onLostDocumentTap;
  final VoidCallback? onFoundDocumentTap;

  const DeclarationTypeChoiceView({
    super.key,
    this.onLostDocumentTap,
    this.onFoundDocumentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceL,
            vertical: AppSizes.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header supérieur
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AppBackButton(),
                      const SizedBox(width: AppSizes.spaceSm),
                      const Text(
                        'Nouvelle déclaration',
                        style: TextStyle(
                          fontSize: AppSizes.fontL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: AppSizes.iconXl,
                    height: AppSizes.iconXl,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: AppSizes.iconMd,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spaceXl),

              // 2. Badge "Démarche citoyenne certifiée"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceSm,
                  vertical: AppSizes.spaceXxsm + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: AppSizes.iconSm,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: AppSizes.spaceXxsm + 2),
                    Text(
                      'DÉMARCHE CITOYENNE CERTIFIÉE',
                      style: TextStyle(
                        fontSize: AppSizes.fontXxsm,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.spaceMd - 2),

              // 3. Titre & Description
              const Text(
                'Que souhaitez-vous déclarer ?',
                style: TextStyle(
                  fontSize: AppSizes.fontXl,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: AppSizes.spaceXsm),

              const Text(
                'Sélectionnez l\'option correspondant à votre situation pour démarrer la démarche sécurisée Finds.',
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: AppColors.textSubtle,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: AppSizes.spaceXxl),

              // 4. Carte 1 : Document perdu
              _buildChoiceCard(
                title: 'Document perdu',
                description:
                    'J’ai perdu un document personnel ou officiel et je souhaite le signaler à la communauté.',
                icon: Icons.find_in_page_rounded,
                iconColor: AppColors.primary,
                iconBg: AppColors.primarySoft,
                badges: const [
                  {
                    'icon': Icons.notifications_active_rounded,
                    'text': 'Alerte instantanée',
                    'color': AppColors.primary,
                  },
                  {
                    'icon': Icons.visibility_off_rounded,
                    'text': 'Données masquées',
                    'color': AppColors.textSubtle,
                  },
                ],
                onTap:
                    onLostDocumentTap ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LostDocumentStep1View(),
                        ),
                      );
                    },
              ),

              const SizedBox(height: AppSizes.spaceL),

              // 5. Carte 2 : Document trouvé
              _buildChoiceCard(
                title: 'Document trouvé',
                description:
                    'J’ai trouvé un document égaré et je souhaite aider son propriétaire légitime à le restituer.',
                icon: Icons.volunteer_activism_rounded,
                iconColor: AppColors.successDark,
                iconBg: AppColors.primarySoft,
                badges: const [
                  {
                    'icon': Icons.handshake_rounded,
                    'text': 'Remise sécurisée',
                    'color': AppColors.successDark,
                  },
                  {
                    'icon': Icons.favorite_rounded,
                    'text': 'Action citoyenne',
                    'color': AppColors.textSubtle,
                  },
                ],
                onTap:
                    onFoundDocumentTap ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FoundDocumentStep1View(),
                        ),
                      );
                    },
              ),

              const SizedBox(height: AppSizes.spaceXxl),

              // Bandeau d'aide
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.spaceMd),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: AppSizes.iconMd,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: AppSizes.spaceSm),
                    Expanded(
                      child: Text(
                        'Vos informations sensibles ne sont jamais rendues publiques avant la confirmation mutuelle.',
                        style: TextStyle(
                          fontSize: AppSizes.fontXsm,
                          color: AppColors.textSubtle,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<Map<String, dynamic>> badges,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spaceL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône stylisée
            Container(
              width: AppSizes.buttonHeightL,
              height: AppSizes.buttonHeightL,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.iconL),
            ),
            const SizedBox(width: AppSizes.spaceMd),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppSizes.fontL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                      ),
                      Container(
                        width: AppSizes.spaceXxl,
                        height: AppSizes.spaceXxl,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: AppSizes.iconSm,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceXxsm + 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSm,
                      color: AppColors.textSubtle,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceSm),
                  // Badges
                  Wrap(
                    spacing: AppSizes.spaceSm - 2,
                    runSpacing: AppSizes.spaceXxsm + 2,
                    children: badges.map((b) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            b['icon'] as IconData,
                            size: AppSizes.iconXsm,
                            color: b['color'] as Color,
                          ),
                          const SizedBox(width: AppSizes.spaceXxsm),
                          Text(
                            b['text'] as String,
                            style: TextStyle(
                              fontSize: AppSizes.fontXxsm + 1,
                              fontWeight: FontWeight.w600,
                              color: b['color'] as Color,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
