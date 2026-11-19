import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';
import 'lost_document_step2_view.dart';

/// Modèle pour les données de déclaration de document perdu
class LostDeclarationModel {
  String documentType;
  String customDocumentType;
  String documentNumber;
  String lastName;
  String firstName;
  String birthDate;
  String birthPlace;
  String lossDate;
  String lossLocation;
  String description;
  String? photoName;
  Uint8List? photoBytes;
  String? photoSize;
  String contactMethod;
  bool isCertified;

  LostDeclarationModel({
    this.documentType = '',
    this.customDocumentType = '',
    this.documentNumber = '',
    this.lastName = '',
    this.firstName = '',
    this.birthDate = '',
    this.birthPlace = '',
    this.lossDate = '',
    this.lossLocation = '',
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
        return 'Passeport';
      case 'PERMIS':
        return 'Permis de conduire';
      case 'STUDENT':
        return 'Carte d’étudiant';
      case 'GRISE':
        return 'Carte grise (Certificat d’immatriculation)';
      case 'DIPLOMA':
        return 'Diplôme ou Attestation d’État';
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

/// Étape 1/3 : Déclaration d'un document perdu — Identification du document
/// Conforme à la maquette findmydoc_document_perdu_tape_1_2
class LostDocumentStep1View extends StatefulWidget {
  final LostDeclarationModel? initialData;

  const LostDocumentStep1View({super.key, this.initialData});

  @override
  State<LostDocumentStep1View> createState() => _LostDocumentStep1ViewState();
}

class _LostDocumentStep1ViewState extends State<LostDocumentStep1View> {
  final _formKey = GlobalKey<FormState>();

  /// Modèle partagé avec les étapes 2 et 3 : comme cet État reste dans la
  /// pile de navigation pendant tout le parcours, les données saisies dans
  /// les étapes suivantes restent disponibles si l'on revient en arrière.
  late final LostDeclarationModel _declaration;

  late String _documentType;
  late final TextEditingController _docNumberController;
  late final TextEditingController _customDocTypeController;

  final List<Map<String, String>> _docTypes = [
    {'value': 'CNI', 'label': 'Carte Nationale d’Identité (CNI)'},
    {'value': 'PASSPORT', 'label': 'Passeport'},
    {'value': 'PERMIS', 'label': 'Permis de conduire'},
    {'value': 'STUDENT', 'label': 'Carte d’étudiant'},
    {'value': 'GRISE', 'label': 'Carte grise (Immatriculation)'},
    {'value': 'DIPLOMA', 'label': 'Diplôme ou Attestation d’État'},
    {'value': 'AUTRE', 'label': 'Autre document officiel…'},
  ];

  @override
  void initState() {
    super.initState();
    _declaration = widget.initialData ?? LostDeclarationModel();
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
        builder: (_) => LostDocumentStep2View(declaration: _declaration),
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

                      // SECTION 1: Document Identification
                      _buildSectionCard(
                        title: 'Identification du document',
                        icon: Icons.badge_rounded,
                        children: [
                          _buildDocTypeDropdown(),
                          const SizedBox(height: AppSizes.spaceMd),
                          _buildDocNumberField(),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spaceXl),

                      // CTA Button: Round StadiumBorder
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
                    'Étape 1 sur 3 • Identification',
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
                    '33% complété',
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
            value: 0.33,
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
                color: AppColors.textStrong,
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
                'Officiel',
                style: TextStyle(
                  fontSize: AppSizes.fontXxsm,
                  fontWeight: FontWeight.w700,
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
            color: AppColors.inputFill,
            borderRadius: AppSizes.borderRadiusSm,
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
                          color: AppColors.textStrong,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _documentType = val);
              }
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Numéro du document',
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceXsm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE9E8E7),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
              ),
              child: const Text(
                'Optionnel',
                style: TextStyle(
                  fontSize: AppSizes.fontXxsm,
                  color: AppColors.textBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceXxsm + 2),
        TextFormField(
          controller: _docNumberController,
          decoration: InputDecoration(
            hintText: 'Entrez le numéro du document',
            prefixIcon: const Icon(
              Icons.tag_rounded,
              color: AppColors.textSubtle,
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
        const SizedBox(height: AppSizes.spaceXxsm + 2),
        const Row(
          children: [
            Icon(
              Icons.lock_rounded,
              size: AppSizes.iconXsm,
              color: AppColors.primary,
            ),
            SizedBox(width: AppSizes.spaceXxsm + 2),
            Expanded(
              child: Text(
                'Les chiffres centraux seront automatiquement masqués pour préserver votre identité.',
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
}
