import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';
import '../../widgets/api_status_banner.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/document_utils.dart';
import '../declaration/found_document_step1_view.dart';
import '../declaration/lost_document_step1_view.dart';
import '../messages/chat_conversation_view.dart';
import '../../widgets/match_score_breakdown.dart';

/// Onglet 2 : Matches & Correspondances
/// Conforme à la maquette findmydoc_matches_liste_des_correspondances
class MatchesListView extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final int refreshToken;

  const MatchesListView({
    super.key,
    this.onNavigateToTab,
    this.refreshToken = 0,
  });

  @override
  State<MatchesListView> createState() => _MatchesListViewState();
}

class _MatchesListViewState extends State<MatchesListView> {
  String _activeFilter = 'all'; // 'all', 'new', 'progress', 'restored'
  bool _isLoading = false;
  String? _error;
  bool _offline = false;
  List<Map<String, dynamic>> _apiMatches = [];

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  @override
  void didUpdateWidget(covariant MatchesListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchMatches();
      });
    }
  }

  Future<void> _fetchMatches() async {
    // Pas d'auto-login : l'utilisateur doit se connecter via LoginView.
    if (FindsApiClient.authToken.value == null) {
      debugPrint('[MatchesListView] Aucun token : connexion requise.');
      return;
    }

    setState(() => _isLoading = true);

    // Comme citizen : `matches` est réservé aux admins, on passe donc par
    // myDeclarations puis declarationMatches pour chaque déclaration.
    try {
      final decRes = await FindsApiClient.query(
        GraphQLQueries.myDeclarationsQuery,
        variables: {
          'pagination': {'page': 1, 'pageSize': 50},
        },
      );
      _offline = FindsApiClient.isFromOfflineCache(decRes);
      _error = decRes.hasException
          ? FindsApiClient.errorMessage(decRes.exception)
          : null;
      if (decRes.hasException) {
        debugPrint('[MatchesListView] Erreur API: ${decRes.exception}');
      }
      final List declarations =
          decRes.data?['myDeclarations']?['data'] as List? ?? [];
      final withMatches = declarations
          .where((d) => ((d['matchesCount'] as int?) ?? 0) > 0)
          .toList();

      final results = await Future.wait(
        withMatches.map((d) {
          return FindsApiClient.query(
            GraphQLQueries.declarationMatchesQuery,
            variables: {'declarationId': d['id']},
          );
        }),
      );

      final seen = <String>{};
      final mapped = <Map<String, dynamic>>[];
      for (var i = 0; i < withMatches.length; i++) {
        final decl = withMatches[i] as Map<String, dynamic>;
        final List matches =
            results[i].data?['declarationMatches'] as List? ?? [];
        for (final m in matches) {
          final id = m['id'] as String?;
          if (id == null || !seen.add(id)) continue;
          if (m['statut'] == 'REJETE') continue;
          mapped.add(_mapMatch(m as Map<String, dynamic>, decl));
        }
      }

      FindsApiClient.pendingMatchesCount.value = mapped
          .where((m) => m['category'] == 'new')
          .length;
      if (mounted) {
        setState(() {
          _apiMatches = mapped;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('[MatchesListView] Erreur API: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _mapMatch(
    Map<String, dynamic> m,
    Map<String, dynamic> decl,
  ) {
    final score = ((m['score'] as num?) ?? 0).round();
    final isDeclarant = decl['type'] == 'PERTE';
    final hasConfirmed = isDeclarant
        ? m['confirmeParDeclarant'] == true
        : m['confirmeParTrouveur'] == true;

    String category;
    String statusLabel;
    Color statusColor;
    String actionLabel;
    if (decl['statut'] == 'RESOLUE') {
      category = 'restored';
      statusLabel = 'Restitué avec succès';
      statusColor = AppColors.successDeep;
      actionLabel = 'Consulter l\'archive';
    } else if (m['statut'] == 'ACCEPTE') {
      category = 'progress';
      statusLabel = 'Échange en cours';
      statusColor = AppColors.infoDark;
      actionLabel = 'Reprendre le chat';
    } else if (hasConfirmed) {
      category = 'progress';
      statusLabel = 'En attente de l\'autre partie';
      statusColor = AppColors.infoDark;
      actionLabel = 'Examiner le dossier';
    } else {
      category = 'new';
      statusLabel = 'Nouveau ($score%)';
      statusColor = AppColors.primary;
      actionLabel = 'Examiner le dossier';
    }

    final doc = _docInfo(decl['typeDocument'] as String?);
    final owner =
        '${decl['prenomProprietaire'] ?? ''} ${decl['nomProprietaire'] ?? ''}'
            .trim();
    final location = [
      decl['quartier'],
      decl['ville'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

    return {
      'id': 'MATCH-${(m['id'] as String).substring(0, 6).toUpperCase()}',
      'dbId': m['id'],
      'declarationId': decl['id'],
      'matchStatut': m['statut'],
      'hasConfirmed': hasConfirmed,
      'category': category,
      'title': doc.$2,
      'number': maskDocumentNumber(decl['numeroDocument'] as String?),
      'score': score,
      'scoreNom': m['scoreNom'],
      'scoreType': m['scoreType'],
      'scoreNumero': m['scoreNumero'],
      'scoreVille': m['scoreVille'],
      'timeAgo': relativeTime(m['createdAt'] as String?),
      'owner': owner.isNotEmpty ? owner : 'Citoyen solidaire',
      'location': location.isNotEmpty ? location : 'Lieu non précisé',
      'icon': doc.$1,
      'statusLabel': statusLabel,
      'statusColor': statusColor,
      'actionLabel': actionLabel,
      'contactName': isDeclarant ? 'Trouveur' : 'Propriétaire',
    };
  }

  static (IconData, String) _docInfo(String? type) {
    switch (type) {
      case 'PASSEPORT':
        return (Icons.menu_book_rounded, 'Passeport');
      case 'PERMIS_CONDUIRE':
        return (Icons.directions_car_rounded, 'Permis de conduire');
      case 'CARTE_GRISE':
        return (Icons.two_wheeler_rounded, 'Carte grise');
      case 'CARTE_ETUDIANT':
        return (Icons.school_rounded, 'Carte étudiant');
      case 'CARTE_PROFESSIONNELLE':
        return (Icons.work_rounded, 'Carte professionnelle');
      case 'ACTE_NAISSANCE':
        return (Icons.description_rounded, 'Acte de naissance');
      case 'CARTE_CONSULAIRE':
        return (Icons.public_rounded, 'Carte consulaire');
      case 'CERTIFICAT_NATIONALITE':
        return (Icons.verified_user_rounded, 'Certificat de nationalité');
      case 'AUTRE':
        return (Icons.insert_drive_file_rounded, 'Autre document');
      case 'CNI':
      default:
        return (Icons.badge_rounded, 'Carte Nationale d\'Identité (CNI)');
    }
  }

  List<Map<String, dynamic>> get _filteredMatches {
    if (_activeFilter == 'all') return _apiMatches;
    return _apiMatches.where((m) => m['category'] == _activeFilter).toList();
  }

  Future<void> _validateRestitution(Map<String, dynamic> item) async {
    final result = await FindsApiClient.mutate(
      GraphQLQueries.confirmMatchMutation,
      variables: {'matchId': item['dbId'].toString()},
    );
    final ok = result.data?['confirmMatch']?['success'] == true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.primary : AppColors.warning,
        content: Text(
          ok
              ? (result.data?['confirmMatch']?['message'] as String? ??
                    'Correspondance confirmée.')
              : FindsApiClient.errorMessage(
                  result.exception,
                  fallback:
                      result.data?['confirmMatch']?['message'] as String? ??
                      'Confirmation impossible.',
                ),
        ),
      ),
    );
    if (ok) _fetchMatches();
  }

  Future<void> _rejectMatch(Map<String, dynamic> item) async {
    final result = await FindsApiClient.mutate(
      GraphQLQueries.rejectMatchMutation,
      variables: {'matchId': item['dbId'].toString()},
    );
    final ok = result.data?['rejectMatch']?['success'] == true;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Correspondance écartée. Le moteur continue ses recherches.'
              : FindsApiClient.errorMessage(
                  result.exception,
                  fallback: 'Impossible d\'écarter cette correspondance.',
                ),
        ),
      ),
    );
    if (ok) _fetchMatches();
  }

  Future<void> _openConversation(Map<String, dynamic> item) async {
    final res = await FindsApiClient.query(
      GraphQLQueries.conversationByMatchIdQuery,
      variables: {'matchId': item['dbId'].toString()},
    );
    final convId = res.data?['conversationByMatchId']?['id'] as String?;
    if (!mounted) return;
    if (convId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La messagerie s\'ouvre quand les deux parties ont confirmé la correspondance.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationView(
          conversationId: convId,
          contactName: item['contactName'] as String,
          docTag: item['title'] as String,
        ),
      ),
    );
  }

  void _showMatchDetails(Map<String, dynamic> item) {
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

                  // Match header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textStrong,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['number'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: AppColors.textSubtle,
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
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${item['score']}% de concordance',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (MatchCriterion.hasAny(item)) ...[
                    MatchScoreBreakdown(match: item),
                    const SizedBox(height: 12),
                  ],

                  // Cross check detail card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RAPPROCHEMENT IA',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSubtle,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Perdu ↔ Trouvé',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: AppColors.textSubtle,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Titulaire présumé : ${item['owner']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: AppColors.textSubtle,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['location'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSubtle,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons (Pill shaped StadiumBorder)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openConversation(item);
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: const Text(
                        'Contacter via la messagerie sécurisée',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  if (item['matchStatut'] == 'EN_ATTENTE' &&
                      item['hasConfirmed'] != true) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _validateRestitution(item);
                            },
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              'Confirmer',
                              style: TextStyle(
                                fontSize: 12.5,
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
                              _rejectMatch(item);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.error,
                            ),
                            label: const Text(
                              'Rejeter',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.error,
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
    final filtered = _filteredMatches;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchMatches,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSizes.paddingPage,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Matching Engine Banner
                      ApiStatusBanner(
                        error: _error,
                        offline: _offline,
                        onRetry: _fetchMatches,
                      ),
                      _buildEngineBanner(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // Filter Chips
                      _buildFilterChips(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // Matches list or Empty State
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
                              const SizedBox(height: AppSizes.spaceSm),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildMatchCard(item);
                          },
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
        vertical: AppSizes.spaceSm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Matchs',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Pastille calée à droite (largeur limitée pour les grands textes).
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 3.5,
                    backgroundColor: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${_filteredMatches.length} détectés',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Moteur de rapprochement Finds',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_apiMatches.length} correspondances proposées automatiquement à partir du type de document, du nom, du numéro et de la ville.',
                  style: const TextStyle(
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

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Tous', 'count': _apiMatches.length},
      {
        'key': 'new',
        'label': 'Nouveaux',
        'count': _apiMatches.where((m) => m['category'] == 'new').length,
      },
      {
        'key': 'progress',
        'label': 'En cours',
        'count': _apiMatches.where((m) => m['category'] == 'progress').length,
      },
      {
        'key': 'restored',
        'label': 'Clôturés',
        'count': _apiMatches.where((m) => m['category'] == 'restored').length,
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
                _fetchMatches();
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

  Widget _buildMatchCard(Map<String, dynamic> item) {
    return InkWell(
      onTap: () => _showMatchDetails(item),
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
            // Top row: icon + title + score
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
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
                        item['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['number'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '${item['score']} %',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['timeAgo'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (MatchCriterion.hasAny(item)) ...[
              const SizedBox(height: 10),
              MatchScoreChips(match: item),
            ],
            const SizedBox(height: 12),

            // Context card
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: AppColors.textSubtle,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Titulaire présumé : ${item['owner']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.textSubtle,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item['location'] as String,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSubtle,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Bottom action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['statusLabel'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item['statusColor'] as Color,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          item['actionLabel'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDeclaration(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _fetchMatches();
  }

  Widget _buildEmptyState() {
    final noMatchAtAll = _apiMatches.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              Icons.handshake_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            noMatchAtAll
                ? 'Aucun match pour l\'instant'
                : 'Aucun match dans cette section',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            noMatchAtAll
                ? 'Un match apparaît quand une déclaration de perte correspond à un document trouvé. Déclarez votre document pour lancer la recherche.'
                : 'Essayez un autre filtre pour voir vos autres matchs.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSubtle),
            textAlign: TextAlign.center,
          ),
          if (noMatchAtAll) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openDeclaration(const LostDocumentStep1View()),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(
                'Déclarer un document perdu',
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: const StadiumBorder(),
              ),
            ),
            TextButton(
              onPressed: () => _openDeclaration(const FoundDocumentStep1View()),
              child: const Text('J\'ai trouvé un document'),
            ),
          ] else ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => _activeFilter = 'all'),
              child: const Text('Voir tous les matchs'),
            ),
          ],
        ],
      ),
    );
  }
}
