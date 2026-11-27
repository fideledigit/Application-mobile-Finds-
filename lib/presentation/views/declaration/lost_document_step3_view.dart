import 'package:flutter/material.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/photo_upload_service.dart';
import '../../../core/utils/document_utils.dart';
import '../../../core/services/receipt_pdf_service.dart';
import '../../../core/services/share_service.dart';
import '../../widgets/app_back_button.dart';
import '../auth/login_view.dart';
import '../home/main_screen.dart';
import 'lost_document_step1_view.dart';

/// Étape 3/3 : Vérification et publication du document perdu
/// Conforme à la maquette findmydoc_v_rification_tape_2_2_document_perdu
class LostDocumentStep3View extends StatefulWidget {
  final LostDeclarationModel declaration;

  const LostDocumentStep3View({super.key, required this.declaration});

  @override
  State<LostDocumentStep3View> createState() => _LostDocumentStep3ViewState();
}

class _LostDocumentStep3ViewState extends State<LostDocumentStep3View> {
  late String _selectedContactMethod;
  late final String _localReference;
  String _serverReference = '';
  bool _certifyChecked = true;
  bool _isPublishing = false;
  bool _isPublished = false;

  String get _reference =>
      _serverReference.isNotEmpty ? _serverReference : _localReference;

  @override
  void initState() {
    super.initState();
    _selectedContactMethod = widget.declaration.contactMethod;
    // Le dépôt physique chez un partenaire n'est plus proposé.
    if (!['internal', 'masked_phone'].contains(_selectedContactMethod)) {
      _selectedContactMethod = 'internal';
    }
    _localReference =
        'DEC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  void _submitDeclaration() async {
    if (!_certifyChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Veuillez certifier sur l\'honneur l\'exactitude des informations avant de valider.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    // Pas d'auto-login : l'utilisateur doit se connecter via LoginView.
    if (FindsApiClient.authToken.value == null) {
      if (mounted) {
        setState(() => _isPublishing = false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
      return;
    }

    String serverReference = '';

    try {
      final dec = widget.declaration;

      // Normalisation du TypeDocument pour l'API RetrouveTout (nye-agbale)
      String docTypeEnum = 'AUTRE';
      final dt = dec.documentType.toUpperCase();
      if (dt == 'CNI') {
        docTypeEnum = 'CNI';
      } else if (dt == 'PASSPORT' || dt == 'PASSEPORT') {
        docTypeEnum = 'PASSEPORT';
      } else if (dt == 'PERMIS' || dt == 'PERMIS_CONDUIRE') {
        docTypeEnum = 'PERMIS_CONDUIRE';
      } else if (dt == 'STUDENT' || dt == 'CARTE_ETUDIANT') {
        docTypeEnum = 'CARTE_ETUDIANT';
      } else if (dt == 'GRISE' || dt == 'CARTE_GRISE') {
        docTypeEnum = 'CARTE_GRISE';
      } else if (dt == 'CARTE_CONSULAIRE') {
        docTypeEnum = 'CARTE_CONSULAIRE';
      } else if (dt == 'CARTE_PROFESSIONNELLE') {
        docTypeEnum = 'CARTE_PROFESSIONNELLE';
      } else if (dt == 'ACTE_NAISSANCE') {
        docTypeEnum = 'ACTE_NAISSANCE';
      } else if (dt == 'CERTIFICAT_NATIONALITE') {
        docTypeEnum = 'CERTIFICAT_NATIONALITE';
      }

      final nom = dec.lastName.isNotEmpty
          ? dec.lastName
          : (FindsApiClient.userLastName.isNotEmpty
                ? FindsApiClient.userLastName
                : FindsApiClient.userFullName);
      final prenom = dec.firstName.isNotEmpty
          ? dec.firstName
          : FindsApiClient.userFirstName;

      final place = splitPlace(dec.lossLocation);
      String? photoUrl;
      if (dec.photoBytes != null) {
        photoUrl = await PhotoUploadService.uploadImageBytes(
          dec.photoBytes!,
          filename: dec.photoName ?? 'photo.jpg',
        );
      }

      final result = await FindsApiClient.mutate(
        GraphQLQueries.createDeclarationMutation,
        variables: {
          'input': {
            'type': 'PERTE',
            'typeDocument': docTypeEnum,
            'nomProprietaire': nom,
            'prenomProprietaire': prenom,
            'numeroDocument': dec.documentNumber.isNotEmpty
                ? dec.documentNumber
                : null,
            'descriptionLibre': dec.description.isNotEmpty
                ? dec.description
                : null,
            'ville': place.ville,
            'quartier': place.quartier,
            'source': 'MOBILE',
            'photoUrl': photoUrl,
          },
        },
      );

      final resp = result.data?['createDeclaration'];
      if (resp == null || resp['success'] != true) {
        if (!mounted) return;
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              FindsApiClient.errorMessage(
                result.exception,
                fallback:
                    resp?['message'] as String? ??
                    'La déclaration n\'a pas pu être publiée.',
              ),
            ),
          ),
        );
        return;
      }
      serverReference =
          'DEC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      FindsApiClient.declarationsRevision.value++;
    } catch (e) {
      debugPrint('[LostDocumentStep3] Exception publication GraphQL: $e');
      if (mounted) setState(() => _isPublishing = false);
      return;
    }

    _serverReference = serverReference;

    if (!mounted) return;

    setState(() {
      _isPublishing = false;
      _isPublished = true;
    });

    _showSuccessDialog(serverReference);
  }

