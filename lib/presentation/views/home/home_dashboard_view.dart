import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/photo_service.dart';
import '../notifications/notifications_list_view.dart';
import '../search/document_search_view.dart';
import '../notifications/notification_detail_view.dart';

/// Page d'accueil / Dashboard citoyen (Finds)
/// Conforme aux maquettes officielles (findmydoc_accueil_dashboard & findmydoc_accueil_tat_vide)
class HomeDashboardView extends StatefulWidget {
  final VoidCallback? onNewDeclarationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final void Function(int tabIndex)? onNavigateToTab;

  /// Incrémenté par l'écran principal pour forcer un rechargement
  /// (retour sur l'onglet Accueil, nouvelle déclaration…).
  final int refreshToken;

  const HomeDashboardView({
    super.key,
    this.onNewDeclarationTap,
    this.onSearchTap,
    this.onNotificationsTap,
    this.onNavigateToTab,
    this.refreshToken = 0,
  });

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView>
    with WidgetsBindingObserver {
  /// Défilement du contenu sous l'app bar fixe : sert à afficher une ombre
  /// sous la barre dès que le contenu passe dessous.
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  final PageController _stepPageController = PageController(
    viewportFraction: 0.88,
  );
  int _currentStepIndex = 0;

  int _declarationsCount = 0;
  int _matchesCount = 0;
  int _restoredCount = 0;
  int _unreadNotifications = 0;
  List<Map<String, dynamic>> _activities = [];

  /// Les correspondances et les messages arrivent côté serveur sans que
  /// l'utilisateur ne fasse rien : on recharge régulièrement l'activité.
  static const Duration _autoRefreshEvery = Duration(seconds: 30);
  Timer? _autoRefresh;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _fetchDashboardData();
    _autoRefresh = Timer.periodic(
      _autoRefreshEvery,
      (_) => _fetchDashboardData(),
    );
  }

