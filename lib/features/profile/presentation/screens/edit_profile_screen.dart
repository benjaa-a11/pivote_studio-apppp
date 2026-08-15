import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _lastName;
  late final TextEditingController _currentPassword;
  late final TextEditingController _newPassword;
  bool _loading = false;
  bool _passwordOpen = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _currentPassword = TextEditingController();
    _newPassword = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _lastName.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<UserProvider>();
    final user = provider.user;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      if (user.name != _name.text.trim() || user.lastName != _lastName.text.trim()) {
        await AuthService.updateUser(user.copyWith(name: _name.text.trim(), lastName: _lastName.text.trim()));
        await provider.refreshUser();
      }
      if (_passwordOpen && _newPassword.text.isNotEmpty) {
        try {
          await provider.updatePassword(_currentPassword.text, _newPassword.text);
          if (mounted) AppNotifications.showSuccess(context, 'Contraseña actualizada');
          _newPassword.clear();
          _passwordOpen = false;
        } catch (e) {
          if (e.toString().contains('requires-recent-login')) {
            if (mounted) AppNotifications.showError(context, 'Por seguridad, iniciá sesión nuevamente para cambiar tu contraseña');
          } else {
            rethrow;
          }
        }
      }
      if (!mounted) return;
      AppNotifications.showSuccess(context, 'Perfil actualizado correctamente');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) AppNotifications.showError(context, 'No pudimos guardar los cambios');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await AppDialogs.showConfirm(
      context: context,
      title: '¿Eliminar tu cuenta?',
      message: 'Esta acción es permanente e irreversible. Se eliminarán tus datos, favoritos e historial.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.error,
    );
    if (ok != true) return;
    setState(() => _loading = true);
    try {
      await context.read<UserProvider>().deleteAccount();
      if (!mounted) return;
      AppNotifications.showSuccess(context, 'Tu cuenta fue eliminada');
      Navigator.of(context).pushAndRemoveUntil(AppAnimations.createFadeRoute(const LoginScreen()), (route) => false);
    } catch (e) {
      if (mounted) AppNotifications.showError(context, e.toString().contains('requires-recent-login') ? 'Por seguridad, necesitás haber iniciado sesión recientemente' : 'No pudimos eliminar tu cuenta');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final imagePath = userProvider.profileImagePath;
    final dark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(title: 'Editar perfil', subtitle: 'Actualizá tu información personal'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 34),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: dark ? [accent.withValues(alpha: .12), theme.colorScheme.surface] : [accent.withValues(alpha: .08), Colors.white]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withValues(alpha: .11)),
                ),
                child: Column(children: [
                  Stack(children: [
                    Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent.withValues(alpha: .55), width: 2)), child: CircleAvatar(radius: 52, backgroundColor: accent.withValues(alpha: .08), backgroundImage: imagePath != null ? FileImage(File(imagePath)) : (user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null) as ImageProvider?, child: imagePath == null && user?.photoUrl == null ? Icon(Icons.person_rounded, size: 50, color: accent) : null)),
                    Positioned(right: 1, bottom: 1, child: Material(color: accent, shape: const CircleBorder(), child: InkWell(onTap: userProvider.updateProfileImage, customBorder: const CircleBorder(), child: const Padding(padding: EdgeInsets.all(9), child: Icon(Icons.camera_alt_rounded, size: 15, color: Colors.black))))),
                  ]),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Tu perfil', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(user?.email ?? '', style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor)),
                ]),
              ),
              const SizedBox(height: 22),
              Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _section(context, 'Información personal'),
                  const SizedBox(height: 9),
                  _field(context, _name, 'Nombre', Icons.person_outline_rounded),
                  const SizedBox(height: 9),
                  _field(context, _lastName, 'Apellido', Icons.badge_outlined),
                  const SizedBox(height: 20),
                  _section(context, 'Seguridad'),
                  const SizedBox(height: 9),
                  if (!_passwordOpen)
                    _action(context, Icons.lock_reset_rounded, 'Cambiar contraseña', 'Actualizá tu contraseña de acceso', () => setState(() => _passwordOpen = true), accent)
                  else ...[
                    _field(context, _currentPassword, 'Contraseña actual', Icons.lock_outline_rounded, password: true, validatePassword: true),
                    const SizedBox(height: 9),
                    _field(context, _newPassword, 'Nueva contraseña', Icons.lock_reset_rounded, password: true, validatePassword: true),
                    const SizedBox(height: 7),
                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () { setState(() { _passwordOpen = false; _newPassword.clear(); }); }, child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.error)))),
                  ],
                  const SizedBox(height: 13),
                  Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: accent.withValues(alpha: .06), borderRadius: BorderRadius.circular(17), border: Border.all(color: accent.withValues(alpha: .1))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.verified_user_rounded, color: accent, size: 18), const SizedBox(width: 9), Expanded(child: Text('Tus datos de perfil se sincronizan con tu cuenta. Pivote no necesita que compartas tu contraseña con nadie.', style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.4)))])),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(onPressed: _loading ? null : _save, icon: const Icon(Icons.check_rounded, size: 18), label: Text('Guardar cambios', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900)), style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0))),
                  const SizedBox(height: 12),
                  TextButton.icon(onPressed: _loading ? null : _delete, icon: const Icon(Icons.delete_forever_rounded, size: 18), label: Text('Eliminar mi cuenta', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900)), style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error)),
                ]),
              ),
            ],
          ),
          if (_loading) Container(color: Colors.black.withValues(alpha: .22), child: const Center(child: PivoteLoader(size: 40))),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900));

  Widget _field(BuildContext context, TextEditingController controller, String label, IconData icon, {bool password = false, bool validatePassword = false}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: theme.dividerColor.withValues(alpha: .08))),
      child: TextFormField(
        controller: controller,
        obscureText: password,
        style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600),
        validator: (value) {
          if (!password && (value == null || value.trim().isEmpty)) return 'Este campo es requerido';
          if (password && validatePassword && _passwordOpen && value != null && value.isNotEmpty && value.length < 6) return 'Mínimo 6 caracteres';
          return null;
        },
        decoration: InputDecoration(isDense: true, hintText: label, prefixIcon: Icon(icon, size: 19, color: theme.colorScheme.primary), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12)),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, Color accent) {
    final theme = Theme.of(context);
    return Material(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(17), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: accent.withValues(alpha: .1))), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: accent.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 19, color: accent)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: theme.hintColor))])), Icon(Icons.arrow_forward_ios_rounded, size: 11, color: theme.hintColor)])));
  }
}
