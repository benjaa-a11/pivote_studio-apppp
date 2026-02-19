import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseService.initialize();
  debugPrint('🔔 Background message: ${message.messageId}');
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await FirebaseService.initialize();

  // Initialize Notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();

  // AudioManager will be initialized lazily or via the Provider
  final audioManager = AudioManager();

  // IMPORTANTE: NO restringir orientaciones aquí
  // Las pantallas individuales manejarán sus propias orientaciones
  // Esto permite que PlayerScreen pueda rotar a landscape
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
        // ⚡ CRÍTICO: Usar .value para pasar el AudioManager ya inicializado
        ChangeNotifierProvider.value(value: audioManager),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Configurar barra de estado según el tema
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

/// Wrapper to check authentication status and navigate accordingly
class _AuthenticationWrapper extends StatelessWidget {
  const _AuthenticationWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, authSnapshot) {
        // Mientras esperamos el primer valor del stream de autenticación
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final user = authSnapshot.data;

        // Si el usuario no está autenticado, ir login
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FlutterNativeSplash.remove();
          });
          return const LoginScreen();
        }

        // Si está autenticado, esperamos a que los datos estén listos
        return Consumer2<ChannelProvider, SoccerProvider>(
          builder: (context, channelProvider, soccerProvider, child) {
            // Relaxed check: Only depends on channelProvider for the core experience
            // Soccer and Match data can load lazily
            final isDataReady = channelProvider.isInitialized;

            if (isDataReady) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FlutterNativeSplash.remove();
              });
              return const MainScreen();
            }

            // Show a themed loading state if it's taking too long
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Color(0xFF0F172A), // Match splash/app background
            );
          },
        );
      },
    );
  }
}
