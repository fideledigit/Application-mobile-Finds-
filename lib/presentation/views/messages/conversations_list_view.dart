import 'package:flutter/material.dart';
import '../../widgets/api_status_banner.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'chat_conversation_view.dart';

/// Onglet 3 : Messagerie sécurisée Finds
/// Conforme à la maquette findmydoc_messages_liste_des_conversations
class ConversationsListView extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final int refreshToken;

  const ConversationsListView({
    super.key,
    this.onNavigateToTab,
    this.refreshToken = 0,
  });

  @override
  State<ConversationsListView> createState() => _ConversationsListViewState();
}

class _ConversationsListViewState extends State<ConversationsListView> {
  String _activeFilter = 'all'; // 'all', 'unread', 'done'
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  @override
  void didUpdateWidget(covariant ConversationsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchConversations();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;
  String? _error;
  bool _offline = false;

  static String _shortTime(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (now.difference(d).inDays < 2) return 'Hier';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchConversations() async {
    if (!FindsApiClient.isAuthenticated) return;
    setState(() => _isLoading = true);

    final res = await FindsApiClient.query(
      GraphQLQueries.myConversationsQuery,
      variables: {
        'pagination': {'page': 1, 'pageSize': 50},
      },
    );
    if (!mounted) return;
    _offline = FindsApiClient.isFromOfflineCache(res);
    _error = res.hasException
        ? FindsApiClient.errorMessage(res.exception)
        : null;
    if (res.hasException) {
      debugPrint('[Conversations] Erreur API : ${res.exception}');
    }

    final myId = FindsApiClient.currentUser.value?['id'];
    final List raw = res.data?['myConversations']?['data'] as List? ?? [];
    final mapped = raw.map<Map<String, dynamic>>((c) {
      final participants = c['participants'] as List? ?? [];
      Map<String, dynamic>? me;
      Map<String, dynamic>? other;
      for (final p in participants) {
        if (p['userId'] == myId) {
          me = p as Map<String, dynamic>;
        } else {
          other = p as Map<String, dynamic>;
        }
      }
      final u = other?['user'] as Map<String, dynamic>?;
      final name = '${u?['prenom'] ?? ''} ${u?['nom'] ?? ''}'.trim();
      final messages = c['messages'] as List? ?? [];
      final last = messages.isNotEmpty ? messages.last : null;
      final unread = (me?['nombreNonLus'] as int?) ?? 0;
      final statut = c['statut'] as String?;
      final displayName = name.isNotEmpty ? name : 'Citoyen Finds';

      return {
        'id': c['id'],
        'name': displayName,
        'tag': switch (statut) {
          'RESOLUE' => 'Restitué',
          'FERMEE' => 'Fermée',
          'SIGNALEE' => 'Signalée',
          _ => 'En cours',
        },
        'time': _shortTime((last?['createdAt'] ?? c['updatedAt']) as String?),
        'lastMessage': last?['contenu'] as String? ?? 'Aucun message',
        'unreadCount': unread,
        'isOnline': false,
        'isOfficial': false,
        'avatarInitial': displayName[0].toUpperCase(),
        'avatarColor': AppColors.successDeep,
        'isRestituted': statut == 'RESOLUE',
        'isClosed': statut == 'RESOLUE' || statut == 'FERMEE',
      };
    }).toList();

    if (!res.hasException) {
      FindsApiClient.unreadMessagesCount.value = mapped.fold<int>(
        0,
        (sum, c) => sum + (c['unreadCount'] as int),
      );
    }
    setState(() {
      _conversations = mapped;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredConversations {
    var list = _conversations;
    if (_activeFilter == 'unread') {
      list = list.where((c) => (c['unreadCount'] as int) > 0).toList();
    } else if (_activeFilter == 'done') {
      list = list.where((c) => c['isClosed'] == true).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        return (c['name'] as String).toLowerCase().contains(query) ||
            (c['tag'] as String).toLowerCase().contains(query) ||
            (c['lastMessage'] as String).toLowerCase().contains(query);
      }).toList();
    }
    return list;
  }

  Future<void> _openChat(Map<String, dynamic> item) async {
    setState(() {
      item['unreadCount'] = 0;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationView(
          conversationId: item['id'] as String,
          contactName: item['name'] as String,
          docTag: item['tag'] as String,
          isOfficial: item['isOfficial'] as bool,
        ),
      ),
    );
    if (mounted) _fetchConversations();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredConversations;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchConversations,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSizes.paddingPage,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header title & count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${_conversations.length} conversation${_conversations.length > 1 ? 's' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppSizes.fontSm,
                                color: AppColors.textBody,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.spaceSm - 2,
                                vertical: AppSizes.spaceXxsm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusL,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: AppSizes.iconXxsm,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: AppSizes.spaceXxsm),
                                  Flexible(
                                    child: Text(
                                      'Confidentiel',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: AppSizes.fontXxsm + 1,
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
                      const SizedBox(height: AppSizes.spaceMd - 2),

                      // Filter chips
                      ApiStatusBanner(
                        error: _error,
                        offline: _offline,
                        onRetry: _fetchConversations,
                      ),
                      _buildFilterChips(),
                      const SizedBox(height: AppSizes.spaceMd),

                      // List of conversations
                      if (_isLoading && _conversations.isEmpty)
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
                              const SizedBox(height: AppSizes.spaceSm - 2),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildConversationItem(item);
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
      child: _isSearching
          ? Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.textSubtle,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            decoration: const InputDecoration(
                              hintText: 'Rechercher une conversation…',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSubtle,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSubtle,
                  ),
                  tooltip: 'Fermer la recherche',
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: const Text(
                          'Messagerie',
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
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSubtle,
                  ),
                  tooltip: 'Rechercher',
                  onPressed: () => setState(() => _isSearching = true),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Toutes', 'count': _conversations.length},
      {
        'key': 'unread',
        'label': 'Non lus',
        'count': _conversations
            .where((c) => (c['unreadCount'] as int) > 0)
            .length,
      },
      {
        'key': 'done',
        'label': 'Terminées',
        'count': _conversations.where((c) => c['isClosed'] == true).length,
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

  Widget _buildConversationItem(Map<String, dynamic> item) {
    final unread = (item['unreadCount'] as int) > 0;

    return InkWell(
      onTap: () => _openChat(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: unread
              ? Border.all(color: AppColors.primarySoft, width: 1.5)
              : null,
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
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: (item['avatarColor'] as Color).withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    item['avatarInitial'] as String,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: item['avatarColor'] as Color,
                    ),
                  ),
                ),
                if (item['isOnline'] == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
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
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                item['name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: AppColors.textStrong,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.chipBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['tag'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSubtle,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (item['isOfficial'] == true) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['time'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: unread
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: unread
                              ? AppColors.primary
                              : AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['lastMessage'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: unread
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: unread
                                ? AppColors.textStrong
                                : AppColors.textSubtle,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${item['unreadCount']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item['isRestituted'] == true) ...[
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: AppColors.successDark,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Restitution confirmée',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.successDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucune conversation dans cette section',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'La messagerie s\'ouvre quand vous et l\'autre personne avez confirmé un match.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSubtle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(2); // Aller aux Matches
                }
              },
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Voir mes matchs'),
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
