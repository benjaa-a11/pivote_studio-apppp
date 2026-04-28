import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:pivote/features/home/presentation/screens/home_screen.dart';
import 'package:pivote/features/soccer/presentation/screens/futbol_screen.dart';
import 'package:pivote/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pivote/features/radio/presentation/screens/radios_screen.dart';
import 'package:pivote/features/profile/presentation/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    // Check notification permission after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumida - Actualizando datos de fútbol');
      try {
        final soccerProvider = context.read<SoccerProvider>();
        soccerProvider.fetchData(silent: true);
      } catch (e) {
        debugPrint('⚠️ Error al refrescar datos de fútbol: $e');
      }
    }
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    if (index == 1) {
      try {
        final soccerProvider = context.read<SoccerProvider>();
        soccerProvider.refreshIfStale();
      } catch (e) {
        debugPrint('⚠️ Error al refrescar datos de fútbol: $e');
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  /// Checks if we should show the notification permission prompt.
  /// Only shows once, tracked via SharedPreferences.
  Future<void> _checkNotificationPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool('notification_prompt_shown') ?? false;
      if (hasPrompted) return;

      // Check current permission status
      final isAlreadyEnabled =
          await NotificationService.areNotificationsEnabled();
      if (isAlreadyEnabled) {
        // Already authorized, just mark as done
        await prefs.setBool('notification_prompt_shown', true);
        return;
      }

      // Wait a bit so user sees the main screen first
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      _showNotificationPrompt(prefs);
    } catch (e) {
      debugPrint('⚠️ Error checking notification permission: $e');
    }
  }

  /// Shows a contextual bottom sheet explaining notification benefits.
  void _showNotificationPrompt(SharedPreferences prefs) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.hintColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Mantente al día!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Activa las notificaciones para recibir alertas de partidos en vivo, nuevos canales y contenido exclusivo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await NotificationService.requestPermission();
                  await prefs.setBool('notification_prompt_shown', true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ACTIVAR NOTIFICACIONES',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await prefs.setBool('notification_prompt_shown', true);
              },
              child: Text(
                'Ahora no',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                child: Icon(
                  Icons.favorite_outline_rounded,
                  size: 22,
                  color: theme.iconTheme.color?.withValues(alpha: 0.7) ??
                      Colors.grey,
                ),
              ),
              selectedIcon: AppAnimations.pulseIcon(
                isSelected: _selectedIndex == 2,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 22,
                  color: selectedColor,
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
