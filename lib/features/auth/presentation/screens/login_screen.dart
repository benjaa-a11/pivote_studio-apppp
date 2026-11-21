import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/screens/signup_screen.dart';
import 'package:pivote/features/auth/presentation/widgets/auth_components.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    unawaited(HapticFeedback.lightImpact());

    final userProvider = context.read<UserProvider>();

    setState(() => _isLoading = true);
    try {
      await userProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        AppNotifications.showSuccess(context, '¡Bienvenido de nuevo!');
        // Si LoginScreen estaba apilado sobre el wrapper raíz, volvemos a la raíz;
        // _AuthenticationWrapper transiciona automáticamente a MainScreen.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AccountAccessBlockedException {
      // UserProvider ya cambió authStatus a `blocked` y cerró sesión;
      // el wrapper raíz mostrará AccountStatusScreen al instante.
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthService.getErrorMessage(e);
        AppNotifications.showError(context, errorMessage);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final email = await AppDialogs.showInputDialog(
      context: context,
      title: 'Recuperar contraseña',
      message:
          'Ingresá tu correo electrónico para recibir el enlace oficial de restablecimiento.',
      hintText: 'ejemplo@correo.com',
      initialValue: _emailController.text.trim(),
      confirmLabel: 'Enviar enlace',
      keyboardType: TextInputType.emailAddress,
      icon: Icons.mark_email_read_outlined,
    );
    if (email == null || email.trim().isEmpty || !mounted) return;

    try {
      await AuthService.sendPasswordResetEmail(email.trim());
      if (mounted) {
        AppNotifications.showSuccess(
          context,
          'Te enviamos un enlace para restablecer tu contraseña.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(context, AuthService.getErrorMessage(e));
      }
    }
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
              title: 'Inicia sesión',
              single: true,
            ),
            panel: AuthPanel(
              footer: AuthFootLink(
                prefix: '¿Tenés código de invitación?',
                linkText: 'Crea tu cuenta',
                onTap: () {
                  Navigator.of(context).push(
                    AppAnimations.createFadeRoute(
                      const SignUpScreen(),
                    ),
                  );
                },
              ),
              children: [
                const SizedBox(height: 8),

                // Etiqueta discreta de acceso privado
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
                      Icon(Icons.lock_outline_rounded, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'ACCESO PRIVADO POR INVITACIÓN',
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

                const SizedBox(height: 22),

                // Formulario de acceso
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                      const SizedBox(height: 14),
                      AuthPasswordInput(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        placeholder: 'Contraseña',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
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
                  label: 'Iniciar sesión',
                  isLoading: _isLoading,
                  onTap: _handleLogin,
                ),

                AuthSmallLink(
                  text: '¿Olvidaste tu contraseña? ',
                  linkText: 'Recupérala',
                  onTap: _showForgotPasswordDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
