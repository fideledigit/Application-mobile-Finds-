import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Indicateur de pagination avec pilule animée pour l'Onboarding
class PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final ValueChanged<int>? onDotTap;

  const PageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool isActive = index == currentIndex;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDotTap != null ? () => onDotTap!(index) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceXxsm,
              vertical: AppSizes.spaceXsm,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: AppSizes.spaceXsm,
              width: isActive ? AppSizes.spaceXl : AppSizes.spaceXsm,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(AppSizes.radiusXxsm),
              ),
            ),
          ),
        );
      }),
    );
  }
}
