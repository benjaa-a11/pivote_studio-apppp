import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/app_activity_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/features/auth/presentation/screens/signup_screen.dart';
import 'package:pivote/features/home/presentation/screens/main_screen.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

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
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
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
    HapticFeedback.lightImpact();

    final userProvider = context.read<UserProvider>();

    setState(() => _isLoading = true);
    try {
      await userProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        context.read<AppActivityService>().onUserLogin();
        AppNotifications.showSuccess(context, '¡Bienvenido de nuevo!');
        Navigator.of(context).pushReplacement(
          AppAnimations.createFadeRoute(const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthService.getErrorMessage(e);
        AppNotifications.showError(context, errorMessage);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      resizeToAvoidBottomInset: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.07),
                  // Logo + branding
                  _buildBranding(isDark),
                  SizedBox(height: screenHeight * 0.06),
                  // Formulario
                  _buildForm(context, theme, isDark),
                  const SizedBox(height: 16),
                  // Sign up link
                  _buildSignUpLink(context, theme),
                  const SizedBox(height: 24),
                  // Footer
                  Center(
                    child: Text(
                      'Al iniciar sesión aceptas nuestra\nPolítica de Privacidad y Términos de Servicio',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBg2 : AppTheme.lightBg1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.lightBorder,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/logo.png',
            errorBuilder: (_, __, ___) => const Icon(
              Icons.play_circle_fill,
              color: AppTheme.darkAccent,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Bienvenido\nde nuevo',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ingresá a tu cuenta para continuar',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, ThemeData theme, bool isDark) {
    final fieldBg = isDark
        ? AppTheme.darkBg2
        : AppTheme.lightBg1;
    final borderColor = isDark ? AppTheme.darkBorder2 : AppTheme.lightBorder;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email
          _buildLabel('Correo electrónico', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passwordFocus),
            style: GoogleFonts.spaceGrotesk(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontSize: 15,
            ),
            decoration: _inputDecoration(
              hint: 'tu@email.com',
              icon: Icons.email_outlined,
              fieldBg: fieldBg,
              borderColor: borderColor,
              isDark: isDark,
              theme: theme,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresá tu correo';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Correo inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          // Password
          _buildLabel('Contraseña', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            style: GoogleFonts.spaceGrotesk(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontSize: 15,
            ),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              fieldBg: fieldBg,
              borderColor: borderColor,
              isDark: isDark,
              theme: theme,
              suffix: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 20,
                  color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresá tu contraseña';
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 28),
          // Botón principal
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkAccent,
                foregroundColor: AppTheme.darkBg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor:
                    AppTheme.darkAccent.withValues(alpha: 0.4),
              ),
              child: _isLoading
                  ? const PivoteLoader(
                      color: AppTheme.darkBg,
                      size: 22,
                      strokeWidth: 2.5,
                    )
                  : Text(
                      'Entrar',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppTheme.darkBg,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color fieldBg,
    required Color borderColor,
    required bool isDark,
    required ThemeData theme,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.spaceGrotesk(
        color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
        fontSize: 14,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon,
            size: 18,
            color: isDark ? AppTheme.darkText3 : AppTheme.lightText3),
      ),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.darkAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.darkDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.darkDanger, width: 1.5),
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿Nuevo en Pivote? ',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                AppAnimations.createRoute(const SignUpScreen()),
              );
            },
            child: Text(
              'Crear cuenta',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkAccent,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.darkAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
