import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_typography.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';

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
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final FocusNode _passwordFocusNode = FocusNode();

  bool _saving = false;
  static const String _maskedPassword = '••••••••';

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    final fullName = [
      if (user?.name.isNotEmpty == true) user!.name,
      if (user?.lastName.isNotEmpty == true) user!.lastName,
    ].join(' ').trim();

    _usernameController = TextEditingController(
      text: fullName.isNotEmpty ? fullName : 'Usuario',
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _emailController = TextEditingController(
      text: user?.email ?? 'usuario@correo.com',
    );
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<String?> _askCurrentPassword() async {
    final palette = ProfilePalette.of(context);
    final currentPassCtrl = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: palette.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: palette.border),
          ),
          title: Text(
            'Confirmar contraseña actual',
            style: AppFont.primary(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresá tu contraseña actual para guardar la nueva clave.',
                style: AppFont.primary(
                  fontSize: 13.5,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: TextField(
                  controller: currentPassCtrl,
                  obscureText: true,
                  autofocus: true,
                  style: AppFont.primary(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: palette.text,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contraseña actual',
                    hintStyle: AppFont.primary(
                      color: palette.muted,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: AppFont.primary(
                  color: palette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, currentPassCtrl.text),
              child: Text(
                'Confirmar',
                style: AppFont.primary(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<UserProvider>();
    final user = provider.user;
    if (user == null) return;

    final fullInput = _usernameController.text.trim();
    if (fullInput.isEmpty) {
      AppNotifications.showWarning(context, 'Ingresá un nombre de usuario');
      return;
    }

    final parts = fullInput.split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final newEmail = _emailController.text.trim();
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
        name: firstName,
        lastName: lastName,
        email: newEmail.isNotEmpty ? newEmail : user.email,
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
    final palette = ProfilePalette.of(context);
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final imagePath = userProvider.profileImagePath;
    final photoUrl = user?.photoUrl;

    final currentText = _usernameController.text.trim();
    final initial =
        currentText.isNotEmpty ? currentText[0].toUpperCase() : 'U';
    final isVip = user?.isVip == true ||
        user?.userType.toLowerCase() == 'vip' ||
        user?.userType.toLowerCase() == 'admin';

    return ProfileSubsectionScaffold(
      title: 'Editar perfil',
      children: [
        // Avatar (.ava: 112x112 with animated colorful ring + edit button)
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 18),
              child: SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatarWithRing(
                      size: 112,
                      imagePath: imagePath,
                      photoUrl: photoUrl,
                      fallbackInitial: initial,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        userProvider.updateProfileImage();
                      },
                    ),
                    Positioned(
                      right: -2,
                      bottom: 2,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          userProvider.updateProfileImage();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.primaryBtnBg,
                            border: Border.all(
                              color: palette.bg,
                              width: 3,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: palette.primaryBtnText,
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

        // Fields Group
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: ProfileGroupCard(
            children: [
              _EditableProfileField(
                label: 'Nombre de usuario',
                controller: _usernameController,
                keyboardType: TextInputType.name,
              ),
              _EditableProfileField(
                label: 'Correo electrónico',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
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

        // Plan Section
        AppAnimations.staggeredSlideIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Plan'),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Tu plan actual',
                    trailing: ProfilePlanBadge(
                      isVip: isVip,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Save Button
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
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const _EditableProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
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
    if (_ownsNode) {
      _node.dispose();
    }
    super.dispose();
  }

  @override
  
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _node.requestFocus();
        widget.onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: AppFont.primary(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _focused ? palette.text : palette.muted,
              ),
              child: Text(widget.label),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: widget.controller,
              focusNode: _node,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              onTap: widget.onTap,
              style: AppFont.primary(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: palette.text,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
