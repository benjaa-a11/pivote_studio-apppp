import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/radio/presentation/providers/radio_provider.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/radio/presentation/providers/audio_manager.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/firebase_service.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/home/presentation/screens/main_screen.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pivote/shared/widgets/connectivity_wrapper.dart';
import 'package:pivote/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/features/soccer/data/services/soccer_service.dart';
import 'package:pivote/shared/screens/firebase_required_screen.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';
import 'package:pivote/features/auth/presentation/screens/suspended_screen.dart';
import 'package:pivote/features/movies/presentation/providers/movies_provider.dart';

import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/services/wakelock_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseService.initialize();
  debugPrint('🔔 Background message: ${message.messageId}');
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await FirebaseService.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initializeWithoutPermission();

  // Initialize custom auth session
  await AuthService.initSession();

  SoccerService.prefetchLiveSoccerData();
  final audioManager = AudioManager();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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
        ChangeNotifierProvider(create: (_) => MoviesProvider()),
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
              title: 'Pivote',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode:
                  themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const _AuthenticationWrapper(),
              routes: const {},
            ),
          );
        },
      ),
    );
  }
}

class _AuthenticationWrapper extends StatefulWidget {
  const _AuthenticationWrapper();

  @override
  State<_AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<_AuthenticationWrapper> {
  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (!FirebaseService.isInitialized) {
      setState(() {
        _isCheckingAuth = false;
        _isLoggedIn = false;
      });
      return;
    }

    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (loggedIn) {
        // Let's verify with Firestore that the user isn't suspended!
        final user = await AuthService.getUser();
        if (user == null) {
          await AuthService.logout();
          if (mounted) {
            setState(() {
              _isLoggedIn = false;
              _isCheckingAuth = false;
            });
          }
        } else {
          // Sync local UserProvider state as well
          if (mounted) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

            if (userProvider.user == null) {
              await userProvider.refreshUser();
            }

            // Trigger favorites sync too!
            favoritesProvider.refreshFromFirestore();

            // Trigger FCM token sync too!
            NotificationService.getToken().then((token) {
              if (token != null) {
                AuthService.updateFcmToken(token);
              }
            });

            setState(() {
              _isLoggedIn = true;
              _isCheckingAuth = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _isCheckingAuth = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ _AuthenticationWrapper: Error checking auth: $e');
      // Fallback to local session check if there's no internet/transient error
      final loggedIn = await AuthService.isLoggedIn();
      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseService.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
      return const FirebaseRequiredScreen();
    }

    if (_isCheckingAuth) {
      return const SizedBox.shrink();
    }

    if (!_isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
      return const LoginScreen();
    }

    return Consumer3<UserProvider, ChannelProvider, SoccerProvider>(
      builder: (context, userProvider, channelProvider, soccerProvider, child) {
        // If user is suspended, show the elegant suspended account screen immediately
        if (userProvider.user?.isSuspended == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FlutterNativeSplash.remove();
          });
          return const SuspendedScreen();
        }

        final isDataReady = channelProvider.isInitialized;
        if (isDataReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FlutterNativeSplash.remove();
          });
          return const MainScreen();
        }
        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          body: Center(
            child: AppAnimations.smoothFadeInScale(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.darkBg,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      errorBuilder: (context, _, __) => const Icon(
                        Icons.play_circle_fill,
                        size: 60,
                        color: AppTheme.darkAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: PivoteLoader(
                      color: AppTheme.darkAccent,
                      strokeWidth: 3,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
