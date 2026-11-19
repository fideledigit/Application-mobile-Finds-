import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/logo_findmydoc.dart';
import '../auth/login_view.dart';
import '../auth/register_view.dart';
import 'models/onboarding_item.dart';
import 'widgets/onboarding_illustration.dart';
import 'widgets/page_indicator.dart';

/// Écran d'Onboarding / Splash (3 slides interactives)
class OnboardingView extends StatefulWidget {
  final VoidCallback? onStart;
  final VoidCallback? onLogin;

  const OnboardingView({super.key, this.onStart, this.onLogin});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _slides = const [
    OnboardingItem(
      slideIndex: 0,
      titlePart1: AppStrings.slide1TitlePart1,
      titleHighlight: AppStrings.slide1TitleHighlight,
      description: AppStrings.slide1Description,
      badgeText: AppStrings.slide1Badge,
    ),
    OnboardingItem(
      slideIndex: 1,
      titlePart1: AppStrings.slide2TitlePart1,
      titleHighlight: AppStrings.slide2TitleHighlight,
      description: AppStrings.slide2Description,
      badgeText: AppStrings.slide2Badge,
    ),
    OnboardingItem(
      slideIndex: 2,
      titlePart1: AppStrings.slide3TitlePart1,
      titleHighlight: AppStrings.slide3TitleHighlight,
      description: AppStrings.slide3Description,
      badgeText: AppStrings.slide3Badge,
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goToNextPage() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _animateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _skipToLast() {
    _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastSlide = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Barre supérieure : Logo Finds + Bouton "Passer"
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LogoFinds(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isLastSlide ? 0.0 : 1.0,
                    child: TextButton(
                      onPressed: isLastSlide ? null : _skipToLast,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        splashFactory: NoSplash.splashFactory,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        AppStrings.skip,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Zone défilante des 3 slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    // Centré si la place suffit, défilable sur les petits écrans.
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: AppSizes.spaceL),

                                // Carte d'illustration
                                OnboardingIllustration(
                                  slideIndex: slide.slideIndex,
                                  assetPath: slide.assetPath,
                                ),

                                const SizedBox(height: 32),

                                // Titre avec mot accentué en vert
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: AppSizes.fontXxl,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      height: 1.25,
                                      fontFamily: 'Roboto',
                                    ),
                                    children: [
                                      TextSpan(text: slide.titlePart1),
                                      TextSpan(
                                        text: slide.titleHighlight,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: AppSizes.spaceMd - 2),

                                // Sous-titre / description
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.spaceSm,
                                  ),
                                  child: Text(
                                    slide.description,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: AppSizes.fontMd,
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: AppSizes.spaceL),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // 3. Indicateur de progression (3 points)
            PageIndicator(
              count: _slides.length,
              currentIndex: _currentIndex,
              onDotTap: _animateToPage,
            ),

            const SizedBox(height: AppSizes.spaceXl),

            // 4. Boutons d'action en bas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXl),
              child: isLastSlide
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton principal : "Commencer"
                        ElevatedButton(
                          onPressed:
                              widget.onStart ??
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterView(),
                                  ),
                                );
                              },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            minimumSize: const Size.fromHeight(
                              AppSizes.buttonHeightDefault,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            AppStrings.start,
                            style: TextStyle(
                              fontSize: AppSizes.fontDefault,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSizes.spaceSm),

                        // Bouton secondaire : "J'ai déjà un compte"
                        OutlinedButton(
                          onPressed:
                              widget.onLogin ??
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginView(),
                                  ),
                                );
                              },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1.2,
                            ),
                            shape: const StadiumBorder(),
                            minimumSize: const Size.fromHeight(
                              AppSizes.buttonHeightDefault,
                            ),
                          ),
                          child: const Text(
                            AppStrings.alreadyHaveAccount,
                            style: TextStyle(
                              fontSize: AppSizes.fontMd,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _goToNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(
                          AppSizes.buttonHeightDefault,
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.next,
                            style: TextStyle(
                              fontSize: AppSizes.fontDefault,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: AppSizes.spaceXsm),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: AppSizes.iconSm,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: AppSizes.spaceL),
          ],
        ),
      ),
    );
  }
}
