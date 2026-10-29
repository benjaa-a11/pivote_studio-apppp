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
    AppNotifications.showInfo(
      context,
      'Registro con Google próximamente disponible',
    );
  }

  void _showPolicyDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: kHtmlInk,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: const TextStyle(
              color: kHtmlMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kHtmlBtnMain,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
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
            // ─── Hero exacto de 2 líneas (.hero: height 174px) ───────────
            hero: const AuthHero(
              title: 'Crea una\ncuenta',
              single: false,
            ),
            // ─── Panel blanco (.panel) ──────────────────────────────────
            panel: AuthPanel(
              children: [
                // Botón Google
                AuthGoogleBtn(
                  label: 'Registrarse con Google',
                  onTap: _handleGoogleSignUp,
                ),

                // Separador "o"
                const AuthOrText(),

                // Formulario de campos
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nombre y Apellido (.row con 2 .field)
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
                        onLastSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_emailFocus),
                        lastValidator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Apellido requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 9),

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

                // Botón principal negro (.btn-main)
                AuthMainBtn(
                  label: 'Crear cuenta',
                  isLoading: _isLoading,
                  onTap: _handleSignUp,
                ),

                // Aviso Legal (.legal)
                AuthLegalNotice(
                  onPrivacyTap: () => _showPolicyDialog(
                    'Política de Privacidad',
                    'En Pivote nos tomamos tu privacidad con seriedad. No compartimos tus credenciales ni tus datos personales con terceros.',
                  ),
                  onTermsTap: () => _showPolicyDialog(
                    'Términos de Servicio',
                    'Al utilizar Pivote aceptas disfrutar de los contenidos y transmisiones de manera responsable.',
                  ),
                ),

                // Enlace hacia Login (.foot.tight)
                AuthFootLink(
                  prefix: '¿Ya tienes una cuenta?',
                  linkText: 'Inicia sesión aquí',
                  onTap: () {
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
    );
  }
}