  void _showSuccessDialog([String reference = '']) {
    final displayRef = reference.isNotEmpty
        ? reference
        : 'DEC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Déclaration publiée !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Votre déclaration n° $displayRef pour ${widget.declaration.documentTypeLabel} a été enregistrée avec succès.',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textBody,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(
                        initialIndex: 1,
                      ), // Onglet Déclarations
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Consulter mes déclarations',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ReceiptData _receiptData() {
    final d = widget.declaration;
    return ReceiptData(
      reference: _reference,
      category: 'PERDU',
      documentType: d.documentTypeLabel,
      documentNumber: d.maskedNumber,
      holderName: '${d.lastName} ${d.firstName}'.trim(),
      eventDate: d.lossDate,
      eventLocation: d.lossLocation,
      description: d.description,
      contactMethod: _selectedContactMethod,
      declarantName: FindsApiClient.userFullName,
    );
  }

  Future<void> _shareOnWhatsApp() async {
    final d = widget.declaration;
    final message =
        '🚨 DOCUMENT PERDU — Finds\n'
        'Type : ${d.documentTypeLabel}\n'
        'Lieu de perte : ${d.lossLocation.isNotEmpty ? d.lossLocation : 'Non précisé'}\n'
        'Date : ${d.lossDate.isNotEmpty ? d.lossDate : 'Non précisée'}\n'
        'Référence : $_reference\n\n'
        'Si vous retrouvez ce document, ouvrez l\'application Finds et '
        'signalez-le avec cette référence. Merci de partager ce message '
        'autour de vous, chaque partage augmente les chances de restitution.';

    final ok = await ShareService.shareOnWhatsApp(message);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.whatsapp : AppColors.error,
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ok
                    ? 'Alerte WhatsApp prête à être envoyée !'
                    : 'Impossible d\'ouvrir WhatsApp. Vérifiez qu\'il est installé.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdfSummary() async {
    try {
      final ok = await ReceiptPdfService.share(_receiptData());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppColors.primary : AppColors.error,
          content: Row(
            children: [
              Icon(
                ok ? Icons.picture_as_pdf_rounded : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ok
                      ? 'Fiche PDF générée : choisissez « Enregistrer » ou partagez-la.'
                      : 'Impossible de générer la fiche PDF.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('[LostDocumentStep3] Erreur PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Erreur lors de la génération de la fiche PDF.'),
        ),
      );
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step progress header
                    _buildProgressHeader(),
                    const SizedBox(height: AppSizes.spaceMd - 2),

                    // Security Banner
                    _buildSecurityBanner(),
                    const SizedBox(height: AppSizes.spaceMd),

                    // Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: AppSizes.spaceL - 2),

                    // Contact preference options
                    _buildContactPreferenceSection(),
                    const SizedBox(height: AppSizes.spaceL - 2),

                    // Sworn statement card
                    _buildSwornStatementCard(),
                    const SizedBox(height: AppSizes.spaceL - 2),

                    // Quick secondary action pill buttons: WhatsApp & PDF
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _shareOnWhatsApp,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.spaceSm,
                                horizontal: 6,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.share_rounded,
                                  size: AppSizes.iconSm,
                                  color: AppColors.whatsapp,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Sur WhatsApp',
                                    style: TextStyle(
                                      fontSize: AppSizes.fontSm,
                                      color: AppColors.textStrong,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spaceSm),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _downloadPdfSummary,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.spaceSm,
                                horizontal: 6,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: AppSizes.iconSm,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Fiche en PDF',
                                    style: TextStyle(
                                      fontSize: AppSizes.fontSm,
                                      color: AppColors.textStrong,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spaceL - 2),

                    // Primary action button (Pill StadiumBorder)
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeightDefault,
                      child: ElevatedButton(
                        onPressed: _isPublishing ? null : _submitDeclaration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPublished
                              ? AppColors.successDeep
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: const StadiumBorder(),
                        ),
                        child: _isPublishing
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: AppSizes.iconMd,
                                    height: AppSizes.iconMd,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: AppSizes.spaceSm - 2),
                                  Text(
                                    'Publication en cours...',
                                    style: TextStyle(
                                      fontSize: AppSizes.fontMd,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isPublished
                                        ? Icons.check_rounded
                                        : Icons.check_circle_rounded,
                                    size: AppSizes.iconMd,
                                  ),
                                  const SizedBox(width: AppSizes.spaceXsm),
                                  Flexible(
                                    child: Text(
                                      _isPublished
                                          ? 'Déclaration publiée !'
                                          : 'Confirmer et publier',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: AppSizes.fontMd,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceXsm),

                    // Edit button back to step 2
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: AppSizes.iconSm - 2,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Modifier les informations (Étape 2)',
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceSm - 2),

                    // Legal footnote
                    const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: AppSizes.iconXsm,
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
                    const SizedBox(height: AppSizes.spaceXl),
                  ],
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
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (route) => false,
              );
            },
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

