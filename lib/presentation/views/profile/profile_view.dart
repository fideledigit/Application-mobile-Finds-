import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/api/graphql_queries.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/photo_service.dart';
import '../auth/login_view.dart';
import 'about_view.dart';
import 'change_password_view.dart';
import 'conditions_view.dart';
import 'edit_profile_view.dart';
import 'faq_view.dart';
import 'privacy_view.dart';

/// Onglet 4 : Mon Profil Citoyen
/// Conforme à la maquette findmydoc_profil
class ProfileView extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final int refreshToken;

  const ProfileView({super.key, this.onNavigateToTab, this.refreshToken = 0});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late String _userName;
  late String _userEmail;
  late String _userPhone;
  late String _userAddress;
  late int _reputationPoints;

  int _declarationsCount = 0;
  int _matchesCount = 0;
  int _restoredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchStats();
    FindsApiClient.currentUser.addListener(_loadUserData);
  }

  @override
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharge les compteurs à chaque retour sur l'onglet Profil.
    if (oldWidget.refreshToken != widget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchStats();
        }
      });
    }
  }

  Future<void> _fetchStats() async {
    if (!FindsApiClient.isAuthenticated) return;
    try {
      final res = await FindsApiClient.query(GraphQLQueries.meQuery);
      final me = res.data?['me'] as Map<String, dynamic>?;
      if (!mounted) return;
      if (me != null) {
        // Met à jour la session : le listener recharge nom, email, téléphone.
        await FindsApiClient.updateCurrentUser(me);
        if (!mounted) return;
        setState(() {
          _restoredCount = me['nombreRestitutions'] as int? ?? _restoredCount;
        });
      }

      final decRes = await FindsApiClient.query(
        GraphQLQueries.myDeclarationsQuery,
        variables: const {
          'pagination': {'page': 1, 'pageSize': 100},
        },
      );
      final myDec = decRes.data?['myDeclarations'];
      if (mounted && myDec is Map) {
        final List data = myDec['data'] as List? ?? [];
        final matches = data.fold<int>(
          0,
          (sum, d) => sum + ((d['matchesCount'] as int?) ?? 0),
        );
        setState(() {
          _declarationsCount = myDec['meta']?['total'] as int? ?? data.length;
          _matchesCount = matches;
        });
      }
    } catch (e) {
      debugPrint('[ProfileView] Erreur chargement statistiques : $e');
    }
  }

  @override
  void dispose() {
    FindsApiClient.currentUser.removeListener(_loadUserData);
    super.dispose();
  }

  void _loadUserData() {
    void apply() {
      _userName = FindsApiClient.userFullName;
      _userEmail = FindsApiClient.userEmail;
      _userPhone = FindsApiClient.userPhone;
      _userAddress = FindsApiClient.userAddress;
      _reputationPoints = FindsApiClient.userReputation;
    }

    if (mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _openEditProfile() async {
    // EditProfileView enregistre via updateUser puis met à jour la session.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileView(
          initialName: _userName,
          initialEmail: _userEmail,
          initialPhone: _userPhone,
          initialAddress: _userAddress,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar({
    required double radius,
    required double fontSize,
  }) {
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: FindsApiClient.userAvatarBytes,
      builder: (context, bytes, _) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primarySoft,
        backgroundImage: bytes != null ? MemoryImage(bytes) : null,
        child: bytes == null
            ? Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
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
      debugPrint('[ProfileView] Erreur sélection photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Impossible d\'ouvrir le sélecteur de photo.'),
        ),
      );
    }
  }

  void _showPhotoOptionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              const SizedBox(height: 16),
              _buildProfileAvatar(radius: 40, fontSize: 36),
              const SizedBox(height: 12),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _userEmail,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Prendre une photo'),
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
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSubtle,
                ),
                title: const Text('Modifier les informations textuelles'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openEditProfile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: const Text('Déconnexion'),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de Finds ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              FindsApiClient.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  void _showSupportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusL),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              const Text(
                'Aide & Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Notre équipe et nos ressources sont là pour vous accompagner.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSubtle),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.quiz_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Consulter la FAQ'),
                subtitle: const Text(
                  'Réponses aux questions les plus fréquentes',
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSubtle,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const FaqView()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModalInfo(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontL,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            fontSize: AppSizes.fontSm,
            height: 1.45,
            color: AppColors.textBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Fermer',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceMd,
                  vertical: AppSizes.spaceSm,
                ),
                child: Column(
                  children: [
                    // Citizen Profile Header Card
                    _buildUserCard(),
                    const SizedBox(height: AppSizes.spaceMd),

                    // Stats row: 2 Declarations, 3 Matches, 1 Restitue
                    _buildStatsRow(),
                    const SizedBox(height: AppSizes.spaceL - 2),

                    // Group 1: Activite & Suivi
                    _buildSectionHeader('ACTIVITÉ & SUIVI'),
                    _buildGroupCard([
                      _buildListTile(
                        icon: Icons.description_rounded,
                        title: 'Mes déclarations',
                        subtitle: 'Pièces perdues & trouvées',
                        badge: '2 actives',
                        onTap: () => widget.onNavigateToTab?.call(1),
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppColors.divider,
                      ),
                      _buildListTile(
                        icon: Icons.handshake_rounded,
                        title: 'Mes matchs',
                        subtitle: 'Correspondances trouvées',
                        badge: '1 nouveau',
                        badgeColor: AppColors.primary,
                        badgeTextColor: Colors.white,
                        onTap: () => widget.onNavigateToTab?.call(2),
                      ),
                    ]),
                    const SizedBox(height: AppSizes.spaceMd),

                    // Group 2: Preferences de compte
                    _buildSectionHeader('PRÉFÉRENCES DE COMPTE'),
                    _buildGroupCard([
                      _buildListTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Modifier mon profil',
                        subtitle: 'Nom, e-mail, téléphone et adresse',
                        onTap: _openEditProfile,
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppColors.divider,
                      ),
                      _buildListTile(
                        icon: Icons.security_rounded,
                        title: 'Sécurité et confidentialité',
                        subtitle: 'Protection des données personnelles',
                        onTap: () {
                          _showModalInfo(
                            'Sécurité et confidentialité',
                            'Les échanges entre l\'application et le serveur Finds passent par une connexion sécurisée (HTTPS). Vos informations personnelles sont protégées et vos coordonnées ne sont pas divulguées publiquement.',
                          );
                        },
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppColors.divider,
                      ),
                      _buildListTile(
                        icon: Icons.lock_reset_rounded,
                        title: 'Changer le mot de passe',
                        subtitle: 'Mot de passe actuel requis',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordView(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: AppSizes.spaceMd),

                    // Group 3: Assistance & Legal
                    _buildSectionHeader('ASSISTANCE & LÉGAL'),
                    _buildGroupCard([
                      _buildListTile(
                        icon: Icons.contact_support_rounded,
                        title: 'Aide & Support en ligne',
                        onTap: _showSupportOptions,
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppColors.divider,
                      ),
                      _buildListTile(
                        icon: Icons.info_rounded,
                        title: 'À propos de Finds',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutView()),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppColors.divider,
                      ),
                      _buildListTile(
                        icon: Icons.quiz_rounded,
                        title: 'FAQ',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FaqView()),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppColors.divider,
                      ),
                      _buildListTile(
                        icon: Icons.gavel_rounded,
                        title: 'Conditions Générales d’Utilisation',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConditionsView(),
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: 56,
                        color: AppColors.divider,
                      ),
                      _buildListTile(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Politique de Confidentialité',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyView(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: AppSizes.spaceMd),

                    // Group 4: Deconnexion
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusDefault,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.errorSoft,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusSm - 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: AppSizes.iconMd,
                          ),
                        ),
                        title: const Text(
                          'Se déconnecter',
                          style: TextStyle(
                            fontSize: AppSizes.fontMd,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.error,
                          size: AppSizes.iconSm,
                        ),
                        onTap: _handleLogout,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceXl),

                    // Footer
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: AppSizes.iconXsm,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: AppSizes.spaceXxsm + 2),
                        Flexible(
                          child: Text(
                            'Finds v1.2.0 • Plateforme civique',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppSizes.fontXxsm + 1,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spaceXxl),
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
        vertical: AppSizes.spaceSm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
                ),
                child: const Icon(
                  Icons.account_circle_rounded,
                  color: AppColors.primary,
                  size: AppSizes.iconL,
                ),
              ),
              const SizedBox(width: AppSizes.spaceSm - 2),
              const Text(
                'Mon profil',
                style: TextStyle(
                  fontSize: AppSizes.fontL,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSubtle,
            ),
            onPressed: _openEditProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: AppSizes.paddingCard,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          InkWell(
            onTap: _showPhotoOptionsModal,
            borderRadius: BorderRadius.circular(34),
            child: Stack(
              children: [
                _buildProfileAvatar(radius: 34, fontSize: AppSizes.fontXxl + 2),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _showPhotoOptionsModal,
                    child: Container(
                      width: AppSizes.spaceXl,
                      height: AppSizes.spaceXl,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: AppSizes.iconXxsm,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spaceSm + 2),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: AppSizes.fontL,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userEmail,
                  style: const TextStyle(
                    fontSize: AppSizes.fontXsm,
                    color: AppColors.textSubtle,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _userPhone,
                  style: const TextStyle(
                    fontSize: AppSizes.fontXsm,
                    color: AppColors.textSubtle,
                  ),
                ),
                if (_userAddress.isNotEmpty)
                  Text(
                    _userAddress,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXsm,
                      color: AppColors.textSubtle,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppSizes.spaceXxsm + 2),

                // Reputation badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceXsm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: AppSizes.iconXsm - 1,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.spaceXxsm),
                      Text(
                        'Citoyen Vérifié • +$_reputationPoints Pts',
                        style: const TextStyle(
                          fontSize: AppSizes.fontXxsm + 0.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            value: '$_declarationsCount',
            label: 'Déclarations',
            icon: Icons.description_rounded,
            onTap: () => widget.onNavigateToTab?.call(1),
          ),
        ),
        const SizedBox(width: AppSizes.spaceSm - 2),
        Expanded(
          child: _buildStatItem(
            value: '$_matchesCount',
            label: 'Matchs',
            icon: Icons.handshake_rounded,
            hasPing: _matchesCount > 0,
            onTap: () => widget.onNavigateToTab?.call(2),
          ),
        ),
        const SizedBox(width: AppSizes.spaceSm - 2),
        Expanded(
          child: _buildStatItem(
            value: '$_restoredCount',
            label: 'Restitué',
            icon: Icons.task_alt_rounded,
            onTap: () => widget.onNavigateToTab?.call(1),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    bool hasPing = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spaceSm + 2,
          horizontal: AppSizes.spaceXsm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: AppSizes.iconMd,
                  ),
                ),
                if (hasPing)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: AppSizes.spaceXsm,
                      height: AppSizes.spaceXsm,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceXsm),
            Text(
              value,
              style: const TextStyle(
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.fontXxsm + 1,
                color: AppColors.textSubtle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSizes.spaceXxsm,
          bottom: AppSizes.spaceXsm,
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: AppSizes.fontXxsm + 1,
            fontWeight: FontWeight.bold,
            color: AppColors.textSubtle,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
        ),
        child: Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppSizes.fontSm,
          fontWeight: FontWeight.w600,
          color: AppColors.textStrong,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: AppSizes.fontXxsm + 1.5,
                color: AppColors.textSubtle,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceXsm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.chipBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: AppSizes.fontXxsm + 0.5,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor ?? AppColors.textBody,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spaceXxsm + 2),
          ],
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSubtle,
            size: AppSizes.iconMd,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
