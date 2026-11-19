import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/document_utils.dart';
import '../../widgets/app_back_button.dart';
import '../declaration/found_document_step1_view.dart';
import '../declaration/lost_document_step1_view.dart';
import '../messages/chat_conversation_view.dart';
import 'widgets/document_detail_sheet.dart';

/// Écran de recherche multi-critères de documents
/// Conforme à la maquette findmydoc_recherche_de_documents
class DocumentSearchView extends StatefulWidget {
  const DocumentSearchView({super.key});

  @override
  State<DocumentSearchView> createState() => _DocumentSearchViewState();
}

class _DocumentSearchViewState extends State<DocumentSearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'all'; // 'all', 'lost', 'found'
  bool _isLoadingApi = false;
  List<Map<String, dynamic>> _apiDocs = [];

  Timer? _debounce;
  int _requestId = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFromApi();
    _searchController.addListener(_onSearchInputChanged);
  }

  void _onSearchInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchFromApi);
  }

  static Map<String, dynamic> _mapDeclaration(Map<String, dynamic> item) {
    final isLost = item['type'] == 'PERTE';
    final ownerName =
        '${item['prenomProprietaire'] ?? ''} ${item['nomProprietaire'] ?? ''}'
            .trim();
    final ville = item['ville'] as String? ?? '';
    final quartier = item['quartier'] as String? ?? '';
    final place = [quartier, ville].where((s) => s.isNotEmpty).join(', ');
    final statut = item['statut'] as String?;

    return {
      'id': item['id'],
      'ownerId': item['userId'],
      'name': ownerName.isNotEmpty ? ownerName : 'Titulaire non renseigné',
      'type': documentTypeLabel(item['typeDocument'] as String?),
      'typeShort': documentTypeShortLabel(item['typeDocument'] as String?),
      'category': isLost ? 'lost' : 'found',
      'location': place.isEmpty
          ? 'Lieu non précisé'
          : '${isLost ? 'Perdu à' : 'Trouvé à'} $place',
      'timeAgo': relativeTime(item['createdAt'] as String?),
      'maskedNumber': maskDocumentNumber(item['numeroDocument'] as String?),
      'badge': statut == 'RESOLUE'
          ? 'Restitué'
          : statut == 'MATCHEE'
          ? 'Correspondance'
          : (isLost ? 'Signalé' : 'Sécurisé'),
      'badgeColor': isLost ? AppColors.primary : AppColors.successDeep,
      'typeDocument': item['typeDocument'],
      'nomProprietaire': item['nomProprietaire'] ?? '',
      'prenomProprietaire': item['prenomProprietaire'] ?? '',
      'ville': ville,
      'quartier': quartier,
      'place': place,
      'statut': statut,
      'description': item['descriptionLibre'] as String? ?? '',
      'photoFlouteeUrl': item['photoFlouteeUrl'] as String?,
      'createdAt': item['createdAt'] as String?,
      'matchesCount': item['matchesCount'] as int? ?? 0,
    };
  }

  // Le serveur rapproche automatiquement une perte et une découverte :
  // on ouvre donc la déclaration inverse, pré-remplie.
  void _openMatchingDeclaration(Map<String, dynamic> doc) {
    final type = formDocumentTypeFromApi(doc['typeDocument'] as String?);
    final custom = type == 'AUTRE'
        ? documentTypeLabel(doc['typeDocument'] as String?)
        : '';
    final place = [
      doc['ville'],
      doc['quartier'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

    final Widget screen = doc['category'] == 'found'
        ? LostDocumentStep1View(
            initialData: LostDeclarationModel(
              documentType: type,
              customDocumentType: custom,
              lastName: doc['nomProprietaire'] as String,
              firstName: doc['prenomProprietaire'] as String,
              lossLocation: place,
            ),
          )
        : FoundDocumentStep1View(
            initialData: FoundDeclarationModel(
              documentType: type,
              customDocumentType: custom,
              lastName: doc['nomProprietaire'] as String,
              firstName: doc['prenomProprietaire'] as String,
              foundLocation: place,
            ),
          );
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  // Charge toutes les pages : chaque déclaration publiée est visible.
  Future<void> _fetchFromApi() async {
    final requestId = ++_requestId;
    final queryText = _searchController.text.trim();
    setState(() {
      _isLoadingApi = true;
      _errorMessage = null;
    });

    final all = <Map<String, dynamic>>[];
    var page = 1;
    var totalPages = 1;
    String? error;
    do {
      final res = await FindsApiClient.query(
        GraphQLQueries.searchDeclarationsQuery,
        variables: {
          'filter': {'search': queryText.isNotEmpty ? queryText : null},
          'pagination': {'page': page, 'pageSize': 100},
        },
      );
      if (requestId != _requestId) return;
      if (res.hasException) {
        error = FindsApiClient.errorMessage(res.exception);
        break;
      }
      final raw = res.data?['searchDeclarations'];
      final List list = raw?['data'] as List? ?? [];
      all.addAll(list.map((e) => _mapDeclaration(e as Map<String, dynamic>)));
      totalPages = raw?['meta']?['totalPages'] as int? ?? 1;
      page++;
    } while (page <= totalPages && page <= 20);

    if (!mounted || requestId != _requestId) return;
    setState(() {
      _apiDocs = all;
      _isLoadingApi = false;
      _errorMessage = error;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredResults {
    if (_activeFilter == 'all') return _apiDocs;
    return _apiDocs.where((d) => d['category'] == _activeFilter).toList();
  }

  void _showDocumentDetail(Map<String, dynamic> doc) {
    DocumentDetailSheet.show(
      context,
      doc: doc,
      onDeclare: () => _openMatchingDeclaration(doc),
      onContact: () => _contactOwner(doc),
    );
  }

  // ── Messagerie avec l'auteur de l'annonce ─────────────────────────────────

  static String _normalizeName(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Retrouve la conversation déjà ouverte avec la personne à l'origine de
  /// l'annonce (le propriétaire pour une perte, le trouveur pour une
  /// découverte). `null` tant que la correspondance n'est pas confirmée.
  Future<Map<String, dynamic>?> _findConversationWithOwner(
    Map<String, dynamic> doc,
  ) async {
    final res = await FindsApiClient.query(
      GraphQLQueries.myConversationsQuery,
      variables: {
        'pagination': {'page': 1, 'pageSize': 100},
      },
    );
    if (res.hasException) {
      debugPrint('[Recherche] Conversations indisponibles : ${res.exception}');
    }

    final myId = FindsApiClient.currentUser.value?['id'];
    final ownerId = doc['ownerId'] as String?;
    final wantedName = _normalizeName(doc['name'] as String? ?? '');
    final List raw = res.data?['myConversations']?['data'] as List? ?? [];

    for (final c in raw) {
      final participants = c['participants'] as List? ?? [];
      for (final p in participants) {
        if (p['userId'] == myId) continue;
        final u = p['user'] as Map<String, dynamic>?;
        final name = '${u?['prenom'] ?? ''} ${u?['nom'] ?? ''}'.trim();
        final sameOwner = ownerId != null && p['userId'] == ownerId;
        final sameName =
            ownerId == null &&
            wantedName.isNotEmpty &&
            _normalizeName(name) == wantedName;
        if (!sameOwner && !sameName) continue;

        final statut = c['statut'] as String?;
        return {
          'id': c['id'] as String,
          'name': name.isNotEmpty ? name : (doc['name'] as String),
          'tag': switch (statut) {
            'RESOLUE' => 'Restitué',
            'FERMEE' => 'Fermée',
            'SIGNALEE' => 'Signalée',
            _ => 'En cours',
          },
        };
      }
    }
    return null;
  }

  Future<void> _contactOwner(Map<String, dynamic> doc) async {
    if (!FindsApiClient.isAuthenticated) {
      _showMessage(
        'Connectez-vous pour discuter avec le titulaire du document.',
      );
      return;
    }

    final myId = FindsApiClient.currentUser.value?['id'];
    final isMine =
        (doc['ownerId'] != null && doc['ownerId'] == myId) ||
        _normalizeName(doc['name'] as String? ?? '') ==
            _normalizeName(FindsApiClient.userFullName);
    if (isMine) {
      _showMessage(
        'Cette annonce est la vôtre : la messagerie sert à échanger avec '
        'l\'autre personne.',
      );
      return;
    }

    BuildContext? loader;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loader = ctx;
        return const Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'Recherche de la conversation…',
                    style: TextStyle(fontSize: 13.5, color: AppColors.textBody),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Map<String, dynamic>? conversation;
    try {
      conversation = await _findConversationWithOwner(doc);
    } finally {
      if (loader != null && loader!.mounted) {
        Navigator.of(loader!).pop();
      }
    }
    if (!mounted) return;

    if (conversation == null) {
      _showMessagingLockedSheet(doc);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationView(
          conversationId: conversation!['id'] as String,
          contactName: conversation['name'] as String,
          docTag: doc['type'] as String? ?? 'Document',
        ),
      ),
    );
  }

  /// Explique pourquoi la discussion n'est pas encore ouverte et propose
  /// directement la déclaration qui la débloquera.
  void _showMessagingLockedSheet(Map<String, dynamic> doc) {
    final isLost = doc['category'] == 'lost';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          16 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'La messagerie s\'ouvre après la correspondance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLost
                  ? 'Pour protéger les deux parties, Finds active la discussion '
                        'sécurisée uniquement quand la découverte est confirmée. '
                        'Déclarez que vous avez trouvé ce document : vous serez '
                        'alors mis en relation avec son propriétaire.'
                  : 'Pour protéger les deux parties, Finds active la discussion '
                        'sécurisée uniquement quand la perte est confirmée. '
                        'Déclarez la perte de ce document : vous serez alors '
                        'mis en relation avec la personne qui l\'a trouvé.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _openMatchingDeclaration(doc);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Déclarer maintenant',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSubtle,
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text(
                'Plus tard',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            _buildSearchBar(),

            // Filter Chips
            _buildFilterChips(),

            // Results Counter
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd,
                vertical: AppSizes.spaceXsm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${results.length} document${results.length > 1 ? 's' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppSizes.fontXsm,
                        color: AppColors.textSubtle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceXsm),
                  const Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: AppSizes.iconXsm,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: AppSizes.spaceXxsm),
                        Flexible(
                          child: Text(
                            'Numéros masqués',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppSizes.fontXxsm + 1.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: _isLoadingApi && results.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _errorMessage != null && results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSubtle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _fetchFromApi,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : results.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spaceMd,
                        vertical: 6,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSizes.spaceSm - 2),
                      itemBuilder: (context, index) {
                        final doc = results[index];
                        return _buildDocumentCard(doc);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceMd,
        vertical: AppSizes.spaceSm - 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: AppSizes.spaceXsm),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSizes.buttonHeightSm + 6,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceSm),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSubtle,
                    size: AppSizes.iconMd,
                  ),
                  const SizedBox(width: AppSizes.spaceXsm),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un document (nom, lieu…)',
                        hintStyle: TextStyle(
                          fontSize: AppSizes.fontSm,
                          color: AppColors.textSubtle,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_isLoadingApi)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (_searchController.text.isNotEmpty)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSubtle,
                      ),
                      onPressed: () {
                        setState(() => _searchController.clear());
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Tous', 'count': _apiDocs.length},
      {
        'key': 'lost',
        'label': 'Perdus',
        'count': _apiDocs.where((d) => d['category'] == 'lost').length,
      },
      {
        'key': 'found',
        'label': 'Trouvés',
        'count': _apiDocs.where((d) => d['category'] == 'found').length,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final isLost = doc['category'] == 'lost';

    return InkWell(
      onTap: () => _showDocumentDetail(doc),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isLost
                              ? AppColors.errorSoft
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isLost ? 'PERDU' : 'TROUVÉ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isLost
                                ? AppColors.errorDark
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.chipBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          doc['typeShort'] as String? ?? doc['type'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      doc['timeAgo'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 3),
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
                              doc['location'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSubtle,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doc['maskedNumber'] as String,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSubtle,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              Icons.search_off_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasQuery ? 'Aucun document trouvé' : 'Aucune déclaration publiée',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'Personne n\'a encore signalé ce document. Déclarez sa perte : vous serez prévenu dès qu\'il sera trouvé.'
                : 'Déclarez votre document perdu : vous serez prévenu dès qu\'un document correspondant sera signalé.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSubtle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LostDocumentStep1View()),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              'Déclarer un document perdu',
              textAlign: TextAlign.center,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: const StadiumBorder(),
            ),
          ),
          if (hasQuery)
            TextButton(
              onPressed: () => setState(() => _searchController.clear()),
              child: const Text('Effacer la recherche'),
            ),
        ],
      ),
    );
  }
}
