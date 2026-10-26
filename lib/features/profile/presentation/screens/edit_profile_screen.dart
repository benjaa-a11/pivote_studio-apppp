import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
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
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;

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

    await HapticFeedback.mediumImpact();
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
      message:
          'Esta acción es permanente e irreversible. Se borrarán tus datos y preferencias.',
      confirmLabel: 'Eliminar cuenta',
      cancelLabel: 'Cancelar',
      isDestructive: true,
      type: AppDialogType.error,
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await userProvider.deleteAccount();
      if (!mounted) return;
      await navigator.pushAndRemoveUntil(
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
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<UserProvider>();
    final user = provider.user;
    final imagePath = provider.profileImagePath;
    final primaryColor =
        isDark ? AppTheme.darkAccent : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const PivoteAppBar(
        title: 'Editar perfil',
        subtitle: 'Actualizá tus datos personales y seguridad',
      ),
      body: Stack(
        children: [
          ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              _buildAvatar(theme, isDark, primaryColor, provider, imagePath,
                  user?.photoUrl),
              const SizedBox(height: 28),
              Text(
                'Información personal',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(
                        _nameController,
                        'Nombre',
                        Icons.person_outline_rounded,
                        theme,
                        isDark,
                        primaryColor),
                    const SizedBox(height: 12),
                    _field(_lastNameController, 'Apellido',
                        Icons.badge_outlined, theme, isDark, primaryColor),
                    const SizedBox(height: 24),
                    _buildPasswordCard(theme, isDark, primaryColor),
                    const SizedBox(height: 20),
                    _buildSecurityCard(theme, isDark, primaryColor),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          'Guardar cambios',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _saving ? null : _deleteAccount,
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: Text(
                        'Eliminar mi cuenta definitivamente',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_saving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(child: PivoteLoader(size: 40)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    ThemeData theme,
    bool isDark,
    Color primaryColor,
    UserProvider provider,
    String? imagePath,
    String? photoUrl,
  ) {
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.8),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 58,
              backgroundColor: primaryColor.withValues(alpha: 0.12),
              backgroundImage: image,
              child: image == null
                  ? Icon(Icons.person_rounded, size: 56, color: primaryColor)
                  : null,
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Material(
              color: primaryColor,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  provider.updateProfileImage();
                },
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
    ThemeData theme,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Este campo es requerido'
            : null,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: label,
          hintStyle: GoogleFonts.spaceGrotesk(
            color: theme.hintColor.withValues(alpha: 0.5),
            fontSize: 13.5,
          ),
          prefixIcon: Icon(icon, size: 20, color: primaryColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordCard(ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap:
              _passwordOpen ? null : () => setState(() => _passwordOpen = true),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _passwordOpen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_reset_rounded,
                              color: primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Actualizar contraseña',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _passwordField(
                        _currentPasswordController,
                        'Contraseña actual',
                        Icons.lock_outline_rounded,
                        _obscureCurrentPass,
                        () => setState(
                            () => _obscureCurrentPass = !_obscureCurrentPass),
                        theme,
                        isDark,
                        primaryColor,
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        _newPasswordController,
                        'Nueva contraseña',
                        Icons.lock_rounded,
                        _obscureNewPass,
                        () =>
                            setState(() => _obscureNewPass = !_obscureNewPass),
                        theme,
                        isDark,
                        primaryColor,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() {
                            _passwordOpen = false;
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                          }),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.spaceGrotesk(
                              color: theme.hintColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.lock_reset_rounded,
                            color: primaryColor, size: 19),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cambiar contraseña',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: theme.hintColor),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String hint,
    IconData icon,
    bool obscure,
    VoidCallback toggleObscure,
    ThemeData theme,
    bool isDark,
    Color primaryColor,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: (value) =>
          value != null && value.isNotEmpty && value.length < 6
              ? 'Mínimo 6 caracteres'
              : null,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.spaceGrotesk(
          color: theme.hintColor.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, size: 19, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 19,
            color: theme.hintColor,
          ),
          onPressed: toggleObscure,
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkBg2 : theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSecurityCard(ThemeData theme, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withValues(alpha: .15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tus datos personales y credenciales están cifrados. Mantené tu información al día para una experiencia segura.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.hintColor,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
