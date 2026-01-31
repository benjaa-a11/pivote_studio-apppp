import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../config/app_animations.dart';
import 'home_screen.dart';
import 'futbol_screen.dart';
import 'favorites_screen.dart';
import 'radios_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FutbolScreen(),
    const FavoritesScreen(),
    const RadiosScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: theme.scaffoldBackgroundColor,
          animationDuration: const Duration(milliseconds: 350),
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onNavItemTapped,
          elevation: 0,
          height: 70,
          indicatorColor: theme.navigationBarTheme.indicatorColor,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: AppAnimations.pulseIcon(
                isSelected: false,
                child: SvgPicture.asset(
                  'assets/icons/home_16.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    theme.iconTheme.color?.withValues(alpha: 0.7) ??
                        Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              selectedIcon: AppAnimations.pulseIcon(
                isSelected: _selectedIndex == 0,
                child: SvgPicture.asset(
                  'assets/icons/home_active_16.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    selectedColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: AppAnimations.pulseIcon(
                isSelected: false,
                child: Icon(
                  Icons.sports_soccer_outlined,
                  size: 22,
                  color: theme.iconTheme.color?.withValues(alpha: 0.7) ??
                      Colors.grey,
                ),
              ),
              selectedIcon: AppAnimations.pulseIcon(
                isSelected: _selectedIndex == 1,
                child: Icon(
                  Icons.sports_soccer,
                  size: 22,
                  color: selectedColor,
                ),
              ),
              label: 'Futbol',
            ),
            NavigationDestination(
              icon: AppAnimations.pulseIcon(
                isSelected: false,
                child: SvgPicture.asset(
                  'assets/icons/favorite_16.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    theme.iconTheme.color?.withValues(alpha: 0.7) ??
                        Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              selectedIcon: AppAnimations.pulseIcon(
                isSelected: _selectedIndex == 2,
                child: SvgPicture.asset(
                  'assets/icons/favorite_active_16.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    selectedColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: AppAnimations.pulseIcon(
                isSelected: false,
                child: FaIcon(
                  FontAwesomeIcons.radio,
                  size: 22,
                  color: theme.iconTheme.color?.withValues(alpha: 0.7) ??
                      Colors.grey,
                ),
              ),
              selectedIcon: AppAnimations.pulseIcon(
                isSelected: _selectedIndex == 3,
                child: FaIcon(
                  FontAwesomeIcons.radio,
                  size: 22,
                  color: selectedColor,
                ),
              ),
              label: 'Radio',
            ),
            NavigationDestination(
              icon: AppAnimations.pulseIcon(
                isSelected: false,
                child: SvgPicture.asset(
                  'assets/icons/user_16.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    theme.iconTheme.color?.withValues(alpha: 0.7) ??
                        Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              selectedIcon: AppAnimations.pulseIcon(
                isSelected: _selectedIndex == 4,
                child: SvgPicture.asset(
                  'assets/icons/user_active_16.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    selectedColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
