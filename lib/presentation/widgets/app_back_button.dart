import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Bouton retour circulaire moderne et soigné (fidèle à la maquette Figma)
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = AppSizes.buttonHeightSm,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            onPressed ??
            () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFF1F5F3),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              size: AppSizes.iconMd,
              color: iconColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
