import 'package:flutter/material.dart';
import '../../widgets/api_status_banner.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/document_utils.dart';
import '../../../core/services/receipt_pdf_service.dart';
import '../../../core/services/share_service.dart';
import '../auth/login_view.dart';
import '../declaration/declaration_type_choice_view.dart';

/// Onglet 1 : Mes Déclarations
/// Conforme à la maquette findmydoc_mes_d_clarations
class DeclarationsListView extends StatefulWidget {
  final VoidCallback? onNewDeclarationTap;
  final ValueChanged<int>? onNavigateToTab;
  final int refreshToken;

  const DeclarationsListView({
    super.key,
    this.onNewDeclarationTap,
    this.onNavigateToTab,
    this.refreshToken = 0,
  });

  @override
  State<DeclarationsListView> createState() => _DeclarationsListViewState();
}

class _DeclarationsListViewState extends State<DeclarationsListView> {
  String _activeFilter = 'all'; // 'all', 'perdu', 'trouve', 'restitue'
  bool _isLoading = false;
  String? _error;
  bool _offline = false;
  List<Map<String, dynamic>> _apiDeclarations = [];

  @override
  void initState() {
    super.initState();
    _fetchDeclarations();
    FindsApiClient.declarationsRevision.addListener(_onRevisionChanged);
  }

  @override
  void dispose() {
    FindsApiClient.declarationsRevision.removeListener(_onRevisionChanged);
    super.dispose();
  }

