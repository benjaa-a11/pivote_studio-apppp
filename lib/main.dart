import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/channel_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/radio_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/match_provider.dart';
import 'providers/soccer_provider.dart';
import 'providers/audio_manager.dart';
import 'config/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/main_screen.dart';
import 'widgets/connectivity_wrapper.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await FirebaseService.initialize();

  // IMPORTANTE: NO restringir orientaciones aquí
  // Las pantallas individuales manejarán sus propias orientaciones
  // Esto permite que PlayerScreen pueda rotar a landscape
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const PivoteApp());
}

class PivoteApp extends StatelessWidget {
  const PivoteApp({super.key});

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
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => SoccerProvider()),
        ChangeNotifierProvider(create: (_) => AudioManager()..initialize()),
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
    return FutureBuilder<bool>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        // While checking authentication, show nothing (splash screen is still visible)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        // Remove splash screen once we know the auth status
        FlutterNativeSplash.remove();

        // Navigate based on authentication status
        // For now, always navigate to MainScreen
        return const MainScreen();
      },
    );
  }

  Future<bool> _checkAuthStatus() async {
    // Add a small delay to ensure smooth transition
    await Future.delayed(const Duration(milliseconds: 300));
    return await AuthService.isLoggedIn();
  }
}
