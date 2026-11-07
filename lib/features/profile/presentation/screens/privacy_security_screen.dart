import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _saveHistory = true;
  bool _privateProfile = false;
  bool _twoFactorEnabled = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _saveHistory = prefs.getBool('privacy_save_history') ?? true;
      _privateProfile = prefs.getBool('privacy_private_profile') ?? false;
      _twoFactorEnabled = prefs.getBool('security_two_factor') ?? true;
    });
  }

  Future<void> _updatePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() {
      if (key == 'privacy_save_history') _saveHistory = value;
      if (key == 'privacy_private_profile') _privateProfile = value;
      if (key == 'security_two_factor') _twoFactorEnabled = value;
    });
  }

  void _showTwoFactorSheet() {
    final palette = ProfilePalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'Verificación en dos pasos',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
                ProfileGroupCard(
                  children: [
                    ProfileGroupRow(
                      title: 'Protección en dos pasos',
                      subtitle:
                          'Solicitar confirmación adicional al iniciar sesión en un dispositivo nuevo',
                      onTap: () {
                        final next = !_twoFactorEnabled;
                        _updatePref('security_two_factor', next);
                        Navigator.pop(ctx);
                      },
                      trailing: ProfileSwitch(
                        value: _twoFactorEnabled,
                        onChanged: (val) {
                          _updatePref('security_two_factor', val);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConnectedDevicesSheet() {
    final palette = ProfilePalette.of(context);
    final email = context.read<UserProvider>().user?.email ?? 'Sesión activa';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'Dispositivos conectados',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
                ProfileGroupCard(
                  children: [
                    ProfileGroupRow(
                      title: 'Este dispositivo',
                      subtitle: '$email · En línea ahora',
                      valueText: 'Actual',
                    ),
                    const ProfileGroupRow(
                      title: 'Pivote Web / Smart TV',
                      subtitle: 'Sincronizado con tu cuenta',
                      valueText: 'Activo',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: '¿Eliminar tu cuenta?',
      message:
          'Esta acción es permanente e irreversible. Se borrarán tus datos y preferencias.',
      confirmLabel: 'Eliminar cuenta',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.error,
    );
    if (confirmed != true || !mounted) return;

    final userProvider = context.read<UserProvider>();
    final navigator = Navigator.of(context);
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _deleting = true);

    try {
      await userProvider.deleteAccount();
      if (!mounted) return;
      await navigator.pushAndRemoveUntil(
        AppAnimations.createFadeRoute(const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(context, 'No se pudo eliminar la cuenta');
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubsectionScaffold(
      title: 'Privacidad',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Privacidad', first: true),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Guardar historial',
                    subtitle: 'Registrar lo que reproducís',
                    onTap: () =>
                        _updatePref('privacy_save_history', !_saveHistory),
                    trailing: ProfileSwitch(
                      value: _saveHistory,
                      onChanged: (v) => _updatePref('privacy_save_history', v),
                    ),
                  ),
                  ProfileGroupRow(
                    title: 'Perfil privado',
                    subtitle: 'Solo vos ves tus favoritos',
                    onTap: () => _updatePref(
                        'privacy_private_profile', !_privateProfile),
                    trailing: ProfileSwitch(
                      value: _privateProfile,
                      onChanged: (v) =>
                          _updatePref('privacy_private_profile', v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Seguridad'),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Cambiar contraseña',
                    showChevron: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppAnimations.createRoute(
                          const EditProfileScreen(focusPassword: true),
                        ),
                      );
                    },
                  ),
                  ProfileGroupRow(
                    title: 'Verificación en dos pasos',
                    valueText: _twoFactorEnabled ? 'Activada' : 'Desactivada',
                    showChevron: true,
                    onTap: _showTwoFactorSheet,
                  ),
                  ProfileGroupRow(
                    title: 'Dispositivos conectados',
                    valueText: '2',
                    showChevron: true,
                    onTap: _showConnectedDevicesSheet,
                  ),
                ],
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 2,
          child: ProfileActionButton(
            label: 'Eliminar cuenta',
            variant: ProfileButtonVariant.danger,
            loading: _deleting,
            onTap: _deleteAccount,
          ),
        ),
      ],
    );
  }
}
