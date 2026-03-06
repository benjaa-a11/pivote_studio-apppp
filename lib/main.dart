import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        ChangeNotifierProxyProvider<ThemeProvider, ChannelProvider>(
          create: (context) => ChannelProvider(context.read<ThemeProvider>()),
          update: (context, themeProvider, channelProvider) =>
              channelProvider!..setDarkMode(themeProvider.isDarkMode),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => RadioProvider()),
        ChangeNotifierProvider(create: (_) => SoccerProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
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

class _AuthenticationWrapper extends StatelessWidget {
  const _AuthenticationWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, authSnapshot) {
        if (!FirebaseService.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FlutterNativeSplash.remove();
          });
          return const FirebaseRequiredScreen();
        }
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final user = authSnapshot.data;
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FlutterNativeSplash.remove();
          });
          return const LoginScreen();
        }
        return Consumer2<ChannelProvider, SoccerProvider>(
          builder: (context, channelProvider, soccerProvider, child) {
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
                        child: CircularProgressIndicator(
                          color: AppTheme.darkAccent,
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}