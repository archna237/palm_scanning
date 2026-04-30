import 'package:flutter/material.dart';
import 'package:scanning_app/src/features/articles/presentation/articles_screen.dart';
import 'package:scanning_app/src/features/explore/presentation/explore_screen.dart';
import 'package:scanning_app/src/features/profiles/presentation/profiles_screen.dart';
import 'package:scanning_app/src/features/scan/presentation/scan_screen.dart';
import 'package:scanning_app/src/features/wallpapers/presentation/wallpapers_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  static final List<Widget> _screens = <Widget>[
    const ScanScreen(),
    const ExploreScreen(),
    const ProfilesScreen(),
    const ArticlesScreen(),
    const WallpapersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Profiles',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Articles',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallpaper_outlined),
            selectedIcon: Icon(Icons.wallpaper),
            label: 'Walls',
          ),
        ],
      ),
    );
  }
}
