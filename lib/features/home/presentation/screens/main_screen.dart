import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/home/presentation/screens/home_screen.dart';
import 'package:pivote/features/profile/presentation/screens/profile_screen.dart';
import 'package:pivote/features/radio/presentation/screens/radios_screen.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/screens/futbol_screen.dart';
import 'package:pivote/shared/widgets/common/animated_indexed_stack.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/floating_bottom_bar.dart';
import 'package:pivote/shared/widgets/common/user_avatar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<ScrollController> _scrollControllers =
      List.generate(4, (_) => ScrollController());

  List<Widget> get _screens {
    final pages = <Widget>[
      HomeScreen(onNavigateToTab: _onNavItemTapped),
      const FutbolScreen(),
      const RadiosScreen(),
      const ProfileScreen(),
    ];
    return [
      for (var i = 0; i < pages.length; i++)
        PrimaryScrollController(
          controller: _scrollControllers[i],
          child: pages[i],
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      try {
        context.read<SoccerProvider>().fetchData(silent: true);
      } catch (e) {
        debugPrint('⚠️ Error al refrescar datos de fútbol: $e');
      }
    }
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) {
      final c = _scrollControllers[index];
      if (c.hasClients && c.offset > 0) {
        HapticFeedback.selectionClick();
        c.animateTo(
          0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool('notification_prompt_shown') ?? false;
      if (hasPrompted) return;

      final isAlreadyEnabled =
          await NotificationService.areNotificationsEnabled();
      if (isAlreadyEnabled) {
        await prefs.setBool('notification_prompt_shown', true);
        return;
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      _showNotificationPrompt(prefs);
    } catch (e) {
      debugPrint('⚠️ Error checking notification permission: $e');
    }
  }

  void _showNotificationPrompt(SharedPreferences prefs) {
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    AppDialogs.showModal<void>(
      context: context,
      child: Builder(
        builder: (ctx) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.accentDim(ctx),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.32),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 30,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '¡Mantente al día!',
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppTheme.textPrimary(ctx),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Activá las notificaciones para recibir alertas de partidos en vivo, goles y nuevos canales.',
                  textAlign: TextAlign.center,
                  style: AppFont.primary(
                    fontSize: 13.5,
                    height: 1.48,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary(ctx),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await NotificationService.requestPermission();
                      await prefs.setBool('notification_prompt_shown', true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: onAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      'Activar notificaciones',
                      style: AppFont.primary(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: onAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await prefs.setBool('notification_prompt_shown', true);
                  },
                  child: Text(
                    'Ahora no',
                    style: AppFont.primary(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppTheme.textTertiary(ctx),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppTheme.accent(context);
    final inactiveColor = AppTheme.textTertiary(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.bg(context),
      body: Stack(
        children: [
          AnimatedIndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onNavItemTapped,
              destinations: [
                FloatingBottomBarItem(
                  icon: SvgPicture.asset(
                    'assets/icons/home_16.svg',
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      inactiveColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  activeIcon: SvgPicture.asset(
                    'assets/icons/home_active_16.svg',
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      selectedColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Inicio',
                ),
                FloatingBottomBarItem(
                  icon: Icon(
                    Icons.sports_soccer_outlined,
                    size: 22,
                    color: inactiveColor,
                  ),
                  activeIcon: Icon(
                    Icons.sports_soccer_rounded,
                    size: 22,
                    color: selectedColor,
                  ),
                  label: 'Fútbol',
                ),
                FloatingBottomBarItem(
                  icon: FaIcon(
                    FontAwesomeIcons.radio,
                    size: 20,
                    color: inactiveColor,
                  ),
                  activeIcon: FaIcon(
                    FontAwesomeIcons.radio,
                    size: 20,
                    color: selectedColor,
                  ),
                  label: 'Radio',
                ),
                FloatingBottomBarItem(
                  icon: const UserAvatar(
                    size: 24,
                    showBorder: false,
                  ),
                  activeIcon: UserAvatar(
                    size: 24,
                    showBorder: true,
                    borderColor: selectedColor,
                  ),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
