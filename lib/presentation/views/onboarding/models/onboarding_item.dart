/// Modèle de données pour une slide d'onboarding
class OnboardingItem {
  final String titlePart1;
  final String titleHighlight;
  final String description;
  final String badgeText;
  final String? assetPath;
  final int slideIndex;

  const OnboardingItem({
    required this.titlePart1,
    required this.titleHighlight,
    required this.description,
    required this.badgeText,
    this.assetPath,
    required this.slideIndex,
  });
}
