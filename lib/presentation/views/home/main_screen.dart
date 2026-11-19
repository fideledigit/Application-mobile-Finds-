import 'package:flutter/material.dart';
import '../../../core/api/graphql_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../declaration/declaration_type_choice_view.dart';
import '../declarations/declarations_list_view.dart';
import '../matches/matches_list_view.dart';
import '../messages/conversations_list_view.dart';
import '../profile/profile_view.dart';
import 'home_dashboard_view.dart';

/// Écran principal avec barre de navigation inférieure (5 onglets)
/// Conforme à la navigation mobile de Stitch
class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  int _homeRefreshToken = 0;
  int _profileRefreshToken = 0;
  int _declarationsRefreshToken = 0;
  int _matchesRefreshToken = 0;
  int _messagesRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      // À chaque ouverture d'un onglet qui affiche des données serveur,
      // on force leur rechargement (les pages restent montées dans l'IndexedStack).
      if (index == 0 && _currentIndex != 0) {
        _homeRefreshToken++;
      }
      if (index == 1 && _currentIndex != 1) {
        _declarationsRefreshToken++;
      }
      if (index == 2 && _currentIndex != 2) {
        _matchesRefreshToken++;
      }
      if (index == 3 && _currentIndex != 3) {
        _messagesRefreshToken++;
      }
      if (index == 4 && _currentIndex != 4) {
        _profileRefreshToken++;
      }
      _currentIndex = index;
    });
  }

  Future<void> _openNewDeclaration() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeclarationTypeChoiceView()),
    );
    if (!mounted) return;
    // Au retour du parcours de déclaration, on rafraîchit les données
    // serveur (liste des déclarations + statistiques du profil).
    setState(() {
      _homeRefreshToken++;
      _declarationsRefreshToken++;
      _profileRefreshToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Le bouton "+" n'apparaît pas sur les onglets Matches et Profil.
    final bool showFab = _currentIndex != 2 && _currentIndex != 4;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      // Bouton "+" flottant : ouvre les options de déclarations (perdu / trouvé)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: showFab
          ? Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceXsm),
              child: FloatingActionButton(
                onPressed: _openNewDeclaration,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                tooltip: 'Nouvelle déclaration',
                child: const Icon(
                  Icons.add_rounded,
                  size: AppSizes.iconDefault + 4,
                ),
              ),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0 : Accueil (Dashboard)
          HomeDashboardView(
            onNewDeclarationTap: _openNewDeclaration,
            onNavigateToTab: _onTabTapped,
            refreshToken: _homeRefreshToken,
          ),

          // 1 : Déclarations
          DeclarationsListView(
            onNewDeclarationTap: _openNewDeclaration,
            onNavigateToTab: _onTabTapped,
            refreshToken: _declarationsRefreshToken,
          ),

          // 2 : Matches
          MatchesListView(
            onNavigateToTab: _onTabTapped,
            refreshToken: _matchesRefreshToken,
          ),

          // 3 : Messages
          ConversationsListView(
            onNavigateToTab: _onTabTapped,
            refreshToken: _messagesRefreshToken,
          ),

          // 4 : Profil
          ProfileView(
            onNavigateToTab: _onTabTapped,
            refreshToken: _profileRefreshToken,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Accueil',
                  icon: Icons.home_rounded,
                  unselectedIcon: Icons.home_outlined,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Déclarations',
                  icon: Icons.description_rounded,
                  unselectedIcon: Icons.description_outlined,
                ),
                ValueListenableBuilder<int>(
                  valueListenable: FindsApiClient.pendingMatchesCount,
                  builder: (_, count, _) => _buildNavItem(
                    index: 2,
                    label: 'Matchs',
                    icon: Icons.handshake_rounded,
                    unselectedIcon: Icons.handshake_outlined,
                    badgeText: _badge(count),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: FindsApiClient.unreadMessagesCount,
                  builder: (_, count, _) => _buildNavItem(
                    index: 3,
                    label: 'Messages',
                    icon: Icons.chat_bubble_rounded,
                    unselectedIcon: Icons.chat_bubble_outline_rounded,
                    badgeText: _badge(count),
                  ),
                ),
                _buildNavItem(
                  index: 4,
                  label: 'Profil',
                  icon: Icons.person_rounded,
                  unselectedIcon: Icons.person_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _badge(int count) =>
      count <= 0 ? null : (count > 9 ? '9+' : '$count');

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData unselectedIcon,
    String? badgeText,
  }) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: AppSizes.borderRadiusDefault,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: AppSizes.spaceXxsm + 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? icon : unselectedIcon,
                    size: AppSizes.iconDefault,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSubtle,
                  ),
                  if (badgeText != null)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spaceXxsm + 1,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm - 2,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppSizes.fontXxsm - 1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: AppSizes.fontXxsm + 1,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