  Widget _buildProgressHeader() {
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
                    'Vérification',
                    style: TextStyle(
                      fontSize: AppSizes.fontXl,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Étape 3 sur 3',
                    style: TextStyle(
                      fontSize: AppSizes.fontXsm,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
                color: const Color(0xFFE9E8E7),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3.5, backgroundColor: AppColors.primary),
                  SizedBox(width: AppSizes.spaceXxsm + 2),
                  Text(
                    'Prêt à valider',
                    style: TextStyle(
                      fontSize: AppSizes.fontXxsm + 1.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
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
            value: 1.0,
            minHeight: 6,
            backgroundColor: AppColors.chipBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
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
                  'Signalement sécurisé',
                  style: TextStyle(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Vérifiez attentivement les données de votre document avant diffusion au réseau civique solidaire.',
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

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Récapitulatif de votre déclaration',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Document perdu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.errorDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Doc Type Item
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.badge_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type de document',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.declaration.documentTypeLabel,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. ID Number
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Numéro officiel',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.declaration.maskedNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.visibility_off_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Partiellement masqué pour préserver votre anonymat',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Titulaire & Né le
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Titulaire',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.declaration.lastName} ${widget.declaration.firstName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Né(e) le',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.declaration.birthDate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Date & Lieu de constatation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Date constatée : ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.declaration.lossDate,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lieu supposé : ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.declaration.lossLocation,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (widget.declaration.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Précisions & contexte',
                    style: TextStyle(fontSize: 12, color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '« ${widget.declaration.description} »',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textStrong,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (widget.declaration.photoName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.declaration.photoName!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.declaration.photoSize ?? 'Photo jointe',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactPreferenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.contact_support_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Comment souhaitez-vous être contacté ?',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Option 1: internal chat
        _buildContactOption(
          id: 'internal',
          title: 'Messagerie interne Finds',
          subtitle:
              'Échangez via la messagerie Finds sans révéler votre numéro de téléphone.',
          badge: 'Recommandé',
        ),
        const SizedBox(height: 8),

        // Option 2: masked phone
        _buildContactOption(
          id: 'masked_phone',
          title: 'Numéro de téléphone masqué',
          subtitle:
              'Appel vocal relayé via un numéro temporaire Finds sécurisé.',
        ),
      ],
    );
  }

  Widget _buildContactOption({
    required String id,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    final isSelected = _selectedContactMethod == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedContactMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textSubtle,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSubtle,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwornStatementCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _certifyChecked,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (val) {
                  setState(() {
                    _certifyChecked = val ?? false;
                  });
                },
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Je certifie sur l’honneur que les informations fournies sont exactes et sincères.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 44.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.gavel_rounded,
                  size: 14,
                  color: AppColors.textSubtle,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tout faux signalement est passible des sanctions prévues par la législation civique en vigueur.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSubtle,
                      height: 1.3,
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
}
