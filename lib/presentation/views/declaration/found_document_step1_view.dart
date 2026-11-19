import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';
import 'found_document_step2_view.dart';

/// Modèle pour les données d'un document trouvé
class FoundDeclarationModel {
  String documentType;
  String customDocumentType;
  String documentNumber;
  String lastName;
  String firstName;
  String birthDate;
  String birthPlace;
  String foundDate;
  String foundLocation;
  String description;
  String? photoName;
  Uint8List? photoBytes;
  String? photoSize;
  String contactMethod;
  bool isCertified;

  FoundDeclarationModel({
    this.documentType = '',
    this.customDocumentType = '',
    this.documentNumber = '',
    this.lastName = '',
    this.firstName = '',
    this.birthDate = '',
    this.birthPlace = '',
    this.foundDate = '',
    this.foundLocation = '',
    this.description = '',
    this.photoName,
    this.photoBytes,
    this.photoSize,
    this.contactMethod = 'internal',
    this.isCertified = true,
  });

  String get maskedNumber {
    if (documentNumber.isEmpty) return 'Non renseigné';
    if (documentNumber.length <= 4) return '••••';
    final start = documentNumber.substring(0, 2);
    final end = documentNumber.substring(documentNumber.length - 3);
    return '$start•••••$end';
  }

  String get documentTypeLabel {
    switch (documentType) {
      case 'CNI':
        return 'Carte Nationale d’Identité (CNI)';
      case 'PASSPORT':
        return 'Passeport ';
      case 'PERMIS':
        return 'Permis de conduire';
      case 'STUDENT':
        return 'Carte d’étudiant';
      case 'GRISE':
        return 'Carte grise (Certificat d’immatriculation)';
      case 'AUTRE':
        return customDocumentType.trim().isNotEmpty
            ? customDocumentType.trim()
            : 'Autre document officiel';
      default:
        return customDocumentType.trim().isNotEmpty
            ? customDocumentType.trim()
            : 'Autre document officiel';
    }
  }
}

/// Étape 1/3 : Déclaration d'un document trouvé — Identification du document
/// Conforme à la maquette findmydoc_document_trouv_tape_1_2
class FoundDocumentStep1View extends StatefulWidget {
  final FoundDeclarationModel? initialData;

  const FoundDocumentStep1View({super.key, this.initialData});

  @override
  State<FoundDocumentStep1View> createState() => _FoundDocumentStep1ViewState();
}

class _FoundDocumentStep1ViewState extends State<FoundDocumentStep1View> {
  final _formKey = GlobalKey<FormState>();

  /// Modèle partagé avec les étapes 2 et 3 : comme cet État reste dans la
  /// pile de navigation pendant tout le parcours, les données saisies dans
  /// les étapes suivantes restent disponibles si l'on revient en arrière.
  late final FoundDeclarationModel _declaration;

  late String _documentType;
  late final TextEditingController _docNumberController;
  late final TextEditingController _customDocTypeController;

  final List<Map<String, String>> _docTypes = [
    {'value': 'CNI', 'label': 'Carte Nationale d’Identité (CNI)'},
    {'value': 'PASSPORT', 'label': 'Passeport'},
    {'value': 'PERMIS', 'label': 'Permis de conduire'},
    {'value': 'STUDENT', 'label': 'Carte d’étudiant'},
    {'value': 'GRISE', 'label': 'Carte grise'},
    {'value': 'AUTRE', 'label': 'Autre document officiel...'},
  ];

  @override
  void initState() {
    super.initState();
    _declaration = widget.initialData ?? FoundDeclarationModel();
    _documentType = _declaration.documentType;
    _docNumberController = TextEditingController(
      text: _declaration.documentNumber,
    );
    _customDocTypeController = TextEditingController(
      text: _declaration.customDocumentType,
    );
  }

  @override
  void dispose() {
    _docNumberController.dispose();
    _customDocTypeController.dispose();
    super.dispose();
  }

