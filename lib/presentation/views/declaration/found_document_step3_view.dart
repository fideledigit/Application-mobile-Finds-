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
import 'found_document_step1_view.dart';

/// Étape 3/3 : Vérification finale et publication d'un document trouvé
/// Conforme à la maquette findmydoc_v_rification_tape_2_2_document_trouv
class FoundDocumentStep3View extends StatefulWidget {
  final FoundDeclarationModel declaration;

  const FoundDocumentStep3View({super.key, required this.declaration});

  @override
  State<FoundDocumentStep3View> createState() => _FoundDocumentStep3ViewState();
}

class _FoundDocumentStep3ViewState extends State<FoundDocumentStep3View> {
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

      final nom = dec.lastName.isNotEmpty ? dec.lastName : 'Inconnu';
      final prenom = dec.firstName.isNotEmpty ? dec.firstName : 'Inconnu';

      final place = splitPlace(dec.foundLocation);
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
            'type': 'TROUVAILLE',
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
      debugPrint('[FoundDocumentStep3] Exception publication GraphQL: $e');
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
                Icons.volunteer_activism_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Merci pour votre civisme !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Votre signalement de ${widget.declaration.documentTypeLabel} a été enregistré avec succès sous le dossier n° $displayRef.',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textBody,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.handshake_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '+50 Pts de Réputation Civique gagnés !',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
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
                  'Voir mes déclarations',
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
      category: 'TROUVE',
      documentType: d.documentTypeLabel,
      documentNumber: d.maskedNumber,
      holderName: '${d.lastName} ${d.firstName}'.trim(),
      eventDate: d.foundDate,
      eventLocation: d.foundLocation,
      description: d.description,
      contactMethod: _selectedContactMethod,
      declarantName: FindsApiClient.userFullName,
    );
  }

  Future<void> _shareOnWhatsApp() async {
    final d = widget.declaration;
    final message =
        '🔎 DOCUMENT TROUVÉ — Finds\n'
        'Type : ${d.documentTypeLabel}\n'
        'Lieu : ${d.foundLocation.isNotEmpty ? d.foundLocation : 'Non précisé'}\n'
        'Date : ${d.foundDate.isNotEmpty ? d.foundDate : 'Non précisée'}\n'
        'Référence : $_reference\n\n'
        'Si ce document vous appartient, ouvrez l\'application Finds et '
        'signalez-le avec cette référence. Merci de partager ce message '
        'autour de vous pour aider à retrouver le propriétaire.';

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

  Future<void> _downloadReceiptPdf() async {
    try {
      final ok = await ReceiptPdfService.share(_receiptData());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppColors.primary : AppColors.error,
          content: Row(
            children: [
              Icon(
                ok ? Icons.receipt_long_rounded : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ok
                      ? 'Reçu PDF généré : choisissez « Enregistrer » ou partagez-le.'
                      : 'Impossible de générer le reçu PDF.',
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
      debugPrint('[FoundDocumentStep3] Erreur PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Erreur lors de la génération du reçu PDF.'),
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Guide citoyen Finds'),
        content: const Text(
          'Vérifiez le récapitulatif du document, choisissez comment être contacté, '
          'puis certifiez l\'exactitude des informations avant de publier.\n\n'
          'Une fois publiée, votre déclaration est visible par les propriétaires '
          'légitimes. Vous pouvez aussi partager l\'alerte sur WhatsApp ou générer '
          'un récépissé PDF depuis les boutons dédiés.',
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
                    _buildProgressHeader(),
                    const SizedBox(height: AppSizes.spaceMd - 2),

                    // Reassuring Shield Banner
                    _buildCivicShieldBanner(),
                    const SizedBox(height: AppSizes.spaceMd),

                    // Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: AppSizes.spaceL - 2),

                    // Contact Preferences
                    _buildContactPreferenceSection(),
                    const SizedBox(height: AppSizes.spaceL - 2),

                    // Sworn statement card
                    _buildSwornStatementCard(),
                    const SizedBox(height: AppSizes.spaceL - 2),

                    // Secondary action buttons (WhatsApp & Reçu PDF)
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
                                    'WhatsApp',
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
                            onPressed: _downloadReceiptPdf,
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
                                  Icons.receipt_long_rounded,
                                  size: AppSizes.iconSm,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Reçu PDF',
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

                    // Primary confirmation CTA (StadiumBorder)
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
                                        ? Icons.check_circle_rounded
                                        : Icons.cloud_done_rounded,
                                    size: AppSizes.iconMd,
                                  ),
                                  const SizedBox(width: AppSizes.spaceXsm),
                                  Flexible(
                                    child: Text(
                                      _isPublished
                                          ? 'Signalement publié avec succès !'
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

                    // Return to step 2
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

                    // Footer legal note
                    const Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Connexion sécurisée • Numéros masqués',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSubtle,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Votre déclaration est publiée avec le numéro de document partiellement masqué.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSubtle,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
                  'Étape 3 sur 3',
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
            onPressed: _showHelpDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Vérification finale',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Étape 3 sur 3',
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
            value: 1.0,
            minHeight: 6,
            backgroundColor: AppColors.chipBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildCivicShieldBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Geste citoyen & sécurisé',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 2, backgroundColor: AppColors.primary),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Protection active',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  'Vos données de contact restent totalement confidentielles jusqu\'à la validation de restitution avec le propriétaire légitime.',
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
              const Text(
                'Récapitulatif du document',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Trouvé',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Core Doc Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
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
                            Text(
                              widget.declaration.documentTypeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.declaration.maskedNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: AppColors.textSubtle,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Confidentiel',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSubtle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Titulaire présumé & Né le
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
                        'Titulaire présumé',
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
                        'Né(e) le / à',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.declaration.birthDate} • ${widget.declaration.birthPlace}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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

          // Date découverte & Lieu exact
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
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Date de découverte : ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.declaration.foundDate,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
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
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lieu exact : ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.declaration.foundLocation,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
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
                    'Précision du déclarant',
                    style: TextStyle(fontSize: 12, color: AppColors.textSubtle),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '« ${widget.declaration.description} »',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
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
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Confidentiel',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
        const Text(
          'Comment souhaitez-vous être contacté ?',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choisissez comment le propriétaire légitime ou les autorités échangeront avec vous.',
          style: TextStyle(fontSize: 12, color: AppColors.textSubtle),
        ),
        const SizedBox(height: 12),

        _buildContactOption(
          id: 'internal',
          title: 'Messagerie Finds',
          subtitle:
              'Chat sécurisé et confidentiel. Aucun échange de numéro personnel avant accord formel.',
          badge: 'Recommandé',
        ),
        const SizedBox(height: 8),

        _buildContactOption(
          id: 'masked_phone',
          title: 'Numéro de téléphone masqué',
          subtitle:
              'Appel vocal sécurisé via numéro relais Finds temporaire sans dévoiler votre ligne personnelle.',
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
        setState(() => _selectedContactMethod = id);
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
                              fontWeight: FontWeight.bold,
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
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
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
                onChanged: (val) =>
                    setState(() => _certifyChecked = val ?? false),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Je certifie sur l’honneur que les informations fournies sont exactes, vérifiables et sincères.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                    'Tout faux signalement ou rétention abusive est passible des sanctions prévues par la réglementation civique en vigueur.',
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
