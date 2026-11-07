import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/features/profile/presentation/screens/privacy_security_screen.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
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
    _nameController = TextEditingController(text: user?.name ?? '')
      ..addListener(_onTextChanged);
    _lastNameController = TextEditingController(text: user?.lastName ?? '')
      ..addListener(_onTextChanged);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _lastNameController.removeListener(_onTextChanged);
    _nameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
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
    final activityService = context.watch<AppActivityService>();
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
            children: [
              AppAnimations.staggeredSlideIn(
                index: 0,
                child: _buildProfilePreviewHero(
                  theme,
                  isDark,
                  primaryColor,
                  provider,
                  activityService,
                  imagePath,
                  user?.photoUrl,
                  user?.email,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAnimations.staggeredSlideIn(
                      index: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(theme, 'DATOS PERSONALES'),
                          const SizedBox(height: 10),
                          _labeledField(
                            controller: _nameController,
                            label: 'Nombre',
                            hint: 'Tu nombre',
                            icon: Icons.person_outline_rounded,
                            theme: theme,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _labeledField(
                            controller: _lastNameController,
                            label: 'Apellido',
                            hint: 'Tu apellido',
                            icon: Icons.badge_outlined,
                            theme: theme,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _readOnlyEmailCard(
                            theme,
                            isDark,
                            primaryColor,
                            user?.email ?? 'Sin correo asociado',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppAnimations.staggeredSlideIn(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(theme, 'CREDENCIALES Y SEGURIDAD'),
                          const SizedBox(height: 10),
                          _buildPasswordCard(theme, isDark, primaryColor),
                          const SizedBox(height: 12),
                          _buildConnectedSecurityBanner(
                              context, theme, isDark, primaryColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppAnimations.staggeredSlideIn(
                      index: 3,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 20,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                              label: Text(
                                'Guardar cambios',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor:
                                    isDark ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _buildDangerZone(theme, isDark),
                        ],
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

  Widget _sectionTitle(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _buildProfilePreviewHero(
    ThemeData theme,
    bool isDark,
    Color primaryColor,
    UserProvider provider,
    AppActivityService activityService,
    String? imagePath,
    String? photoUrl,
    String? email,
  ) {
    ImageProvider<Object>? image;
    if (imagePath != null) {
      image = FileImage(File(imagePath));
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      image = NetworkImage(photoUrl);
    }

    final liveName =
        '${_nameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
        ),
        boxShadow: AppShadows.appleDepth(context, elevation: 0.8),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
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
                  radius: 48,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                  backgroundImage: image,
                  child: image == null
                      ? Icon(Icons.person_rounded,
                          size: 48, color: primaryColor)
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: ApplePressable(
                  scaleDownFactor: 0.90,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.updateProfileImage();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark ? const Color(0xFF131722) : Colors.white,
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            liveName.isNotEmpty ? liveName : 'Usuario Pivote',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            email ?? 'Cuenta activa',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activityService.getArgentineRankEmoji(),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 6),
                Text(
                  '${activityService.getArgentineRank()} · Miembro desde ${activityService.getFormattedStartDate()}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
        ),
      ),
      child: TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Este campo es requerido'
            : null,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.spaceGrotesk(
            color: theme.hintColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: GoogleFonts.spaceGrotesk(
            color: primaryColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          prefixIcon: Icon(icon, size: 20, color: primaryColor),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _readOnlyEmailCard(
    ThemeData theme,
    bool isDark,
    Color primaryColor,
    String email,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF131722).withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.alternate_email_rounded,
                size: 18, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correo electrónico vinculado',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'VERIFICADO',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard(ThemeData theme, bool isDark, Color primaryColor) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _passwordOpen
                ? primaryColor.withValues(alpha: 0.35)
                : (isDark ? const Color(0xFF1E2533) : AppTheme.lightBorder),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: _passwordOpen
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _passwordOpen = true);
                  },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _passwordOpen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(Icons.lock_reset_rounded,
                                  color: primaryColor, size: 19),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Actualizar contraseña',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _passwordOpen = false;
                                _currentPasswordController.clear();
                                _newPasswordController.clear();
                              }),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.spaceGrotesk(
                                  color: theme.hintColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                          'Nueva contraseña (mín. 6 caracteres)',
                          Icons.lock_rounded,
                          _obscureNewPass,
                          () => setState(
                              () => _obscureNewPass = !_obscureNewPass),
                          theme,
                          isDark,
                          primaryColor,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.lock_reset_rounded,
                              color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cambiar contraseña',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Actualizá tu clave de acceso de forma segura',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: theme.hintColor),
                      ],
                    ),
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
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 19,
            color: theme.hintColor,
          ),
          onPressed: toggleObscure,
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
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

  Widget _buildConnectedSecurityBanner(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Color primaryColor,
  ) {
    return ApplePressable(
      scaleDownFactor: 0.98,
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          AppAnimations.createRoute(const PrivacySecurityScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryColor.withValues(alpha: .16)),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: primaryColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Centro de Privacidad y Seguridad',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tus datos están protegidos con cifrado SSL. Toca para ver detalles.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zona de peligro',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.error,
                  ),
                ),
                Text(
                  'Eliminar tu cuenta y datos permanentemente',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _saving ? null : _deleteAccount,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
