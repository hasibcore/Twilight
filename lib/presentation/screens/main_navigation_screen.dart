import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../providers/player_provider.dart';
import '../widgets/mini_player_widget.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'search/search_screen.dart';
import 'library/library_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _lastShownError;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final hasActiveSong = player.currentSong != null;

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
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),

            // Mini Player floating directly above bottom navigation
            if (hasActiveSong)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom +
                    kBottomNavigationBarHeight,
                child: const MiniPlayerWidget(),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xE6030712),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.primaryAccent,
                unselectedItemColor: AppColors.textTertiaryDark,
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
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
                icon: Icon(Icons.search_rounded),
                activeIcon: Icon(Icons.search_rounded),
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
    ),
  ),
);
  }
}


