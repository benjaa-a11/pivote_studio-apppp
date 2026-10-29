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

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
    unawaited(HapticFeedback.selectionClick());
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
            color: kAuthInk,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa tu correo para recibir las instrucciones de recuperación.',
              style: GoogleFonts.figtree(
                color: kAuthMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.figtree(color: kAuthInk),
              decoration: InputDecoration(
                hintText: 'ejemplo@correo.com',
                hintStyle: GoogleFonts.figtree(color: Colors.grey),
                filled: true,
                fillColor: kAuthFieldBg,
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
              style: GoogleFonts.figtree(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C0C0C),
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

    return Scaffold(
      backgroundColor: kAuthHeaderBg,
      resizeToAvoidBottomInset: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              // ─── Header compacto con burbujas (fiel al HTML) ───────────
              AuthHeader(
                title: 'Login Here',
                compact: true,
                onBack: canPop ? () => Navigator.of(context).pop() : null,
              ),

              // ─── Panel blanco inferior (curvado sobre el header) ───────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: kAuthPanelBg,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(23, 36, 23, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Botón Google
                        AuthGoogleButton(onPressed: _handleGoogleSignIn),

                        // Separador "or"
                        const AuthOrDivider(),

                        // Formulario
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email Pill
                              AuthPillField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                hint: 'Email',
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

                              // Password con Eye button
                              AuthPasswordField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                hint: 'Password',
                                isVisible: _isPasswordVisible,
                                onToggleVisibility: () {
                                  setState(() => _isPasswordVisible =
                                      !_isPasswordVisible);
                                },
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

                        const SizedBox(height: 25),

                        // Botón Principal Negro
                        AuthMainButton(
                          label: 'Log in',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),

                        const SizedBox(height: 16),

                        // Solicitar nueva contraseña (HTML: .small)
                        GestureDetector(
                          onTap: _showForgotPasswordDialog,
                          child: Text.rich(
                            TextSpan(
                              text: 'Request a ',
                              style: GoogleFonts.figtree(
                                fontSize: 16,
                                color: kAuthMuted,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'New Password',
                                  style: TextStyle(
                                    color: kAuthInk,
                                    decoration: TextDecoration.underline,
                                    decorationColor: kAuthInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Enlace hacia Sign up (HTML: .foot.tight)
                        AuthFootLink(
                          prefix: 'New here?',
                          linkText: 'Create an account',
                          onTap: () {
                            unawaited(HapticFeedback.selectionClick());
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
            ],
          ),
        ),
      ),
    );
  }
}