  /// Valide l'identification du document puis transmet (étape 1 → étape 2).
  void _goToStep2() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Veuillez sélectionner un type de document.'),
        ),
      );
      return;
    }

    _declaration
      ..documentType = _documentType
      ..customDocumentType = _documentType == 'AUTRE'
          ? _customDocTypeController.text.trim()
          : ''
      ..documentNumber = _docNumberController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoundDocumentStep2View(declaration: _declaration),
      ),
    );
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
                      // Progress header (étape 1/3)
                      _buildProgressHeader(),
                      const SizedBox(height: AppSizes.spaceMd - 2),

                      // Civic Encouragement Banner
                      _buildCivicBanner(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // Document Type
                      _buildDocTypeDropdown(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // Document Number (Optional & Masked)
                      _buildDocNumberField(),
                      const SizedBox(height: AppSizes.spaceXl),

                      // CTA Button (Green StadiumBorder)
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeightDefault,
                        child: ElevatedButton(
                          onPressed: _goToStep2,
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
                                'Continuer vers l\'étape 2',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Document trouvé',
                  style: TextStyle(
                    fontSize: AppSizes.fontL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Étape 1 sur 3',
                  style: TextStyle(
                    fontSize: AppSizes.fontXxsm + 1.5,
                    color: AppColors.textSubtle,
                  ),
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
                    borderRadius: AppSizes.borderRadiusDefault,
                  ),
                  title: const Text('Guide citoyen Finds'),
                  content: const Text(
                    'En signalant un document trouvé, vous aidez un concitoyen à éviter de lourdes démarches administratives. Vos coordonnées restent masquées jusqu\'à validation mutuelle.',
                    style: TextStyle(fontSize: AppSizes.fontSm, height: 1.4),
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
      padding: const EdgeInsets.all(AppSizes.spaceMd - 2),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppSizes.borderRadiusDefault,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: AppSizes.iconSm,
            backgroundColor: Color(0xFFC8E6C9),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.primary,
              size: AppSizes.iconMd,
            ),
          ),
          SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merci pour votre geste civique !',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm + 1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Votre signalement permet au propriétaire légitime de retrouver son document officiel en toute sécurité.',
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

  Widget _buildDocTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Type de document *',
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceXsm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
              ),
              child: const Text(
                'Obligatoire',
                style: TextStyle(
                  fontSize: AppSizes.fontXxsm,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceXxsm + 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd - 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _documentType.isEmpty ? null : _documentType,
            isExpanded: true,
            hint: const Text(
              'Sélectionnez un type de document…',
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w500,
                color: AppColors.textSubtle,
              ),
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Veuillez sélectionner un type de document'
                : null,
            icon: const Icon(
              Icons.expand_more_rounded,
              color: AppColors.textSubtle,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 14),
              border: InputBorder.none,
            ),
            items: _docTypes.map((item) {
              return DropdownMenuItem<String>(
                value: item['value'],
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_rounded,
                      size: AppSizes.iconMd,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSizes.spaceSm - 2),
                    Flexible(
                      child: Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _documentType = val);
            },
          ),
        ),
        if (_documentType == 'AUTRE') ...[
          const SizedBox(height: AppSizes.spaceSm),
          TextFormField(
            controller: _customDocTypeController,
            validator: (v) {
              if (_documentType == 'AUTRE' && (v == null || v.trim().isEmpty)) {
                return 'Veuillez préciser le type de document';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Précisez le type de document *',
              hintText:
                  'Ex. Titre foncier, Carte consulaire, Badge professionnel...',
              prefixIcon: const Icon(
                Icons.edit_note_rounded,
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
        ],
      ],
    );
  }

  Widget _buildDocNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Numéro du document (optionnel)',
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.lock_rounded,
              size: AppSizes.iconSm - 2,
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceXxsm + 2),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: _docNumberController,
            decoration: const InputDecoration(
              hintText: 'Entrez le numéro du document',
              prefixIcon: Icon(
                Icons.tag_rounded,
                color: AppColors.primary,
                size: AppSizes.iconMd,
              ),
              border: InputBorder.none,
              contentPadding: AppSizes.paddingInput,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceXxsm),
        const Row(
          children: [
            Icon(
              Icons.shield_rounded,
              size: AppSizes.iconXsm,
              color: AppColors.textSubtle,
            ),
            SizedBox(width: AppSizes.spaceXxsm + 1),
            Expanded(
              child: Text(
                'Partiellement masqué pour garantir la stricte confidentialité.',
                style: TextStyle(
                  fontSize: AppSizes.fontXxsm + 1,
                  color: AppColors.textSubtle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// En-tête de progression : Étape 1 sur 3 (33 %).
  Widget _buildProgressHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Identification',
              style: TextStyle(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Étape 1 sur 3',
              style: TextStyle(
                fontSize: AppSizes.fontXsm,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceSm - 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: 0.33,
            minHeight: 6,
            backgroundColor: AppColors.chipBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
