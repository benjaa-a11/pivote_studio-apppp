import 'package:flutter/material.dart';

import 'package:pivote/features/navigation/presentation/widgets/tv_nav_drawer.dart';
import 'package:pivote/features/home/presentation/screens/tv_home_screen.dart';
import 'package:pivote/features/soccer/presentation/screens/futbol_screen.dart';
import 'package:pivote/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pivote/features/radio/presentation/screens/radios_screen.dart';
import 'package:pivote/features/profile/presentation/screens/profile_screen.dart';
import 'dart:async';

class TvMainScreen extends StatefulWidget {
  const TvMainScreen({super.key});

  @override
  State<TvMainScreen> createState() => _TvMainScreenState();
}

class _TvMainScreenState extends State<TvMainScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = false;

  // Reuse existing screens for now, will replace with TV-optimized versions progressively
  final List<Widget> _screens = [
    const TvHomeScreen(),
    const FutbolScreen(),
    const FavoritesScreen(),
    const RadiosScreen(),
    const ProfileScreen(),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Timer? _collapseTimer;

  void _onDrawerFocusChange(bool hasFocus) {
    if (hasFocus) {
      _collapseTimer?.cancel();
      setState(() {
        _isExpanded = true;
      });
    } else {
      _collapseTimer = Timer(const Duration(milliseconds: 100), () {
        setState(() {
          _isExpanded = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Navigation Drawer
            TVNavDrawer(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              isExpanded: _isExpanded,
              onFocusChange: _onDrawerFocusChange,
            ),

            // Main Content Area
            Expanded(
              child: FocusTraversalGroup(
                // Ensure focus moves logically from drawer to content
                policy: OrderedTraversalPolicy(),
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
