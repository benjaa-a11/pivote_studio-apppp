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
  late final TextEditingController _nameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  bool _saving = false;
  bool _passwordOpen = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<UserProvider>();
    final user = provider.user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final updated = user.copyWith(
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      if (updated.name != user.name || updated.lastName != user.lastName) {
        await AuthService.updateUser(updated);
        await provider.refreshUser();
      }

      if (_passwordOpen && _newPasswordController.text.trim().isNotEmpty) {
        await provider.updatePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );
      }

      if (!mounted) return;
      AppNotifications.showSuccess(context, 'Perfil actualizado correctamente');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(context, 'No se pudo guardar el perfil: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: '¿Eliminar tu cuenta?',
      message: 'Esta acción es permanente e irreversible.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.error,
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await context.read<UserProvider>().deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppAnimations.createFadeRoute(const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(context, 'No se pudo eliminar la cuenta: $e');
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<UserProvider>();
    final user = provider.user;
    final imagePath = provider.profileImagePath;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Editar perfil',
        subtitle: 'Actualizá tus datos personales',
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
            children: [
              _buildAvatar(theme, provider, imagePath, user?.photoUrl),
              const SizedBox(height: 24),
              Text('Información personal', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(_nameController, 'Nombre', Icons.person_outline_rounded, theme),
                    const SizedBox(height: 10),
                    _field(_lastNameController, 'Apellido', Icons.badge_outlined, theme),
                    const SizedBox(height: 22),
                    _buildPasswordCard(theme),
                    const SizedBox(height: 22),
                    _buildSecurityCard(theme),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text('Guardar cambios', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _saving ? null : _deleteAccount,
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Eliminar mi cuenta'),
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_saving) const Positioned.fill(child: ColoredBox(color: Color(0x66000000), child: Center(child: PivoteLoader(size: 40)))),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, UserProvider provider, String? imagePath, String? photoUrl) {
    ImageProvider<Object>? image;
    if (imagePath != null) {
      image = FileImage(File(imagePath));
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      image = NetworkImage(photoUrl);
    }

    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.primary, width: 2)),
            child: CircleAvatar(
              radius: 58,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: image,
              child: image == null ? Icon(Icons.person_rounded, size: 56, color: theme.colorScheme.primary) : null,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: provider.updateProfileImage,
                customBorder: const CircleBorder(),
                child: const Padding(padding: EdgeInsets.all(9), child: Icon(Icons.camera_alt_rounded, size: 17, color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: theme.dividerColor.withValues(alpha: .08))),
      child: TextFormField(
        controller: controller,
        validator: (value) => value == null || value.trim().isEmpty ? 'Este campo es requerido' : null,
        style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          hintText: label,
          prefixIcon: Icon(icon, size: 19, color: theme.colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildPasswordCard(ThemeData theme) {
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: _passwordOpen ? null : () => setState(() => _passwordOpen = true),
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _passwordOpen
              ? Column(
                  children: [
                    _passwordField(_currentPasswordController, 'Contraseña actual', Icons.lock_outline_rounded),
                    const SizedBox(height: 10),
                    _passwordField(_newPasswordController, 'Nueva contraseña', Icons.lock_reset_rounded),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => setState(() { _passwordOpen = false; _currentPasswordController.clear(); _newPasswordController.clear(); }), child: const Text('Cancelar cambio')),
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Cambiar contraseña', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800))),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _passwordField(TextEditingController controller, String hint, IconData icon) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: true,
      validator: (value) => value != null && value.isNotEmpty && value.length < 6 ? 'Mínimo 6 caracteres' : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: .1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: .1))),
      ),
    );
  }

  Widget _buildSecurityCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: .06), borderRadius: BorderRadius.circular(17), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: .12))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 11),
          Expanded(child: Text('Mantené tus datos actualizados y usá una contraseña segura para proteger tu cuenta.', style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.hintColor, height: 1.45))),
        ],
      ),
    );
  }
}
