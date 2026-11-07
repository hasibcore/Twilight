import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/player_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/mini_player_widget.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'search/search_screen.dart';
import 'library/library_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  /// Switches to the embedded Search tab when inside MainNavigationScreen,
  /// or pushes SearchScreen as a route if outside MainNavigationScreen.
  static void openSearch(BuildContext context, {String? initialQuery}) {
    final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (state != null) {
      state.switchToSearchTab(initialQuery: initialQuery);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchScreen(initialQuery: initialQuery),
        ),
      );
    }
  }

  /// Switches to any top-level tab index (0=Home, 1=Explore, 2=Search, 3=Library, 4=Profile).
  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (state != null) {
      state.selectTab(index);
    }
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _lastShownError;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    SearchScreen(isEmbeddedTab: true),
    LibraryScreen(),
    ProfileScreen(),
  ];

  void selectTab(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() {
      _currentIndex = index;
    });
  }

  void switchToSearchTab({String? initialQuery}) {
    setState(() {
      _currentIndex = 2;
    });
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      context.read<SearchProvider>().search(initialQuery.trim());
    }
  }

  Widget _buildDesktopSidebar() {
    const navItems = [
      (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: AppStrings.navHome),
      (icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: AppStrings.navExplore),
      (icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: AppStrings.navSearch),
      (icon: Icons.library_music_outlined, activeIcon: Icons.library_music_rounded, label: AppStrings.navLibrary),
      (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: AppStrings.navProfile),
    ];

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => selectTab(0),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: AppLogo(
                size: 40,
                showText: true,
                subtitle: 'MUSIC STREAMING',
                stackedSubtitle: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(navItems.length, (idx) {
            final item = navItems[idx];
            final isActive = _currentIndex == idx;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => selectTab(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF4F46E5) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 20,
                          color: isActive ? Colors.white : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final hasActiveSong = player.currentSong != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth >= 768;

    // Gracefully reflect error states
    final errorMsg = player.errorMessage;
    if (errorMsg != null && errorMsg != _lastShownError) {
      _lastShownError = errorMsg;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.surfaceVariantDark,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        player.clearError();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          // Smoothly move Android task to background without killing AudioService
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Row(
          children: [
            if (isDesktopOrTablet) _buildDesktopSidebar(),
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),

                  // Single authoritative Mini Player floating directly above bottom navigation
                  if (hasActiveSong)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: MiniPlayerWidget(),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isDesktopOrTablet
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF020617).withValues(alpha: 0.96),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: const Color(0xFF818CF8),
                  unselectedItemColor: const Color(0xFF94A3B8),
                  currentIndex: _currentIndex,
                  onTap: selectTab,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_filled),
                      label: AppStrings.navHome,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.explore_outlined),
                      activeIcon: Icon(Icons.explore),
                      label: AppStrings.navExplore,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search_outlined),
                      activeIcon: Icon(Icons.search),
                      label: AppStrings.navSearch,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.library_music_outlined),
                      activeIcon: Icon(Icons.library_music),
                      label: AppStrings.navLibrary,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person),
                      label: AppStrings.navProfile,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
