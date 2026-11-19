import 'package:flutter/material.dart';

/// Système unifié et centralisé des tailles de l'application Finds.
///
/// Échelle standardisée demandée :
/// - [xxsm] : Très très petit (micro-badges, mentions légales, pastilles)
/// - [xsm]  : Très petit (sous-titres fins, timestamps, labels secondaires)
/// - [sm]   : Petit (textes d'aide, placeholders, chips)
/// - [md]   : Moyen (corps de texte standard, items de liste)
/// - [defaultSize] : Taille par défaut de référence (16px)
/// - [l]    : Grand (titres de cartes, boutons principaux, sous-sections)
/// - [xl]   : Très grand (titres d'écrans, en-têtes)
/// - [xxl]  : Très très grand (grands titres d'onboarding, héros)
class AppSizes {
  AppSizes._();

  // ===========================================================================
  // 1. FACTEUR DE MISE À L'ÉCHELLE DYNAMIQUE (Accessibilité / Confort visuel)
  // ===========================================================================
  /// Facteur de multiplicateur de police par défaut fixé à 1.15 (Grand (l)) :
  static final ValueNotifier<double> fontScaleNotifier = ValueNotifier<double>(
    1.15,
  );

  static double get fontScale => fontScaleNotifier.value;
  static set fontScale(double scale) => fontScaleNotifier.value = scale;

  // ===========================================================================
  // 2. TAILLES DE POLICES (TYPOGRAPHY SCALE)
  // ===========================================================================
  // Valeurs de base fixes
  static const double fontXxsm = 11.0;
  static const double fontXsm = 12.0;
  static const double fontSm = 13.5;
  static const double fontMd = 15.0;
  static const double fontDefault = 16.0;
  static const double fontL = 18.0;
  static const double fontXl = 22.0;
  static const double fontXxl = 26.0;

  // Valeurs scalables dynamiquement selon les réglages utilisateur
  static double get textXxsm => fontXxsm * fontScale;
  static double get textXsm => fontXsm * fontScale;
  static double get textSm => fontSm * fontScale;
  static double get textMd => fontMd * fontScale;
  static double get textDefault => fontDefault * fontScale;
  static double get textL => fontL * fontScale;
  static double get textXl => fontXl * fontScale;
  static double get textXxl => fontXxl * fontScale;

  // ===========================================================================
  // 3. ESPACEMENTS & PADDINGS (SPACING SCALE)
  // ===========================================================================
  static const double spaceXxsm = 4.0;
  static const double spaceXsm = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 16.0;
  static const double spaceDefault = 16.0;
  static const double spaceL = 20.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  // EdgeInsets raccourcis pratiques
  static const EdgeInsets paddingPage = EdgeInsets.symmetric(
    horizontal: spaceMd,
    vertical: spaceSm,
  );
  static const EdgeInsets paddingCard = EdgeInsets.all(spaceMd);
  static const EdgeInsets paddingInput = EdgeInsets.symmetric(
    horizontal: spaceMd,
    vertical: 14.0,
  );

  // ===========================================================================
  // 4. TAILLES D'ICÔNES (ICON SIZE SCALE)
  // ===========================================================================
  static const double iconXxsm = 12.0;
  static const double iconXsm = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 20.0;
  static const double iconDefault = 24.0;
  static const double iconL = 28.0;
  static const double iconXl = 36.0;
  static const double iconXxl = 44.0;

  // ===========================================================================
  // 5. RAYONS DE BORDURES (BORDER RADIUS SCALE)
  // ===========================================================================
  static const double radiusXxsm = 4.0;
  static const double radiusXsm = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 14.0;
  static const double radiusDefault = 16.0;
  static const double radiusL = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 32.0;

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusDefault = BorderRadius.all(
    Radius.circular(radiusDefault),
  );
  static const BorderRadius borderRadiusL = BorderRadius.all(
    Radius.circular(radiusL),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );

  // ===========================================================================
  // 6. HAUTEURS DE BOUTONS & COMPOSANTS CLÉS
  // ===========================================================================
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightDefault = 52.0;
  static const double buttonHeightL = 56.0;
  static const double inputHeight = 52.0;
  static const double headerHeight = 60.0;
  static const double bottomNavHeight = 64.0;
}
