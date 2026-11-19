import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';
import '../../widgets/api_status_banner.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../widgets/app_back_button.dart';
import '../messages/chat_conversation_view.dart';
import 'notification_detail_view.dart';

/// Écran des notifications civiques Finds
/// Conforme à la maquette findmydoc_notifications
class NotificationsListView extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const NotificationsListView({super.key, this.onNavigateToTab});

  @override
  State<NotificationsListView> createState() => _NotificationsListViewState();
}

class _NotificationsListViewState extends State<NotificationsListView> {
  String _activeFilter = 'all';
  bool _isLoading = true;
  String? _error;
  bool _offline = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final res = await FindsApiClient.query(
      GraphQLQueries.myNotificationsQuery,
      variables: {
        'pagination': {'page': 1, 'pageSize': 50},
      },
    );
    if (!mounted) return;
    if (res.hasException) {
      debugPrint('[Notifications] Erreur API : ${res.exception}');
    }
    final List raw = res.data?['myNotifications']?['data'] as List? ?? [];
    setState(() {
      _offline = FindsApiClient.isFromOfflineCache(res);
      _error = res.hasException
          ? FindsApiClient.errorMessage(res.exception)
          : null;
      _notifications = raw
          .map((n) => _mapNotification(n as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  static Map<String, dynamic> _mapNotification(Map<String, dynamic> n) {
    final type = n['type'] as String? ?? '';
    String category;
    String badge;
    IconData icon;
    Color iconColor;
    Color iconBg;
    int tabTarget;

    switch (type) {
      case 'MATCH_TROUVE':
      case 'MATCH_ACCEPTE':
      case 'MATCH_REJETE':
        category = 'match';
        badge = type == 'MATCH_TROUVE'
            ? 'Action requise'
            : type == 'MATCH_ACCEPTE'
            ? 'Accepté'
            : 'Rejeté';
        icon = Icons.compare_arrows_rounded;
        iconColor = AppColors.primary;
        iconBg = AppColors.primarySoft;
        tabTarget = 2;
      case 'NOUVEAU_MESSAGE':
      case 'CONVERSATION_RESOLUE':
        category = 'message';
        badge = 'Message';
        icon = Icons.forum_rounded;
        iconColor = AppColors.infoDark;
        iconBg = AppColors.infoSoft;
        tabTarget = 3;
      case 'REMERCIEMENT_TROUVEUR':
      case 'EVALUATION_RECUE':
        category = 'restitution';
        badge = 'Restitution';
        icon = Icons.verified_rounded;
        iconColor = AppColors.successDark;
        iconBg = AppColors.primarySoft;
        tabTarget = 1;
      default:
        category = 'alert';
        badge = type == 'BIENVENUE' ? 'Bienvenue' : 'Info';
        icon = Icons.notifications_active_rounded;
        iconColor = AppColors.primary;
        iconBg = AppColors.primarySoft;
        tabTarget = 1;
    }

    return {
      'id': n['id'],
      'type': type,
      'donnees': n['donnees'],
      'category': category,
      'title': n['titre'] as String? ?? '',
      'description': n['corps'] as String? ?? '',
      'time': relativeTime(n['createdAt'] as String?),
      'createdAt': n['createdAt'],
      'isUnread': n['statut'] != 'LUE',
      'badge': badge,
      'icon': icon,
      'iconColor': iconColor,
      'iconBg': iconBg,
      'tabTarget': tabTarget,
    };
  }

  List<Map<String, dynamic>> get _filteredNotifs {
    if (_activeFilter == 'all') return _notifications;
    return _notifications.where((n) => n['category'] == _activeFilter).toList();
  }

  Future<void> _markAllAsRead() async {
    final res = await FindsApiClient.mutate(
      GraphQLQueries.markAllNotificationsReadMutation,
    );
    if (!mounted) return;
    final ok = res.data?['markAllNotificationsRead']?['success'] == true;
    if (ok) {
      setState(() {
        for (final n in _notifications) {
          n['isUnread'] = false;
        }
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Toutes les notifications marquées comme lues.'
              : FindsApiClient.errorMessage(res.exception),
        ),
      ),
    );
  }

  Future<void> _handleTapNotification(Map<String, dynamic> item) async {
    if (item['isUnread'] == true) {
      setState(() => item['isUnread'] = false);
      FindsApiClient.mutate(
        GraphQLQueries.markNotificationReadMutation,
        variables: {'notificationId': item['id']},
      );
    }

    final type = item['type'] as String;

    // Message de l'admin, bienvenue, rappel… : on affiche le texte en entier
    // au lieu d'envoyer vers un autre onglet.
    if (NotificationDetailView.isInformational(type)) {
      await NotificationDetailView.open(context, item);
      return;
    }

    final data = item['donnees'];
    String? conversationId;
    if (data is Map) {
      conversationId = data['conversationId'] as String?;
      final matchId = data['matchId'] as String?;
      if (type == 'MATCH_ACCEPTE' && matchId != null) {
        final res = await FindsApiClient.query(
          GraphQLQueries.conversationByMatchIdQuery,
          variables: {'matchId': matchId},
        );
        conversationId = res.data?['conversationByMatchId']?['id'] as String?;
      }
    }

    if (!mounted) return;
    if (conversationId != null &&
        (type == 'MATCH_ACCEPTE' ||
            type == 'NOUVEAU_MESSAGE' ||
            type == 'CONVERSATION_RESOLUE')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatConversationView(conversationId: conversationId!),
        ),
      );
      return;
    }

    final targetTab = item['tabTarget'] as int?;
    if (targetTab != null && widget.onNavigateToTab != null) {
      Navigator.of(context).pop();
      widget.onNavigateToTab!(targetTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifs;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildFilterChips(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd),
              child: ApiStatusBanner(
                error: _error,
                offline: _offline,
                onRetry: _fetchNotifications,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      color: AppColors.primary,
                      child: filtered.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Center(child: _buildEmptyState()),
                                    ),
                                  ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.spaceMd,
                                vertical: AppSizes.spaceXsm,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSizes.spaceSm - 2),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return _buildNotificationCard(item);
                              },
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
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: AppSizes.spaceSm - 2),
          const Expanded(
            child: Text(
              'Notifications',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
              ),
            ),
          ),
          Flexible(
            child: TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(
                Icons.done_all_rounded,
                size: AppSizes.iconSm - 2,
                color: AppColors.primary,
              ),
              label: const Text(
                'Tout marquer lu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppSizes.fontXsm,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Toutes', 'count': _notifications.length},
      {
        'key': 'match',
        'label': 'Matchs',
        'count': _notifications.where((n) => n['category'] == 'match').length,
      },
      {
        'key': 'message',
        'label': 'Messages',
        'count': _notifications.where((n) => n['category'] == 'message').length,
      },
      {
        'key': 'restitution',
        'label': 'Restitutions',
        'count': _notifications
            .where((n) => n['category'] == 'restitution')
            .length,
      },
      {
        'key': 'alert',
        'label': 'Alertes',
        'count': _notifications.where((n) => n['category'] == 'alert').length,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => setState(() => _activeFilter = f['key'] as String),
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

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final unread = item['isUnread'] == true;

    return InkWell(
      onTap: () => _handleTapNotification(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread
              ? AppColors.primarySoft.withValues(alpha: 0.4)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: unread
              ? Border.all(color: AppColors.primarySoft, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item['iconBg'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: item['iconColor'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unread
                                ? FontWeight.w800
                                : FontWeight.bold,
                            color: AppColors.textStrong,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] as String,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textBody,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: AppColors.textSubtle,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item['time'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSubtle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.chipBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['badge'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSubtle,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primarySoft,
            child: Icon(
              Icons.notifications_off_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucune notification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vous êtes à jour ! Dès qu\'une activité concerne vos pièces, vous recevrez une alerte.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSubtle),
            textAlign: TextAlign.center,
          ),
          if (widget.onNavigateToTab != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onNavigateToTab!(1);
              },
              icon: const Icon(Icons.description_outlined, size: 18),
              label: Text('Voir mes déclarations', textAlign: TextAlign.center),
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
          ],
        ],
      ),
    );
  }
}
