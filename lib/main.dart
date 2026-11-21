import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/favorites/data/services/viewing_history_service.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/home/presentation/screens/main_screen.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/features/auth/presentation/screens/account_status_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pivote/shared/widgets/connectivity_wrapper.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/features/soccer/data/services/soccer_service.dart';
import 'package:pivote/shared/screens/firebase_required_screen.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/wakelock_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/features/home/presentation/providers/notifications_provider.dart';

/// Navigator global para poder cerrar cualquier subpantalla (incluido el reproductor)
/// al instante si la cuenta es revocada en tiempo real desde el panel admin.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  try {
    await FirebaseService.initialize();
    debugPrint('🔔 Background message: ${message.messageId}');
  } catch (e) {
    debugPrint('⚠️ Error in background message handler: $e');
  }
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    } catch (e) {
      debugPrint('⚠️ Error preserving native splash: $e');
    }
  } else {
    try {
      FlutterNativeSplash.remove();
    } catch (e) {
      debugPrint('⚠️ Error removing web splash: $e');
    }
  }

  try {
    ImageCacheHelper.configurePaintingCache();
  } catch (e) {
    debugPrint('⚠️ Error configuring image cache: $e');
  }

  try {
    await FirebaseService.initialize();
  } catch (e) {
    debugPrint('❌ Error initializing Firebase in main: $e');
  }

  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      await NotificationService.initializeWithoutPermission();
    } catch (e) {
      debugPrint('⚠️ Error initializing notifications in main: $e');
    }
  }

  try {
    await AuthService.initSession();
  } catch (e) {
    debugPrint('⚠️ Error initializing AuthService session: $e');
  }

  try {
    SoccerService.prefetchLiveSoccerData();
  } catch (e) {
    debugPrint('⚠️ Error prefetching soccer data: $e');
  }

  late final AudioManager audioManager;
  try {
    audioManager = AudioManager();
  } catch (e) {
    debugPrint('⚠️ Error creating AudioManager: $e');
  }

  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e) {
      debugPrint('⚠️ Error setting preferred orientations: $e');
    }
  }

  runApp(PivoteApp(audioManager: audioManager));
}

class PivoteApp extends StatelessWidget {
  final AudioManager audioManager;
  const PivoteApp({super.key, required this.audioManager});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppActivityService()),
        ChangeNotifierProvider(create: (_) => WakelockService()),
        ChangeNotifierProxyProvider<ThemeProvider, ChannelProvider>(
          create: (context) => ChannelProvider(context.read<ThemeProvider>()),
          update: (context, themeProvider, channelProvider) =>
              channelProvider!..setDarkMode(themeProvider.isDarkMode),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => RadioProvider()),
        ChangeNotifierProvider(create: (_) => SoccerProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider.value(value: audioManager),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
              statusBarBrightness:
                  themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
            ),
          );
          return ConnectivityWrapper(
            child: MaterialApp(
              navigatorKey: rootNavigatorKey,
              title: 'Pivote',
              debugShowCheckedModeBanner: false,
              scrollBehavior: const _NoBounceScrollBehavior(),
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler:
                        TextScaler.linear(themeProvider.textScaleFactor),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const _AuthenticationWrapper(),
              routes: const {},
            ),
          );
        },
      ),
    );
  }
}

class _NoBounceScrollBehavior extends MaterialScrollBehavior {
  const _NoBounceScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _AuthenticationWrapper extends StatefulWidget {
  const _AuthenticationWrapper();

  @override
  State<_AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<_AuthenticationWrapper> {
  String? _hydratedUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      userProvider.setOnSessionRevoked(_handleRealtimeRevocation);
      if (FirebaseService.isInitialized) {
        unawaited(userProvider.checkInitialAuth());
      }
    });
  }

  @override
  void dispose() {
    try {
      context.read<UserProvider>().setOnSessionRevoked(null);
    } catch (_) {}
    super.dispose();
  }

  /// Expulsión inmediata si el admin desactiva la cuenta o vence el plan mientras se usa la app.
  void _handleRealtimeRevocation() {
    _clearSessionScopedProviders();
    // Cerrar cualquier subpantalla abierta (player, perfil, etc.) y volver a la raíz
    rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  /// Carga contenido protegido y sincroniza preferencias persistentes SOLO tras verificar acceso activo.
  void _hydrateForActiveUser(String uid) {
    if (_hydratedUid == uid) return;
    _hydratedUid = uid;

    final channelProvider = context.read<ChannelProvider>();
    final radioProvider = context.read<RadioProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();
    final activityService = context.read<AppActivityService>();

    unawaited(channelProvider.loadChannelsFromFirestore());
    unawaited(radioProvider.loadForAuthenticatedUser());
    unawaited(favoritesProvider.refreshFromFirestore());
    unawaited(ViewingHistoryService.syncFromCloud().then((_) {
      if (mounted) {
        unawaited(channelProvider.refreshViewCounts());
      }
    }));
    unawaited(activityService.onUserLogin());
  }

  /// Limpia datos en memoria/caché local al salir o ser revocado (SIN borrar la nube).
  void _clearSessionScopedProviders() {
    if (_hydratedUid == null) return;
    _hydratedUid = null;

    if (!mounted) return;
    context.read<ChannelProvider>().clearOnLogout();
    context.read<RadioProvider>().clearOnLogout();
    context.read<FavoritesProvider>().clearLocalFavorites();
    unawaited(ViewingHistoryService.clearLocalCache());
    unawaited(context.read<AppActivityService>().onUserLogout());
  }

  void _removeSplash() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseService.isInitialized) {
      _removeSplash();
      return const FirebaseRequiredScreen();
    }

    return Consumer2<UserProvider, ChannelProvider>(
      builder: (context, userProvider, channelProvider, child) {
        switch (userProvider.authStatus) {
          case AuthGateStatus.checking:
            return const _BrandedStartupView();

          case AuthGateStatus.unauthenticated:
            if (_hydratedUid != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _clearSessionScopedProviders();
              });
            }
            _removeSplash();
            return const LoginScreen();

          case AuthGateStatus.blocked:
            if (_hydratedUid != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _clearSessionScopedProviders();
              });
            }
            _removeSplash();
            return AccountStatusScreen(
              info: userProvider.blockInfo ??
                  const AccountBlockInfo(reason: AccountBlockReason.pending),
            );

          case AuthGateStatus.authenticatedActive:
            final user = userProvider.user;
            if (user == null || !user.hasValidAccess) {
              _removeSplash();
              return AccountStatusScreen(
                info: AccountBlockInfo(
                  reason: user?.blockReason ?? AccountBlockReason.pending,
                  email: user?.email,
                  vence: user?.vence,
                  plan: user?.plan,
                ),
              );
            }

            if (_hydratedUid != user.uid) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _hydrateForActiveUser(user.uid);
              });
            }

            if (!channelProvider.isInitialized) {
              return const _BrandedStartupView();
            }

            _removeSplash();
            return const MainScreen();
        }
      },
    );
  }
}

class _BrandedStartupView extends StatelessWidget {
  const _BrandedStartupView();

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        intensity: 1.35,
        child: Center(
          child: AppAnimations.smoothFadeInScale(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PivoteDiffusedCard(
                  borderRadius: 28,
                  glowColor: accent,
                  glowAlignment: const Alignment(0.0, -0.6),
                  glowOpacity: 1.4,
                  highlighted: true,
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: SvgPicture.asset(
                      'assets/logo.svg',
                      width: 68,
                      height: 68,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 3.5,
                      backgroundColor: AppTheme.surface3(context),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
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
}
