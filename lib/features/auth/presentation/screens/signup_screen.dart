import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/features/auth/presentation/screens/login_screen.dart';
import 'package:pivote/features/auth/presentation/widgets/auth_components.dart';
import 'package:pivote/features/home/presentation/screens/main_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
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
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
      await userProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _lastNameController.text.trim(),
      );

      if (mounted) {
        AppNotifications.showSuccess(context, '¡Bienvenido a Pivote!');
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

  void _handleGoogleSignUp() {
    unawaited(HapticFeedback.selectionClick());
    AppNotifications.showInfo(
      context,
      'Registro con Google próximamente disponible',
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
              // ─── Header de 2 líneas con burbujas (fiel al HTML) ─────────
              AuthHeader(
                title: 'Create an\naccount',
                compact: false,
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
                    padding: const EdgeInsets.fromLTRB(23, 34, 23, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Botón Google
                        AuthGoogleButton(onPressed: _handleGoogleSignUp),

                        // Separador "or"
                        const AuthOrDivider(),

                        // Formulario
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Fila First Name + Last Name (HTML: .row con 2 inputs)
                              AuthSplitPillRow(
                                leftController: _nameController,
                                leftFocus: _nameFocus,
                                leftHint: 'First Name',
                                leftSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_lastNameFocus),
                                leftValidator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Nombre requerido';
                                  }
                                  return null;
                                },
                                rightController: _lastNameController,
                                rightFocus: _lastNameFocus,
                                rightHint: 'Last Name',
                                rightSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_emailFocus),
                                rightValidator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Apellido requerido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 9),

                              // Email Pill (HTML: .row .field.pill)
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

                              // Password con Eye button (HTML: .row.pw)
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
                                onSubmitted: (_) => _handleSignUp(),
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

                        // Botón Principal Negro (HTML: .btn-main)
                        AuthMainButton(
                          label: 'Create account',
                          isLoading: _isLoading,
                          onPressed: _handleSignUp,
                        ),

                        // Aviso Legal (HTML: .legal)
                        const AuthLegalNotice(),

                        const SizedBox(height: 24),

                        // Enlace hacia Login (HTML: .foot.tight)
                        AuthFootLink(
                          prefix: 'Have an account?',
                          linkText: 'Log in here',
                          onTap: () {
                            unawaited(HapticFeedback.selectionClick());
                            Navigator.of(context).pushReplacement(
                              AppAnimations.createFadeRoute(
                                const LoginScreen(),
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
