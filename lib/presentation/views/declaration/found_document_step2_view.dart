import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../widgets/city_picker_sheet.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/photo_service.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/photo_source_sheet.dart';
import 'found_document_step1_view.dart';
import 'found_document_step3_view.dart';

/// Étape 2/3 : Déclaration d'un document trouvé — Informations du
/// propriétaire, circonstances de découverte, description et photo.
class FoundDocumentStep2View extends StatefulWidget {
  final FoundDeclarationModel declaration;

  const FoundDocumentStep2View({super.key, required this.declaration});

  @override
  State<FoundDocumentStep2View> createState() => _FoundDocumentStep2ViewState();
}

class _FoundDocumentStep2ViewState extends State<FoundDocumentStep2View> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _birthPlaceController;
  late final TextEditingController _foundDateController;
  late final TextEditingController _foundLocationController;
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
    _foundDateController = TextEditingController(text: data.foundDate);
    _foundLocationController = TextEditingController(text: data.foundLocation);
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
    _foundDateController.dispose();
    _foundLocationController.dispose();
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
      ..foundDate = _foundDateController.text.trim()
      ..foundLocation = _foundLocationController.text.trim()
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
      debugPrint('[FoundDocumentStep2] Erreur sélection photo: $e');
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
  /// (propriétaire/circonstances) à l'étape 3 (vérification).
  void _goToStep3() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Veuillez renseigner les champs requis.'),
        ),
      );
      return;
    }

    _syncDeclaration();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoundDocumentStep3View(declaration: widget.declaration),
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
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSizes.paddingPage,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Civic Encouragement Banner
                      _buildCivicBanner(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // Progress header (étape 2/3)
                      _buildProgressHeader(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // Owner Visible Info Card
                      _buildOwnerInfoCard(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // Discovery Date & Place
                      _buildDiscoveryCircumstances(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // Description
                      _buildDescriptionField(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // Photo Section
                      _buildPhotoUploadSection(),
                      const SizedBox(height: AppSizes.spaceXl),

                      // CTA Button (Green StadiumBorder)
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
                              Icons.verified_user_rounded,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Document trouvé',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Étape 2 sur 3',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSubtle),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: AppColors.textSubtle,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Guide citoyen Finds'),
                  content: const Text(
                    'En signalant un document trouvé, vous aidez un concitoyen à éviter de lourdes démarches administratives. Vos coordonnées restent masquées jusqu\'à validation mutuelle.',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Compris',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCivicBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFC8E6C9),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merci pour votre geste civique !',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Votre signalement permet au propriétaire légitime de retrouver son document officiel en toute sécurité.',
                  style: TextStyle(
                    fontSize: 12,
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

  /// En-tête de progression : Étape 2 sur 3 (66 %).
  Widget _buildProgressHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Informations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Étape 2 sur 3',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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

  /// Bloc « Informations du propriétaire » — carte premium à en-tête.
  /// Bandeau dégradé (avatar + titre + badge « Chiffré »), séparateur fin,
  /// champs blancs à bordure légère avec accent vert au focus, puis pied
  /// de carte avec la mention chiffrée. Nom, prénom(s) et date de naissance
  /// sont obligatoires (comme sur la page « document perdu »).
  Widget _buildOwnerInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF4EC), Color(0xFFF8FBF9)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations du propriétaire',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textStrong,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Indiquez les données visibles sur le document',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                        size: 11,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Confidentiel',
                        style: TextStyle(
                          fontSize: 11,
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

          // Champs : identité du propriétaire
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
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
                    const SizedBox(width: 10),
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
                const SizedBox(height: 12),
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
                    const SizedBox(width: 10),
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
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 13),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Ces informations servent à retrouver le propriétaire du document.',
                    style: TextStyle(
                      fontSize: 11.5,
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

  /// Décoration commune aux champs du bloc propriétaire.
  InputDecoration _ownerFieldDecoration({
    required String label,
    bool isRequired = false,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
  }) {
    const radius = BorderRadius.all(Radius.circular(12));
    const border = BorderSide(color: Color(0xFFE4E7E5));
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      hintText: hint ?? label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: AppColors.primary, size: 18),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, color: AppColors.primary, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      suffixIconConstraints: const BoxConstraints(minWidth: 38),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSubtle,
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      hintStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSubtle,
      ),
      errorStyle: const TextStyle(fontSize: 12),
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

  Widget _buildDiscoveryCircumstances() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date de découverte *',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: _foundDateController,
            readOnly: true,
            onTap: () => _pickDate(_foundDateController),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ requis' : null,
            decoration: const InputDecoration(
              hintText: 'Sélectionnez la date de découverte',
              prefixIcon: Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: Icon(
                Icons.edit_calendar_rounded,
                color: AppColors.textSubtle,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Lieu où vous avez trouvé le document *',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: _foundLocationController,
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
                    title: 'Lieu de découverte',
                  );
                  if (place != null) _foundLocationController.text = place;
                },
              ),
              prefixIcon: const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description & contexte de découverte',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Entrez la description du document et les circonstances de découverte',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Photo du document (optionnel)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Recommandé',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_hasPhoto)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _photoName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _photoSize,
                            style: const TextStyle(
                              fontSize: 12,
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
          )
        else
          InkWell(
            onTap: _pickPhoto,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ajouter une photo du document',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Prenez une photo claire. Veillez à masquer les données sensibles (JPG, PNG max 5 Mo).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