  void _onRevisionChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchDeclarations();
      }
    });
  }

  @override
  void didUpdateWidget(covariant DeclarationsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharge la liste à chaque retour sur l'onglet Déclarations.
    if (oldWidget.refreshToken != widget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchDeclarations();
        }
      });
    }
  }

  Future<void> _fetchDeclarations() async {
    // Pas d'auto-login : l'utilisateur doit se connecter via LoginView.
    if (FindsApiClient.authToken.value == null) {
      debugPrint('[DeclarationsListView] Aucun token : connexion requise.');
      if (mounted) {
        setState(() {
          _apiDeclarations = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final res = await FindsApiClient.query(
        GraphQLQueries.myDeclarationsQuery,
        variables: const {
          'pagination': {'page': 1, 'pageSize': 50},
        },
      );

      _error = res.hasException && !FindsApiClient.isFromOfflineCache(res)
          ? FindsApiClient.errorMessage(res.exception)
          : null;
      _offline = FindsApiClient.isFromOfflineCache(res);
      final myDec = res.data?['myDeclarations'];
      if (myDec != null) {
        final List list = myDec is Map
            ? (myDec['data'] as List? ?? [])
            : (myDec is List ? myDec : []);

        final mapped = list.map<Map<String, dynamic>>((raw) {
          final item = raw is Map ? raw : <String, dynamic>{};
          final rawType = (item['type'] ?? item['category'] ?? 'PERTE')
              .toString()
              .toUpperCase();
          final status = (item['statut'] ?? item['status'] ?? 'ACTIVE')
              .toString()
              .toUpperCase();

          String cat = 'perdu';
          if (rawType == 'TROUVAILLE' || rawType == 'TROUVE') {
            cat = 'trouve';
          }
          if (status == 'RESOLUE' || status == 'RESTORED') {
            cat = 'restitue';
          }

          final matchesCount = (item['matchesCount'] is num)
              ? (item['matchesCount'] as num).toInt()
              : 0;
          final hasMatch =
              status == 'MATCHEE' || status == 'MATCHED' || matchesCount > 0;

          String label = 'En recherche active';
          Color color = AppColors.infoDark;
          Color bg = AppColors.infoSoft;

          if (hasMatch) {
            label = matchesCount > 0
                ? '$matchesCount correspondance(s) potentielle(s)'
                : 'Correspondance potentielle identifiée';
            color = AppColors.primary;
            bg = AppColors.primarySoft;
          } else if (cat == 'restitue') {
            label = 'Restitué avec succès';
            color = AppColors.successDeep;
            bg = AppColors.primarySoft;
          } else if (cat == 'perdu') {
            label = 'En attente de signalement';
            color = AppColors.textSubtle;
            bg = AppColors.chipBackground;
          }

          final docType =
              (item['typeDocument'] ?? item['documentType'] ?? 'CNI')
                  .toString()
                  .toUpperCase();

          IconData icon = Icons.badge_rounded;
          String docLabel = 'Document officiel';

          if (docType == 'CNI') {
            icon = Icons.badge_rounded;
            docLabel = 'Carte Nationale d\'Identité (CNI)';
          } else if (docType == 'PASSEPORT' || docType == 'PASSPORT') {
            icon = Icons.menu_book_rounded;
            docLabel = 'Passeport';
          } else if (docType == 'PERMIS_CONDUIRE' || docType == 'PERMIS') {
            icon = Icons.directions_car_rounded;
            docLabel = 'Permis de Conduire';
          } else if (docType == 'CARTE_ETUDIANT' || docType == 'STUDENT') {
            icon = Icons.school_rounded;
            docLabel = 'Carte d\'Étudiant';
          } else if (docType == 'CARTE_GRISE' || docType == 'GRISE') {
            icon = Icons.two_wheeler_rounded;
            docLabel = 'Carte Grise';
          } else if (docType == 'ACTE_NAISSANCE') {
            icon = Icons.description_rounded;
            docLabel = 'Acte de Naissance';
          } else if (docType == 'CERTIFICAT_NATIONALITE') {
            icon = Icons.verified_user_rounded;
            docLabel = 'Certificat de Nationalité';
          } else if (docType == 'CARTE_CONSULAIRE') {
            icon = Icons.public_rounded;
            docLabel = 'Carte Consulaire';
          } else if (docType == 'CARTE_PROFESSIONNELLE') {
            icon = Icons.work_rounded;
            docLabel = 'Carte Professionnelle';
          }

          if (item['customDocumentType'] != null &&
              item['customDocumentType'].toString().isNotEmpty) {
            docLabel = item['customDocumentType'].toString();
          }

          final dateStr = item['createdAt']?.toString();
          String displayDate = 'Récent';
          if (dateStr != null && dateStr.isNotEmpty) {
            try {
              final d = DateTime.parse(dateStr);
              displayDate =
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
            } catch (_) {}
          }

          final ville =
              item['ville']?.toString() ??
              item['eventLocation']?.toString() ??
              'Lomé';
          final quartier = item['quartier']?.toString() ?? '';
          final location = quartier.isNotEmpty ? '$ville, $quartier' : ville;

          return {
            'id':
                (item['reference'] ??
                        'DEC-${item['id'].toString().substring(0, item['id'].toString().length.clamp(0, 8)).toUpperCase()}')
                    .toString(),
            'category': cat,
            'type': docLabel,
            'number': maskDocumentNumber(item['numeroDocument']?.toString()),
            'date': displayDate,
            'location': location,
            'icon': icon,
            'status': label,
            'statusColor': color,
            'statusBg': bg,
            'hasMatch': hasMatch,
            'photoUrl': item['photoUrl']?.toString(),
            'pdfUrl': item['pdfUrl']?.toString(),
            'dbId': item['id']?.toString(),
            'statut': status,
            'matchesCount': matchesCount,
          };
        }).toList();

        debugPrint(
          '[DeclarationsListView] ${mapped.length} déclaration(s) '
          'chargée(s) depuis ${FindsApiClient.endpoint}',
        );

        if (mounted) {
          setState(() {
            _apiDeclarations = mapped;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[DeclarationsListView] Erreur API: $e');
      _error = 'Une erreur est survenue.';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredDeclarations {
    if (_activeFilter == 'all') return _apiDeclarations;
    return _apiDeclarations
        .where((d) => d['category'] == _activeFilter)
        .toList();
  }

  void _openNewDeclaration() {
    if (widget.onNewDeclarationTap != null) {
      widget.onNewDeclarationTap!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DeclarationTypeChoiceView()),
      );
    }
  }

  ReceiptData _receiptFor(Map<String, dynamic> item) {
    final category = (item['category'] as String? ?? 'perdu').toUpperCase();
    return ReceiptData(
      reference: item['id'] as String? ?? 'DEC-INCONNU',
      category: category,
      documentType: item['type'] as String? ?? 'Document officiel',
      documentNumber: item['number'] as String? ?? '',
      eventDate: item['date'] as String? ?? '',
      eventLocation: item['location'] as String? ?? '',
      declarantName: FindsApiClient.userFullName,
    );
  }

  Future<void> _shareDeclaration(Map<String, dynamic> item) async {
    final isPerdu = item['category'] == 'perdu';
    final isRestitue = item['category'] == 'restitue';
    final header = isRestitue
        ? '✅ DOCUMENT RESTITUÉ — Finds'
        : (isPerdu
              ? '🚨 DOCUMENT PERDU — Finds'
              : '🔎 DOCUMENT TROUVÉ — Finds');

    final message =
        '$header\n'
        'Type : ${item['type']}\n'
        'Référence : ${item['id']}\n'
        'Lieu : ${item['location']}\n'
        'Date : ${item['date']}\n\n'
        'Déclaration enregistrée sur la plateforme civique Finds. '
        'Merci de partager ce message pour faciliter la restitution.';

    final ok = await ShareService.shareOnWhatsApp(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.whatsapp : AppColors.error,
        content: Text(
          ok
              ? 'Partage WhatsApp prêt à être envoyé !'
              : 'Impossible d\'ouvrir WhatsApp sur cet appareil.',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _shareDeclarationPdf(Map<String, dynamic> item) async {
    try {
      final ok = await ReceiptPdfService.share(_receiptFor(item));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppColors.primary : AppColors.error,
          content: Text(
            ok
                ? 'Récépissé PDF généré : choisissez « Enregistrer » ou partagez-le.'
                : 'Impossible de générer le récépissé PDF.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('[DeclarationsListView] Erreur PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Erreur lors de la génération du PDF.'),
        ),
      );
    }
  }

  Future<void> _confirmMarkResolved(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Document restitué ?'),
        content: const Text(
          'Confirmez que ce document a bien été restitué. '
          'La déclaration sera clôturée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await FindsApiClient.mutate(
      GraphQLQueries.markDeclarationResolvedMutation,
      variables: {'declarationId': item['dbId']},
    );
    if (!mounted) return;
    final data = res.data?['markDeclarationResolved'];
    final ok = data?['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.primary : AppColors.error,
        content: Text(
          ok
              ? (data?['message'] as String? ??
                    'Déclaration marquée comme restituée.')
              : FindsApiClient.errorMessage(
                  res.exception,
                  fallback:
                      data?['message'] as String? ??
                      'Impossible de clôturer la déclaration.',
                ),
        ),
      ),
    );
    if (ok) FindsApiClient.declarationsRevision.value++;
  }

  void _showDeclarationDetailModal(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Builder(
          builder: (_) {
            final isPerdu = item['category'] == 'perdu';
            final isRestitue = item['category'] == 'restitue';

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title and badge
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isPerdu
                                    ? AppColors.errorSoft
                                    : (isRestitue
                                          ? AppColors.primarySoft
                                          : AppColors.infoSoft),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: isPerdu
                                    ? AppColors.error
                                    : AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['id'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSubtle,
                                    ),
                                  ),
                                  Text(
                                    item['type'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPerdu
                              ? AppColors.errorSoft
                              : (isRestitue
                                    ? AppColors.primarySoft
                                    : AppColors.infoSoft),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (item['category'] as String).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPerdu
                                ? AppColors.errorDark
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: const Text(
                                'Numéro masqué :',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSubtle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item['number'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: const Text(
                                'Date signalée :',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSubtle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                item['date'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
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
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item['location'],
                                style: const TextStyle(
                                  fontSize: 12,
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
                  const SizedBox(height: 18),

                  // Match action if available
                  if (item['hasMatch'] == true) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          if (widget.onNavigateToTab != null) {
                            widget.onNavigateToTab!(2); // Onglet Matches
                          }
                        },
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          'Voir les correspondances (${item['matchesCount'] ?? 0})',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (item['dbId'] != null &&
                      (item['statut'] == 'ACTIVE' ||
                          item['statut'] == 'MATCHEE')) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _confirmMarkResolved(item);
                        },
                        icon: const Icon(
                          Icons.task_alt_rounded,
                          size: 18,
                          color: AppColors.successDark,
                        ),
                        label: const Text(
                          'Marquer comme restitué',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.successDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: const BorderSide(color: AppColors.successDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Secondary actions: Share & PDF
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _shareDeclaration(item);
                          },
                          icon: const Icon(
                            Icons.share_rounded,
                            size: 16,
                            color: AppColors.whatsapp,
                          ),
                          label: const Text(
                            'WhatsApp',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textStrong,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _shareDeclarationPdf(item);
                          },
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          label: const Text(
                            'Récépissé',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textStrong,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDeclarations;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDeclarations,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSizes.paddingPage,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ApiStatusBanner(
                        error: _error,
                        offline: _offline,
                        onRetry: _fetchDeclarations,
                      ),
                      // Filter Chips (Pill shaped, no borders)
                      _buildFilterChips(),
                      const SizedBox(height: 16),

                      // Declarations list or Empty State
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildDeclarationCard(item);
                          },
                        ),
                      const SizedBox(height: 28),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Déclarations',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openNewDeclaration,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Toutes', 'count': _apiDeclarations.length},
      {
        'key': 'perdu',
        'label': 'Perdus',
        'count': _apiDeclarations.where((d) => d['category'] == 'perdu').length,
      },
      {
        'key': 'trouve',
        'label': 'Trouvés',
        'count': _apiDeclarations
            .where((d) => d['category'] == 'trouve')
            .length,
      },
      {
        'key': 'restitue',
        'label': 'Restitués',
        'count': _apiDeclarations
            .where((d) => d['category'] == 'restitue')
            .length,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() => _activeFilter = f['key'] as String);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textBody,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.chipBadge,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${f['count']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSubtle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeclarationCard(Map<String, dynamic> item) {
    final isPerdu = item['category'] == 'perdu';
    final isRestitue = item['category'] == 'restitue';

    return InkWell(
      onTap: () => _showDeclarationDetailModal(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPerdu
                    ? AppColors.errorSoft
                    : (isRestitue ? AppColors.primarySoft : AppColors.infoSoft),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: isPerdu ? AppColors.errorDark : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPerdu
                                ? AppColors.errorSoft
                                : (isRestitue
                                      ? AppColors.primarySoft
                                      : AppColors.infoSoft),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (item['category'] as String).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isPerdu
                                  ? AppColors.errorDark
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item['date'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['type'],
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['number'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.textSubtle,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['location'],
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSubtle,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item['statusBg'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item['hasMatch'] == true) ...[
                          const Icon(
                            Icons.radar_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            item['status'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item['statusColor'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSubtle,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isNotLoggedIn = FindsApiClient.authToken.value == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isNotLoggedIn ? AppColors.infoSoft : AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNotLoggedIn
                  ? Icons.lock_outline_rounded
                  : Icons.folder_open_rounded,
              color: isNotLoggedIn ? AppColors.infoDark : AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isNotLoggedIn
                ? 'Connexion requise'
                : 'Aucune déclaration dans cette catégorie',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isNotLoggedIn
                ? 'Connectez-vous à votre compte citoyen pour retrouver et suivre vos déclarations en temps réel.'
                : 'Vous n\'avez actuellement aucun document enregistré sous ce filtre.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSubtle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          if (isNotLoggedIn)
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginView()));
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Se connecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            )
          else
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _openNewDeclaration,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Faire une déclaration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
