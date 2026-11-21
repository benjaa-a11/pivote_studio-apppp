import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/widgets/auth_components.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _codeFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeFocus.dispose();
    _nameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    unawaited(HapticFeedback.lightImpact());

    setState(() => _isLoading = true);
    try {
      final userProvider = context.read<UserProvider>();
      final result = await userProvider.registerWithInvitation(
        invitationCode: _codeController.text.trim().toUpperCase(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nombre: _nameController.text.trim(),
        apellido: _lastNameController.text.trim(),
      );

      if (!mounted) return;

      if (result.requiresApproval) {
        AppNotifications.showInfo(
          context,
          'Cuenta creada. Esperando aprobación del administrador.',
        );
      } else {
        AppNotifications.showSuccess(context, '¡Bienvenido a Pivote!');
      }

      // Volvemos al wrapper raíz, que muestra AccountStatusScreen (si quedó pendiente)
      // o carga MainScreen (si la invitación era pre-aprobada).
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthService.getErrorMessage(e);
        AppNotifications.showError(context, errorMessage);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPolicyDialog(String title, String body) {
    AppDialogs.showAlert(
      context: context,
      title: title,
      message: body,
      type: AppDialogType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final accent = AppTheme.accent(context);

    return AuthStageLayout(
      onBack: canPop ? () => Navigator.of(context).pop() : null,
      card: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: AuthCard(
            hero: const AuthHero(
              title: 'Crea una\ncuenta',
              single: false,
            ),
            panel: AuthPanel(
              footer: AuthFootLink(
                prefix: '¿Ya tenés cuenta?',
                linkText: 'Iniciá sesión aquí',
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              children: [
                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDim(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vpn_key_outlined, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'REQUIERE CÓDIGO DE INVITACIÓN',
                        style: AppFont.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Código de invitación obligatorio
                      AuthPillInput(
                        controller: _codeController,
                        focusNode: _codeFocus,
                        placeholder: 'Código de invitación',
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_nameFocus),
                        validator: (v) {
                          final code = (v ?? '').trim();
                          if (code.isEmpty) {
                            return 'Ingresá tu código de invitación';
                          }
                          if (code.length < 6) {
                            return 'El código es demasiado corto';
                          }
                          if (code.contains('/')) {
                            return 'Código con formato inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Nombre y Apellido
                      AuthSplitNameRow(
                        firstController: _nameController,
                        lastController: _lastNameController,
                        firstFocus: _nameFocus,
                        lastFocus: _lastNameFocus,
                        firstPlaceholder: 'Nombre',
                        lastPlaceholder: 'Apellido',
                        onFirstSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_lastNameFocus),
                        firstValidator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nombre requerido';
                          }
                          return null;
                        },
                        onLastSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_emailFocus),
                        lastValidator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Apellido requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Correo electrónico
                      AuthPillInput(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        placeholder: 'Correo electrónico',
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_passwordFocus),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresá tu correo';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Ingresá un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Contraseña
                      AuthPasswordInput(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        placeholder: 'Contraseña',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleSignUp(),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresá tu contraseña';
                          }
                          if (v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                AuthMainBtn(
                  label: 'Crear cuenta',
                  isLoading: _isLoading,
                  onTap: _handleSignUp,
                ),

                AuthLegalNotice(
                  onPrivacyTap: () => _showPolicyDialog(
                    'Política de Privacidad',
                    'En Pivote protegemos tu cuenta y tus datos de acceso. Nunca compartimos tus credenciales ni tu información con terceros.',
                  ),
                  onTermsTap: () => _showPolicyDialog(
                    'Términos de Servicio',
                    'El acceso a Pivote es privado, personal y sujeto a la vigencia y aprobación del administrador.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