  void _onScroll() {
    final scrolled =
        _scrollController.hasClients && _scrollController.offset > 4;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  @override
  void didUpdateWidget(covariant HomeDashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _fetchDashboardData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retour dans l'app (après une notification, un autre appli…).
    if (state == AppLifecycleState.resumed) _fetchDashboardData();
  }

  // Même source que l'accueil de citizen : myDeclarations + myNotifications.
  Future<void> _fetchDashboardData() async {
    if (!FindsApiClient.isAuthenticated) {
      debugPrint('[Accueil] Aucun token : connexion requise.');
      return;
    }
    if (_fetching) return;
    _fetching = true;

    try {
      final results = await Future.wait([
        FindsApiClient.query(
          GraphQLQueries.myDeclarationsQuery,
          variables: {
            'pagination': {'page': 1, 'pageSize': 100},
          },
        ),
        FindsApiClient.query(
          GraphQLQueries.myNotificationsQuery,
          variables: {
            'pagination': {'page': 1, 'pageSize': 50},
          },
        ),
      ]);
      if (!mounted) return;

      // En cas d'erreur réseau/serveur, on garde l'affichage précédent au
      // lieu de vider l'activité récente.
      if (results.any((r) => r.hasException)) {
        for (final r in results.where((r) => r.hasException)) {
          debugPrint('[Accueil] Erreur API : ${r.exception}');
        }
        if (results.every((r) => r.hasException)) return;
      }

      final dec = results[0].data?['myDeclarations'];
      final List decls = dec?['data'] as List? ?? [];
      final List notifs =
          results[1].data?['myNotifications']?['data'] as List? ?? [];

      setState(() {
        _declarationsCount = dec?['meta']?['total'] as int? ?? decls.length;
        _matchesCount = decls.fold<int>(
          0,
          (s, d) => s + ((d['matchesCount'] as int?) ?? 0),
        );
        _restoredCount = decls.where((d) => d['statut'] == 'RESOLUE').length;
        _unreadNotifications = notifs.where((n) => n['statut'] != 'LUE').length;
        _activities = notifs
            .take(3)
            .map((n) => Map<String, dynamic>.from(n as Map))
            .toList();
      });
    } catch (e) {
      debugPrint('[Accueil] Exception : $e');
    } finally {
      _fetching = false;
    }
  }

  final List<Map<String, String>> _steps = const [
    {
      'step': 'Étape 1',
      'title': '1. Document perdu',
      'desc': 'Signalez votre pièce d\'identité égarée',
      'image': 'assets/images/lost_empty.png',
      'badgeColor': 'primary',
    },
    {
      'step': 'Étape 2',
      'title': '2. Document trouvé',
      'desc': 'Un citoyen ou agent publie l\'avis',
      'image': 'assets/images/onboarding_1.png',
      'badgeColor': 'secondary',
    },
    {
      'step': 'Étape 3',
      'title': '3. Mise en relation',
      'desc': 'Correspondance automatique et mise en relation',
      'image': 'assets/images/onboarding_3.png',
      'badgeColor': 'tertiary',
    },
    {
      'step': 'Étape 4',
      'title': '4. Restitution réussie',
      'desc': 'Récupération du document en toute sérénité',
      'image': 'assets/images/recovered_happy.png',
      'badgeColor': 'primary',
    },
  ];

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _stepPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. App bar fixe : profil, salutation, recherche, notifications.
            // Elle reste en haut pendant que le reste de la page défile.
            _buildFixedAppBar(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _fetchDashboardData,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSizes.paddingPage.copyWith(
                    top: AppSizes.spaceXsm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Carte Résumé Activité en temps réel (KPIs)
                      _buildKpiCard(),

                      const SizedBox(height: AppSizes.spaceL - 2),

                      // 3. Bouton proéminent "Nouvelle déclaration"
                      _buildNewDeclarationBanner(),

                      const SizedBox(height: AppSizes.spaceXl),

                      // 4. Section "Comment ça marche" (Carrousel 4 étapes)
                      _buildHowItWorksSection(),

                      const SizedBox(height: AppSizes.spaceXxl - 6),

                      // 5. Section "Votre activité récente"
                      _buildRecentActivitySection(),

                      const SizedBox(height: AppSizes.spaceXl),
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

  Widget _buildFixedAppBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spaceMd,
        AppSizes.spaceSm,
        AppSizes.spaceMd,
        AppSizes.spaceSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(
          bottom: BorderSide(
            color: _isScrolled ? AppColors.divider : Colors.transparent,
          ),
        ),
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      child: _buildHeader(),
    );
  }

  // --- 1. Header Utilisateur Dynamique ---
  Widget _buildHeader() {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: FindsApiClient.currentUser,
      builder: (context, user, _) {
        final firstName = FindsApiClient.userFirstName;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Profil & Salutation
            Expanded(
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _showProfilePhotoModal(context),
                    borderRadius: BorderRadius.circular(AppSizes.iconXxl / 2),
                    child: _buildHeaderAvatar(
                      size: AppSizes.iconXxl,
                      fontSize: AppSizes.fontXl - 2,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceSm + 2),
                  Expanded(
                    // « Hello, Prénom 👋 » sur une seule ligne.
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Hello, ',
                            style: TextStyle(
                              fontSize: AppSizes.fontXxsm,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSubtle,
                            ),
                          ),
                          TextSpan(
                            text: firstName,
                            style: const TextStyle(
                              fontSize: AppSizes.fontMd,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const TextSpan(
                            text: ' 👋',
                            style: TextStyle(fontSize: AppSizes.fontMd),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),

            // Boutons Recherche & Notifications
            Row(
              children: [
                _buildHeaderCircleButton(
                  icon: Icons.search_rounded,
                  onTap:
                      widget.onSearchTap ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DocumentSearchView(),
                          ),
                        );
                      },
                ),
                const SizedBox(width: AppSizes.spaceXsm),
                _buildHeaderCircleButton(
                  icon: Icons.notifications_none_rounded,
                  badgeCount: _unreadNotifications,
                  onTap:
                      widget.onNotificationsTap ??
                      () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NotificationsListView(
                              onNavigateToTab: widget.onNavigateToTab,
                            ),
                          ),
                        );
                        _fetchDashboardData();
                      },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showProfilePhotoModal(BuildContext context) {
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
            final fullName = FindsApiClient.userFullName;
            final email = FindsApiClient.userEmail;
            final reputation = FindsApiClient.userReputation;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCDAD9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildHeaderAvatar(size: 90, fontSize: 40, shadow: true),
                  const SizedBox(height: 14),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
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
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+$reputation Pts Réputation Civique',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Changer la photo de profil',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Prendre une photo ou importer depuis la galerie',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSubtle,
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showPhotoSourcePicker(context);
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                    color: AppColors.divider,
                  ),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.infoSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.infoDark,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Voir mon profil complet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Modifier nom, téléphone, paramètres',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSubtle,
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      widget.onNavigateToTab?.call(4);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar({
    required double size,
    required double fontSize,
    bool shadow = false,
  }) {
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: FindsApiClient.userAvatarBytes,
      builder: (context, bytes, _) {
        final avatar = bytes != null
            ? ClipOval(
                child: Image.memory(
                  bytes,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    FindsApiClient.userInitial,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              );

        return Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: shadow ? 16 : 8,
                offset: Offset(0, shadow ? 6 : 3),
              ),
            ],
          ),
          child: avatar,
        );
      },
    );
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final photo = await PhotoService.pick(source: source);
      if (photo == null || !mounted) return;

