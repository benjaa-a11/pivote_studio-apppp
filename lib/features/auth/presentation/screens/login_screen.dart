import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/features/auth/presentation/screens/signup_screen.dart';
import 'package:pivote/features/auth/presentation/widgets/auth_components.dart';
import 'package:pivote/features/home/presentation/screens/main_screen.dart';

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
        unawaited(context.read<AppActivityService>().onUserLogin());
        AppNotifications.showSuccess(context, '¡Bienvenido de nuevo!');
        unawaited(Navigator.of(context).pushReplacement(
          AppAnimations.createFadeRoute(const MainScreen()),
        ));
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthService.getErrorMessage(e);
        AppNotifications.showError(context, errorMessage);
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignIn() {
    AppNotifications.showInfo(
      context,
      'Inicio de sesión con Google próximamente disponible',
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.figtree(
            fontWeight: FontWeight.w700,
            color: kHtmlInk,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa tu correo para recibir las instrucciones de recuperación.',
              style: GoogleFonts.figtree(
                color: kHtmlMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.figtree(color: kHtmlInk),
              decoration: InputDecoration(
                hintText: 'ejemplo@correo.com',
                hintStyle: GoogleFonts.figtree(color: const Color(0xFF8A8A8A)),
                filled: true,
                fillColor: kHtmlField,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
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
              style: GoogleFonts.figtree(color: kHtmlMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kHtmlBtnMain,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AppNotifications.showSuccess(
                context,
                'Si el correo está registrado, recibirás un enlace de recuperación.',
              );
            },
            child: Text(
              'Enviar enlace',
              style: GoogleFonts.figtree(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AuthStageLayout(
      onBack: canPop ? () => Navigator.of(context).pop() : null,
      card: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: AuthCard(
            // ─── Hero exacto (.hero.single: height 122px) ───────────────
            hero: const AuthHero(
              title: 'Inicia sesión',
              single: true,
            ),
            // ─── Panel blanco (.panel) ──────────────────────────────────
            panel: AuthPanel(
              children: [
                // Botón Google
                AuthGoogleBtn(
                  label: 'Iniciar sesión con Google',
                  onTap: _handleGoogleSignIn,
                ),

                // Separador "o"
                const AuthOrText(),

                // Formulario de campos
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Correo electrónico (.field.pill)
                      AuthPillInput(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        placeholder: 'Correo electrónico',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_passwordFocus),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 9),

                      // Contraseña (.row.pw)
                      AuthPasswordInput(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        placeholder: 'Contraseña',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa tu contraseña';
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

                // Botón principal negro (.btn-main)
                AuthMainBtn(
                  label: 'Iniciar sesión',
                  isLoading: _isLoading,
                  onTap: _handleLogin,
                ),

                // Solicitar nueva contraseña (.small)
                AuthSmallLink(
                  text: '¿Olvidaste tu contraseña? ',
                  linkText: 'Recupérala',
                  onTap: _showForgotPasswordDialog,
                ),

                // Enlace hacia Registro (.foot.tight)
                AuthFootLink(
                  prefix: '¿Eres nuevo?',
                  linkText: 'Crea una cuenta',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      AppAnimations.createFadeRoute(
                        const SignUpScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
