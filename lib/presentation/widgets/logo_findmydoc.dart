import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Widget du Logo officiel Finds
/// Adaptable et responsive sur tous les écrans (mobile, tablette, grand texte).
class LogoFinds extends StatelessWidget {
  /// Taille de l'icône logo (largeur & hauteur)
  final double size;

  /// Affiche ou masque le texte "Finds" à côté de l'icône
  final bool showText;

  /// Taille personnalisée de la typographie (optionnelle)
  final double? fontSize;

  /// Affiche le logo sous forme de pilule d'en-tête (utilisée sur les écrans d'authentification)
  final bool asPill;

  /// Espacement horizontal entre l'icône et le texte
  final double? spacing;

  const LogoFinds({
    super.key,
    this.size = AppSizes.iconL,
    this.showText = true,
    this.fontSize,
    this.asPill = false,
    this.spacing,
  });

  /// Constructeur pratique pour les en-têtes avec style "pilule"
  const LogoFinds.pill({
    super.key,
    this.size = 24.0,
    this.showText = true,
    this.fontSize = 15.0,
    this.spacing = 8.0,
  }) : asPill = true;

  @override
  Widget build(BuildContext context) {
    // Calcul proportionnel de la taille de police si non spécifiée
    final calculatedFontSize = fontSize ?? (size * 0.56).clamp(13.0, 26.0);

    // Widget de l'icône officielle
    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            // Fallback élégant en cas de chargement différé
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(size * 0.22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: size * 0.65,
                ),
              ),
            );
          },
        ),
      ),
    );

    // Contenu Logo + Texte
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        if (showText) ...[
          SizedBox(width: spacing ?? (size * 0.28).clamp(6.0, 12.0)),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: calculatedFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                    fontFamily: 'Roboto',
                  ),
                  children: const [
                    TextSpan(
                      text: 'Find',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: 's',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (asPill) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceMd - 2,
          vertical: AppSizes.spaceXsm - 1,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}
