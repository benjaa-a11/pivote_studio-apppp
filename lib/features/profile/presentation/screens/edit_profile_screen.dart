import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class EditProfileScreen extends StatefulWidget {
  final bool focusPassword;

  const EditProfileScreen({
    super.key,
    this.focusPassword = false,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final FocusNode _passwordFocusNode = FocusNode();

  bool _saving = false;
  static const String _maskedPassword = '••••••••';

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;

    _nameController = TextEditingController(text: user?.nombre ?? '')
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _lastNameController = TextEditingController(text: user?.apellido ?? '')
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController(text: _maskedPassword);

    if (widget.focusPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _passwordController.clear();
          _passwordFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _showAvatarOptionsSheet() async {
    final userProvider = context.read<UserProvider>();
    final hasImage = userProvider.hasProfileImage;

    final action = await AppDialogs.showModal<String>(
      context: context,
      child: Builder(
        builder: (ctx) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PivoteSheetHeader(
                  title: 'Logo / foto de perfil',
                  subtitle:
                      'Se guarda en tu cuenta en la nube y nunca se pierde al reinstalar',
                  icon: Icons.photo_camera_outlined,
                ),
                const SizedBox(height: 16),
                ProfileGroupCard(
                  children: [
                    ProfileGroupRow(
                      leading: const ProfileSettingIconBox(
                        icon: Icons.photo_library_outlined,
                        highlight: true,
                      ),
                      title: hasImage
                          ? 'Cambiar foto / logo'
                          : 'Subir foto / logo',
                      subtitle: 'Elegir imagen desde tu galería',
                      showChevron: true,
                      onTap: () => Navigator.pop(ctx, 'pick'),
                    ),
                    if (hasImage)
                      ProfileGroupRow(
                        leading: const ProfileSettingIconBox(
                          icon: Icons.delete_outline_rounded,
                        ),
                        title: 'Eliminar foto / logo',
                        subtitle: 'Quitar imagen guardada en tu cuenta',
                        isDanger: true,
                        onTap: () => Navigator.pop(ctx, 'delete'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'pick') {
      try {
        final updated = await userProvider.updateProfileImage();
        if (updated && mounted) {
          AppNotifications.showSuccess(
            context,
            'Logo actualizado y guardado en tu cuenta',
          );
        }
      } catch (e) {
        if (mounted) {
          AppNotifications.showError(context, AuthService.getErrorMessage(e));
        }
      }
    } else if (action == 'delete') {
      final confirm = await AppDialogs.showConfirm(
        context: context,
        title: '¿Eliminar foto de perfil?',
        message: 'Tu logo guardado se eliminará de tu cuenta.',
        confirmLabel: 'Eliminar',
        cancelLabel: 'Cancelar',
        isDestructive: true,
        type: AppDialogType.warning,
      );
      if (confirm != true || !mounted) return;
      try {
        await userProvider.removeProfileImage();
        if (mounted) {
          AppNotifications.showInfo(context, 'Foto de perfil eliminada');
        }
      } catch (e) {
        if (mounted) {
          AppNotifications.showError(context, AuthService.getErrorMessage(e));
        }
      }
    }
  }

  Future<String?> _askCurrentPassword() {
    return AppDialogs.showInputDialog(
      context: context,
      title: 'Confirmar contraseña',
      message: 'Ingresá tu contraseña actual para guardar la nueva clave.',
      hintText: 'Contraseña actual',
      obscureText: true,
      icon: Icons.lock_outline_rounded,
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<UserProvider>();
    final user = provider.user;
    if (user == null) return;

    final firstName = _nameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      AppNotifications.showWarning(context, 'Ingresá tu nombre y apellido');
      return;
    }

    final rawPass = _passwordController.text.trim();
    final passwordChanged = rawPass.isNotEmpty && rawPass != _maskedPassword;

    if (passwordChanged && rawPass.length < 6) {
      AppNotifications.showWarning(
        context,
        'La contraseña debe tener al menos 6 caracteres',
      );
      return;
    }

    String? currentPassword;
    if (passwordChanged) {
      currentPassword = await _askCurrentPassword();
      if (currentPassword == null || currentPassword.isEmpty) {
        return;
      }
    }

    await HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    try {
      final updated = user.copyWith(
        nombre: firstName,
        apellido: lastName,
      );

      await AuthService.updateUser(updated);
      await provider.refreshUser();

      if (passwordChanged && currentPassword != null) {
        await provider.updatePassword(currentPassword, rawPass);
      }

      if (!mounted) return;
      AppNotifications.showSuccess(context, 'Cambios guardados correctamente');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(
        context,
        AuthService.getErrorMessage(e),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final imagePath = userProvider.profileImagePath;
    final photoUrl = user?.photoUrl;

    final currentName = _nameController.text.trim();
    final initial =
        currentName.isNotEmpty ? currentName[0].toUpperCase() : 'U';
    final isVip = user?.isVip == true;

    return ProfileSubsectionScaffold(
      title: 'Editar perfil',
      subtitle: 'Datos personales y credenciales',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 20),
              child: SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatarWithRing(
                      size: 108,
                      avatarBytes: userProvider.avatarBytes,
                      imagePath: imagePath,
                      photoUrl: photoUrl,
                      fallbackInitial: initial,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showAvatarOptionsSheet();
                      },
                    ),
                    Positioned(
                      right: -2,
                      bottom: 2,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showAvatarOptionsSheet();
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent(context),
                            border: Border.all(
                              color: AppTheme.bg(context),
                              width: 3,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 15,
                            color: AppTheme.onAccent(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: ProfileGroupCard(
            children: [
              _EditableProfileField(
                label: 'Nombre',
                controller: _nameController,
                keyboardType: TextInputType.name,
              ),
              _EditableProfileField(
                label: 'Apellido',
                controller: _lastNameController,
                keyboardType: TextInputType.name,
              ),
              _EditableProfileField(
                label: 'Correo electrónico (vinculado a tu cuenta)',
                controller: _emailController,
                readOnly: true,
              ),
              _EditableProfileField(
                label: 'Contraseña',
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: true,
                onTap: () {
                  if (_passwordController.text == _maskedPassword) {
                    _passwordController.clear();
                  }
                },
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Acceso y plan'),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Tu plan actual',
                    trailing: ProfilePlanBadge(
                      isVip: isVip,
                      compact: true,
                    ),
                  ),
                  if (user?.vence != null)
                    ProfileGroupRow(
                      title: 'Vigencia del acceso',
                      subtitle: 'Gestionado por el administrador',
                      valueText: _formatDate(user!.vence!),
                    ),
                ],
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 3,
          child: ProfileActionButton(
            label: 'Guardar cambios',
            loading: _saving,
            onTap: _save,
          ),
        ),
      ],
    );
  }
}

class _EditableProfileField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const _EditableProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.focusNode,
    this.onTap,
  });

  @override
  State<_EditableProfileField> createState() => _EditableProfileFieldState();
}

class _EditableProfileFieldState extends State<_EditableProfileField> {
  late FocusNode _node;
  bool _ownsNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _node = widget.focusNode!;
    } else {
      _node = FocusNode();
      _ownsNode = true;
    }
    _node.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _focused = _node.hasFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_handleFocusChange);
    if (_ownsNode) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.readOnly
          ? null
          : () {
              _node.requestFocus();
              widget.onTap?.call();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: AppFont.primary(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _focused && !widget.readOnly
                    ? AppTheme.accent(context)
                    : AppTheme.textTertiary(context),
              ),
              child: Text(widget.label),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: widget.controller,
              focusNode: _node,
              readOnly: widget.readOnly,
              enabled: !widget.readOnly,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              onTap: widget.onTap,
              style: AppFont.primary(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.readOnly
                    ? AppTheme.textTertiary(context)
                    : AppTheme.textPrimary(context),
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
