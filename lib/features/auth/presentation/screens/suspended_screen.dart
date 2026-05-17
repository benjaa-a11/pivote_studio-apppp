import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class SuspendedScreen extends StatefulWidget {
  const SuspendedScreen({super.key});

  @override
  State<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends State<SuspendedScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.refreshUser();

      if (mounted) {
        final user = userProvider.user;
        if (user != null && !user.isSuspended) {
          AppNotifications.showSuccess(
            context,
            '¡Tu cuenta ha sido reactivada! Bienvenido de nuevo.',
          );
        } else {
          AppNotifications.showWarning(
            context,
            'Tu cuenta sigue suspendida. Si tienes dudas, ponte en contacto con soporte.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
          context,
          'No se pudo verificar el estado actual. Revisa tu conexión.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Ban Icon
              AppAnimations.smoothFadeInScale(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkDangerDim : AppTheme.lightDangerDim),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? AppTheme.darkDanger : AppTheme.lightDanger).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.gavel_rounded,
                    size: 56,
                    color: isDark ? AppTheme.darkDanger : AppTheme.lightDanger,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              AppAnimations.smoothFadeIn(
                child: Text(
                  'Cuenta Suspendida',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle / Description
              AppAnimations.smoothFadeIn(
                child: Text(
                  'Tu cuenta ha sido suspendida temporalmente por no cumplir con nuestras pautas comunitarias o términos de servicio.\n\nSi crees que esto es un error o tu cuenta ya fue reactivada, haz clic en el botón de abajo para verificar el estado de tu cuenta.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
                  ),
                ),
              ),

              const Spacer(),

              // Buttons
              AppAnimations.smoothFadeIn(
                child: Column(
                  children: [
                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _checkStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.darkAccent : theme.colorScheme.primary,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isChecking
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: PivoteLoader(
                                  color: isDark ? Colors.black : Colors.white,
                                  strokeWidth: 2.5,
                                  size: 24,
                                ),
                              )
                            : Text(
                                'Verificar Estado',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Logout / Close Session Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton(
                        onPressed: _isChecking ? null : () async {
                          final userProvider = context.read<UserProvider>();
                          final favoritesProvider = context.read<FavoritesProvider>();
                          favoritesProvider.clearLocalFavorites();
                          userProvider.stopSyncTimer();
                          await AuthService.logout();
                          await userProvider.clearUser();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cerrar Sesión',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
