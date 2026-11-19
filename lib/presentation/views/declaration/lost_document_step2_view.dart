import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../widgets/city_picker_sheet.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/photo_service.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/photo_source_sheet.dart';
import 'lost_document_step1_view.dart';
import 'lost_document_step3_view.dart';

/// Étape 2/3 : Déclaration d'un document perdu — Vos informations
/// personnelles, circonstances et photo.
class LostDocumentStep2View extends StatefulWidget {
  final LostDeclarationModel declaration;

  const LostDocumentStep2View({super.key, required this.declaration});

  @override
  State<LostDocumentStep2View> createState() => _LostDocumentStep2ViewState();
}

class _LostDocumentStep2ViewState extends State<LostDocumentStep2View> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _lossDateController;
  late final TextEditingController _lossLocationController;
  late final TextEditingController _descriptionController;

  bool _hasPhoto = false;
  String _photoName = '';
  Uint8List? _photoBytes;
  String _photoSize = '';

  @override
  void initState() {
    super.initState();
    final data = widget.declaration;
    _lastNameController = TextEditingController(text: data.lastName);
    _firstNameController = TextEditingController(text: data.firstName);
    _birthDateController = TextEditingController(text: data.birthDate);
    _birthPlaceController = TextEditingController(text: data.birthPlace);
    _lossDateController = TextEditingController(text: data.lossDate);
    _lossLocationController = TextEditingController(text: data.lossLocation);
    _descriptionController = TextEditingController(text: data.description);
    _hasPhoto = data.photoName != null;
    if (data.photoName != null) {
      _photoName = data.photoName!;
      _photoBytes = data.photoBytes;
      _photoSize = data.photoSize ?? '1.2 Mo';
    }
  }

  @override
  void dispose() {
    // Conserve les saisies dans le modèle partagé si l'on revient en arrière.
    _syncDeclaration();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _birthDateController.dispose();
    _birthPlaceController.dispose();
    _lossDateController.dispose();
    _lossLocationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Écrit les champs de l'étape 2 dans le modèle partagé avec l'étape 1.
  void _syncDeclaration() {
    widget.declaration
      ..lastName = _lastNameController.text.trim()
      ..firstName = _firstNameController.text.trim()
      ..birthDate = _birthDateController.text.trim()
      ..birthPlace = _birthPlaceController.text.trim()
      ..lossDate = _lossDateController.text.trim()
      ..lossLocation = _lossLocationController.text.trim()
      ..description = _descriptionController.text.trim()
      ..photoName = _hasPhoto ? _photoName : null
      ..photoBytes = _hasPhoto ? _photoBytes : null
      ..photoSize = _hasPhoto ? _photoSize : null;
  }

  /// Ouvre l'appareil photo ou la galerie et mémorise la photo choisie.
  Future<void> _pickPhoto() async {
    final source = await showPhotoSourceSheet(
      context,
      title: 'Ajouter une photo du document',
    );
    if (source == null || !mounted) return;

    try {
      final photo = await PhotoService.pick(source: source);
      if (photo == null || !mounted) return;
      setState(() {
        _hasPhoto = true;
        _photoName = photo.name;
        _photoBytes = photo.bytes;
        _photoSize = photo.sizeLabel;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Photo ajoutée : ${photo.name} (${photo.sizeLabel})'),
        ),
      );
    } on PhotoTooLargeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text(e.toString())),
      );
    } catch (e) {
      debugPrint('[LostDocumentStep2] Erreur sélection photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Impossible d\'ouvrir le sélecteur de photo.'),
        ),
      );
    }
  }

  /// Valide le formulaire et transmet l'étape 1 (document) + l'étape 2
  /// (informations personnelles/circonstances) à l'étape 3 (vérification).
  void _goToStep3() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Veuillez compléter les informations obligatoires.'),
        ),
      );
      return;
    }

    _syncDeclaration();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LostDocumentStep3View(declaration: widget.declaration),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1930),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      setState(() {
        controller.text = '$day/$month/$year';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: AppSizes.paddingPage,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress & Context
                      _buildProgressSection(),
                      const SizedBox(height: AppSizes.spaceMd - 2),

                      // Assurance Banner
                      _buildAssuranceBanner(),
                      const SizedBox(height: AppSizes.spaceL - 2),

                      // SECTION 1: Owner Information
                      _buildOwnerInfoCard(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // SECTION 2: Circumstances of Loss
                      _buildSectionCard(
                        title: 'Circonstances de la perte',
                        icon: Icons.explore_rounded,
                        children: [_buildCircumstancesFields()],
                      ),
                      const SizedBox(height: AppSizes.spaceMd),

                      // SECTION 3: Document Photo (Optional)
                      _buildSectionCard(
                        title: 'Photo du document',
                        icon: Icons.photo_camera_rounded,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spaceXsm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9E8E7),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm - 2,
                            ),
                          ),
                          child: const Text(
                            'Optionnel',
                            style: TextStyle(
                              fontSize: AppSizes.fontXxsm + 1,
                              color: AppColors.textBody,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        children: [_buildPhotoSection()],
                      ),
                      const SizedBox(height: AppSizes.spaceXl),

                      // CTA Button: Round StadiumBorder
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeightDefault,
                        child: ElevatedButton(
                          onPressed: _goToStep3,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: const StadiumBorder(),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continuer vers l\'étape 3',
                                style: TextStyle(
                                  fontSize: AppSizes.fontMd,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: AppSizes.spaceXsm),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: AppSizes.iconMd,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceSm),

                      // Legal badge
                      const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gavel_rounded,
                              size: AppSizes.iconSm,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: AppSizes.spaceXxsm + 2),
                            Flexible(
                              child: Text(
                                'Connexion sécurisée (HTTPS) • Numéros de document masqués',
                                style: TextStyle(
                                  fontSize: AppSizes.fontXxsm + 1,
                                  color: AppColors.textSubtle,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceXxl - 4),
                    ],
                  ),
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
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: AppSizes.spaceSm - 2),
          const Expanded(
            child: Text(
              'Nouvelle Déclaration',
              style: TextStyle(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSubtle,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceSm - 2,
                vertical: AppSizes.spaceXxsm + 2,
              ),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document perdu',
                    style: TextStyle(
                      fontSize: AppSizes.fontXl,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Étape 2 sur 3 • Informations',
                    style: TextStyle(
                      fontSize: AppSizes.fontXsm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceSm - 2,
                vertical: AppSizes.spaceXxsm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 3.5, backgroundColor: AppColors.primary),
                  SizedBox(width: AppSizes.spaceXxsm + 2),
                  Text(
                    '66% complété',
                    style: TextStyle(
                      fontSize: AppSizes.fontXxsm + 1.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceSm - 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: 0.66,
            minHeight: 6,
            backgroundColor: AppColors.chipBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildAssuranceBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: AppSizes.spaceMd,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
              size: AppSizes.iconSm,
            ),
          ),
          SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIGNALEMENT SÉCURISÉ',
                  style: TextStyle(
                    fontSize: AppSizes.fontXxsm + 1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Vos informations permettront d\'alerter automatiquement le réseau civique dès qu\'un document concordant est signalé.',
                  style: TextStyle(
                    fontSize: AppSizes.fontXsm,
                    color: AppColors.textBody,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      padding: AppSizes.paddingCard,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSizes.borderRadiusDefault,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.spaceXxl,
                height: AppSizes.spaceXxl,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXsm),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: AppSizes.iconSm,
                ),
              ),
              const SizedBox(width: AppSizes.spaceSm - 2),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSizes.spaceMd - 2),
          ...children,
        ],
      ),
    );
  }

  /// Bloc « Vos informations personnelles » — carte premium à en-tête.
  /// Bandeau dégradé (avatar + titre + badge « Chiffré »), séparateur fin,
  /// champs blancs à bordure légère avec accent vert au focus, puis pied
  /// de carte avec la mention chiffrée. Les validateurs (champs
  /// obligatoires) sont conservés.
  Widget _buildOwnerInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: const Color(0xFFECEFED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bandeau d'en-tête
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceMd - 2,
              vertical: AppSizes.spaceSm,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF4EC), Color(0xFFF8FBF9)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusL),
                topRight: Radius.circular(AppSizes.radiusL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.iconXxl - 2,
                  height: AppSizes.iconXxl - 2,
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
                    Icons.badge_rounded,
                    color: AppColors.primary,
                    size: AppSizes.iconDefault - 2,
                  ),
                ),
                const SizedBox(width: AppSizes.spaceSm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vos informations personnelles',
                        style: TextStyle(
                          fontSize: AppSizes.fontMd,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textStrong,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Nom, prénom, date et lieu de naissance',
                        style: TextStyle(
                          fontSize: AppSizes.fontXxsm + 1.5,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.spaceXsm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceXsm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: AppSizes.iconXxsm - 1,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSizes.spaceXxsm),
                      Text(
                        'Confidentiel',
                        style: TextStyle(
                          fontSize: AppSizes.fontXxsm,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),

          // Champs : état civil du titulaire
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.spaceMd - 2,
              AppSizes.spaceMd - 2,
              AppSizes.spaceMd - 2,
              AppSizes.spaceXxsm,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Champ requis'
                            : null,
                        decoration: _ownerFieldDecoration(
                          label: 'Nom',
                          isRequired: true,
                          prefixIcon: Icons.person_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spaceSm - 2),
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Champ requis'
                            : null,
                        decoration: _ownerFieldDecoration(
                          label: 'Prénom(s)',
                          isRequired: true,
                          prefixIcon: Icons.badge_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spaceSm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _birthDateController,
                        readOnly: true,
                        onTap: () => _pickDate(_birthDateController),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Champ requis'
                            : null,
                        decoration: _ownerFieldDecoration(
                          label: 'Date de naissance',
                          isRequired: true,
                          suffixIcon: Icons.calendar_today_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spaceSm - 2),
                    Expanded(
                      child: TextFormField(
                        controller: _birthPlaceController,
                        decoration: _ownerFieldDecoration(
                          label: 'Lieu de naissance',
                          hint: 'Entrez votre lieu de naissance',
                          prefixIcon: Icons.location_city_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pied de carte : réassurance RGPD
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.spaceMd - 2,
              AppSizes.spaceXxsm,
              AppSizes.spaceMd - 2,
              AppSizes.spaceSm,
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: AppSizes.iconSm - 5,
                  color: AppColors.primary,
                ),
                SizedBox(width: AppSizes.spaceXxsm + 2),
                Expanded(
                  child: Text(
                    'Ces informations servent à retrouver le propriétaire du document.',
                    style: TextStyle(
                      fontSize: AppSizes.fontXxsm + 0.5,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Décoration commune aux champs du bloc informations personnelles.
  InputDecoration _ownerFieldDecoration({
    required String label,
    bool isRequired = false,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
  }) {
    const radius = AppSizes.borderRadiusSm;
    const border = BorderSide(color: Color(0xFFE4E7E5));
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      hintText: hint ?? label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceSm,
        vertical: AppSizes.spaceMd - 1,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: AppColors.primary, size: AppSizes.iconSm),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(
              suffixIcon,
              color: AppColors.primary,
              size: AppSizes.iconSm - 2,
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      suffixIconConstraints: const BoxConstraints(minWidth: 38),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        fontSize: AppSizes.fontXsm,
        fontWeight: FontWeight.w600,
        color: AppColors.textSubtle,
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: AppSizes.fontXsm,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      hintStyle: const TextStyle(
        fontSize: AppSizes.fontSm,
        fontWeight: FontWeight.w500,
        color: AppColors.textSubtle,
      ),
      errorStyle: const TextStyle(fontSize: AppSizes.fontXxsm + 1),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: border,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: border,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.error, width: 1.4),
      ),
    );
  }

  Widget _buildCircumstancesFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date de perte *',
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.spaceXxsm + 2),
        TextFormField(
          controller: _lossDateController,
          readOnly: true,
          onTap: () => _pickDate(_lossDateController),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Champ requis' : null,
          decoration: InputDecoration(
            hintText: 'Sélectionnez la date de perte',
            suffixIcon: const Icon(
              Icons.event_busy_rounded,
              color: AppColors.primary,
              size: AppSizes.iconMd,
            ),
            filled: true,
            fillColor: AppColors.inputFill,
            contentPadding: AppSizes.paddingInput,
            border: OutlineInputBorder(
              borderRadius: AppSizes.borderRadiusSm,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceMd - 2),
        const Text(
          'Lieu de perte *',
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.spaceXxsm + 2),
        TextFormField(
          controller: _lossLocationController,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Champ requis' : null,
          decoration: InputDecoration(
            hintText: 'Saisissez le lieu ou choisissez dans la liste',
            suffixIcon: IconButton(
              tooltip: 'Choisir dans la liste des villes',
              icon: const Icon(
                Icons.format_list_bulleted_rounded,
                color: AppColors.primary,
              ),
              onPressed: () async {
                final place = await showCityPickerSheet(
                  context,
                  title: 'Lieu de perte',
                );
                if (place != null) _lossLocationController.text = place;
              },
            ),
            prefixIcon: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: AppSizes.iconMd,
            ),
            filled: true,
            fillColor: AppColors.inputFill,
            contentPadding: AppSizes.paddingInput,
            border: OutlineInputBorder(
              borderRadius: AppSizes.borderRadiusSm,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceMd - 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Description ou précisions',
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_descriptionController.text.length}/300',
              style: const TextStyle(
                fontSize: AppSizes.fontXxsm + 1,
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceXxsm + 2),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          maxLength: 300,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'Entrez des détails utiles (couleur, particularités, circonstances…)',
            filled: true,
            fillColor: AppColors.inputFill,
            counterText: '',
            contentPadding: const EdgeInsets.all(AppSizes.spaceMd - 2),
            border: OutlineInputBorder(
              borderRadius: AppSizes.borderRadiusSm,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    if (_hasPhoto) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spaceSm - 2),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: AppSizes.borderRadiusSm,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.iconXxl,
                  height: AppSizes.iconXxl,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXsm),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: AppColors.primary,
                    size: AppSizes.iconDefault,
                  ),
                ),
                const SizedBox(width: AppSizes.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _photoName,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _photoSize,
                            style: const TextStyle(
                              fontSize: AppSizes.fontXxsm + 1,
                              color: AppColors.textSubtle,
                            ),
                          ),
                          const SizedBox(width: AppSizes.spaceXxsm + 2),
                          const CircleAvatar(
                            radius: 2,
                            backgroundColor: Color(0xFFBFCABA),
                          ),
                          const SizedBox(width: AppSizes.spaceXxsm + 2),
                          const Icon(
                            Icons.lock_rounded,
                            size: AppSizes.iconXxsm,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'Confidentiel',
                            style: TextStyle(
                              fontSize: AppSizes.fontXxsm + 1,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: AppSizes.iconXl - 14,
                  ),
                  onPressed: () {
                    setState(() {
                      _hasPhoto = false;
                      _photoName = '';
                      _photoSize = '';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm - 2),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(
              Icons.add_a_photo_rounded,
              size: AppSizes.iconSm,
              color: AppColors.primary,
            ),
            label: const Text(
              'Remplacer ou ajouter le verso',
              style: TextStyle(color: AppColors.textStrong),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: RoundedRectangleBorder(
                borderRadius: AppSizes.borderRadiusSm,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.spaceSm,
                horizontal: AppSizes.spaceMd,
              ),
            ),
          ),
        ],
      );
    } else {
      return InkWell(
        onTap: _pickPhoto,
        borderRadius: AppSizes.borderRadiusSm,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceL),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: AppSizes.borderRadiusSm,
            border: Border.all(
              color: const Color(0xFFD0D7DE),
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.add_a_photo_rounded,
                color: AppColors.primary,
                size: AppSizes.iconL + 2,
              ),
              SizedBox(height: AppSizes.spaceXxsm + 2),
              Text(
                'Ajouter une photo du document',
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'JPG, PNG (Optionnel)',
                style: TextStyle(
                  fontSize: AppSizes.fontXxsm + 1,
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