      await FindsApiClient.setAvatar(photo.bytes, name: photo.name);
      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            source == ImageSource.camera
                ? 'Photo de profil mise à jour avec succès !'
                : 'Photo sélectionnée depuis la galerie !',
          ),
        ),
      );
    } on PhotoTooLargeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text(e.toString())),
      );
    } catch (e) {
      debugPrint('[HomeDashboardView] Erreur sélection photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Impossible d\'ouvrir le sélecteur de photo.'),
        ),
      );
    }
  }

  void _showPhotoSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Sélectionner une photo de profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Prendre une photo (Appareil photo)'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickProfilePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Choisir dans la galerie'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickProfilePhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCircleButton({
    required IconData icon,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          child: Container(
            width: AppSizes.buttonHeightSm,
            height: AppSizes.buttonHeightSm,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Icon(icon, size: AppSizes.iconMd, color: AppColors.textBody),
          ),
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceXxsm + 1,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.errorDark,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppSizes.fontXxsm,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- 2. Carte KPIs Activité ---
  Widget _buildKpiCard() {
    return Container(
      width: double.infinity,
      padding: AppSizes.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: const Color(0xFFBFCABA).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: AppSizes.iconSm + 1,
                    ),
                    SizedBox(width: AppSizes.spaceXsm),
                    Flexible(
                      child: Text(
                        'Votre activité en temps réel',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceSm - 2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: AppSizes.borderRadiusDefault,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spaceXxsm + 2),
                    const Text(
                      'Actif',
                      style: TextStyle(
                        fontSize: AppSizes.fontXxsm + 1,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceMd - 2),
          // 3 Colonnes de Compteurs
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceSm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(AppSizes.radiusL - 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildKpiItem(
                  icon: Icons.description_outlined,
                  value: '$_declarationsCount',
                  label: 'Déclarations',
                  iconColor: AppColors.primary,
                  onTap: () => widget.onNavigateToTab?.call(1),
                ),
                Container(
                  width: 1,
                  height: AppSizes.buttonHeightSm,
                  color: AppColors.border,
                ),
                _buildKpiItem(
                  icon: Icons.bolt_rounded,
                  value: '$_matchesCount',
                  label: 'Matchs',
                  iconColor: AppColors.primary,
                  highlight: _matchesCount > 0,
                  onTap: () => widget.onNavigateToTab?.call(2),
                ),
                Container(
                  width: 1,
                  height: AppSizes.buttonHeightSm,
                  color: AppColors.border,
                ),
                _buildKpiItem(
                  icon: Icons.task_alt_rounded,
                  value: '$_restoredCount',
                  label: 'Restitué',
                  iconColor: AppColors.successDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    bool highlight = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: AppSizes.spaceXxl,
              height: AppSizes.spaceXxl,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.iconSm - 1),
            ),
            const SizedBox(height: AppSizes.spaceXxsm + 2),
            Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.fontXl - 2,
                fontWeight: FontWeight.w800,
                color: highlight ? AppColors.primary : AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontXxsm + 1,
                color: highlight ? AppColors.primary : AppColors.textSubtle,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Bannière "Nouvelle déclaration" ---
  Widget _buildNewDeclarationBanner() {
    return Container(
      width: double.infinity,
      padding: AppSizes.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onNewDeclarationTap ?? () {},
        child: Row(
          children: [
            Container(
              width: AppSizes.buttonHeightDefault - 4,
              height: AppSizes.buttonHeightDefault - 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: AppSizes.borderRadiusDefault,
              ),
              child: const Icon(
                Icons.post_add_rounded,
                color: Colors.white,
                size: AppSizes.iconXl - 10,
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouvelle déclaration',
                    style: TextStyle(
                      fontSize: AppSizes.fontDefault,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Signaler un document perdu ou trouvé',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppSizes.fontXsm,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.spaceXsm),
            Container(
              width: AppSizes.buttonHeightSm - 2,
              height: AppSizes.buttonHeightSm - 2,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: AppSizes.iconDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Section "Comment ça marche" ---
  Widget _buildHowItWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Flexible(
              child: Text(
                'COMMENT ÇA MARCHE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textSubtle,
                ),
              ),
            ),
            Text(
              'En 4 étapes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _stepPageController,
            itemCount: _steps.length,
            onPageChanged: (i) => setState(() => _currentStepIndex = i),
            itemBuilder: (context, index) {
              final step = _steps[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primarySoft,
                  border: Border.all(
                    color: const Color(0xFFBFCABA).withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Image de fond
                      Positioned.fill(
                        child: Image.asset(
                          step['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.primarySoft,
                            child: const Icon(
                              Icons.article_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      // Gradient noir pour la lisibilité
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Textes
                      Positioned(
                        bottom: 12,
                        left: 14,
                        right: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                step['step']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              step['desc']!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_steps.length, (index) {
            final isActive = index == _currentStepIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // --- 5. Activité Récente (Populated vs Empty) ---
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Votre activité récente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 12),
        if (_activities.isEmpty)
          _buildEmptyActivityState()
        else
          _buildPopulatedActivityList(),
      ],
    );
  }

  Widget _buildPopulatedActivityList() {
    return Column(
      children: [
        for (int i = 0; i < _activities.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildNotificationActivity(_activities[i]),
        ],
      ],
    );
  }

  /// Ouvre une notification d'information (message de l'admin, rappel…)
  /// en entier et la marque comme lue.
  Future<void> _openNotificationDetail(Map<String, dynamic> n) async {
    if (n['statut'] != 'LUE') {
      setState(() {
        n['statut'] = 'LUE';
        if (_unreadNotifications > 0) _unreadNotifications--;
      });
      FindsApiClient.mutate(
        GraphQLQueries.markNotificationReadMutation,
        variables: {'notificationId': n['id']},
      );
    }
    await NotificationDetailView.open(context, n);
    if (mounted) _fetchDashboardData();
  }

  Widget _buildNotificationActivity(Map<String, dynamic> n) {
    final type = n['type'] as String? ?? '';
    final unread = n['statut'] != 'LUE';
    if (type.startsWith('MATCH_')) {
      return _buildActivityItem(
        icon: Icons.find_in_page_rounded,
        iconBg: AppColors.primarySoft,
        iconColor: AppColors.primary,
        title: n['titre'] as String? ?? '',
        subtitle: n['corps'] as String? ?? '',
        time: relativeTime(n['createdAt'] as String?),
        timeColor: AppColors.primary,
        hasNotificationDot: unread,
        onTap: () => widget.onNavigateToTab?.call(2),
      );
    }
    if (type == 'NOUVEAU_MESSAGE' || type == 'CONVERSATION_RESOLUE') {
      return _buildActivityItem(
        icon: Icons.chat_bubble_outline_rounded,
        iconBg: const Color(0xFFE1F5FE),
        iconColor: const Color(0xFF0288D1),
        title: n['titre'] as String? ?? '',
        subtitle: n['corps'] as String? ?? '',
        time: relativeTime(n['createdAt'] as String?),
        hasNotificationDot: unread,
        onTap: () => widget.onNavigateToTab?.call(3),
      );
    }
    if (NotificationDetailView.isInformational(type)) {
      return _buildActivityItem(
        icon: Icons.campaign_rounded,
        iconBg: AppColors.primarySoft,
        iconColor: AppColors.primary,
        title: n['titre'] as String? ?? '',
        subtitle: n['corps'] as String? ?? '',
        time: relativeTime(n['createdAt'] as String?),
        hasNotificationDot: unread,
        onTap: () => _openNotificationDetail(n),
      );
    }
    return _buildActivityItem(
      icon: Icons.task_alt_rounded,
      iconBg: AppColors.primarySoft,
      iconColor: AppColors.successDark,
      title: n['titre'] as String? ?? '',
      subtitle: n['corps'] as String? ?? '',
      time: relativeTime(n['createdAt'] as String?),
      hasNotificationDot: unread,
      onTap: () => widget.onNavigateToTab?.call(1),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    Color? timeColor,
    bool hasNotificationDot = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (hasNotificationDot)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSubtle,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: timeColor ?? AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // État vide
  Widget _buildEmptyActivityState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune activité pour le moment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vos prochaines actions (correspondances, messages, restitutions…) apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSubtle,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onNewDeclarationTap ?? () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Créer une déclaration'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
