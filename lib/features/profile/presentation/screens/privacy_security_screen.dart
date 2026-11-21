import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _saveHistory = true;
  bool _privateProfile = false;

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
    });
  }

  Future<void> _updatePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() {
      if (key == 'privacy_save_history') _saveHistory = value;
      if (key == 'privacy_private_profile') _privateProfile = value;
    });
  }

  void _showConnectedDevicesSheet() {
    final user = context.read<UserProvider>().user;
    final email = user?.email ?? 'Sesión activa';
    final maxDevices = user?.maxDispositivos ?? 1;
    final linkedCount = user?.dispositivos.length ??
        ((user?.deviceId != null && user!.deviceId!.isNotEmpty) ? 1 : 0);

    AppDialogs.showModal<void>(
      context: context,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PivoteSheetHeader(
                title: 'Dispositivos autorizados',
                subtitle: 'Límite de tu cuenta: $linkedCount / $maxDevices',
                icon: Icons.devices_rounded,
              ),
              const SizedBox(height: 16),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    leading: const ProfileSettingIconBox(
                      icon: Icons.smartphone_rounded,
                      highlight: true,
                    ),
                    title: 'Este dispositivo',
                    subtitle: '$email · Sesión verificada',
                    valueText: 'Activo',
                  ),
                  ProfileGroupRow(
                    leading: const ProfileSettingIconBox(
                      icon: Icons.shield_outlined,
                    ),
                    title: 'Cambio de dispositivo',
                    subtitle:
                        'Si cambiás de equipo, pedí al administrador que resetee tu dispositivo.',
                    valueText: 'Máx. $maxDevices',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestAccountRemovalInfo() {
    AppDialogs.showAlert(
      context: context,
      title: 'Baja de cuenta privada',
      message:
          'Al ser una app con acceso privado administrado, la baja definitiva de cuentas se gestiona directamente con el administrador.',
      type: AppDialogType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final maxDevices = user?.maxDispositivos ?? 1;

    return ProfileSubsectionScaffold(
      title: 'Privacidad y seguridad',
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
                    subtitle: 'Registrar los canales que reproducís',
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
                      'privacy_private_profile',
                      !_privateProfile,
                    ),
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
                    title: 'Dispositivos autorizados',
                    valueText: 'Máx. $maxDevices',
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
            label: 'Solicitar baja de cuenta',
            variant: ProfileButtonVariant.soft,
            onTap: _showRequestAccountRemovalInfo,
          ),
        ),
      ],
    );
  }
}
