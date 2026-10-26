import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/features/home/presentation/screens/main_screen.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

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
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
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
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Branding
                _buildBranding(isDark),
                const SizedBox(height: 32),
                // Form
                _buildForm(context, theme, isDark),
                const SizedBox(height: 16),
                // Login link
                _buildLoginLink(context, isDark),
                const SizedBox(height: 32),
              ],
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
        Text(
          'Crea tu\ncuenta',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Únete a Pivote y accede a todo el contenido',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + Apellido en fila
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nombre', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_lastNameFocus),
                      style: _fieldTextStyle(isDark),
                      decoration: _inputDecoration(
                        hint: 'Nombre',
                        isDark: isDark,
                        theme: theme,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Apellido', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lastNameController,
                      focusNode: _lastNameFocus,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_emailFocus),
                      style: _fieldTextStyle(isDark),
                      decoration: _inputDecoration(
                        hint: 'Apellido',
                        isDark: isDark,
                        theme: theme,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel('Correo electrónico', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passwordFocus),
            style: _fieldTextStyle(isDark),
            decoration: _inputDecoration(
              hint: 'tu@email.com',
              icon: Icons.email_outlined,
              isDark: isDark,
              theme: theme,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresá tu correo';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Correo inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLabel('Contraseña', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_confirmFocus),
            style: _fieldTextStyle(isDark),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
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
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresá tu contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLabel('Confirmar contraseña', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            focusNode: _confirmFocus,
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSignUp(),
            style: _fieldTextStyle(isDark),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              theme: theme,
              suffix: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 20,
                  color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
                ),
                onPressed: () => setState(() =>
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirmá tu contraseña';
              if (v != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          // Privacy note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.darkAccent.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security_rounded,
                  size: 16,
                  color: AppTheme.darkAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu contraseña se almacena encriptada y nunca se comparte.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
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
                      'Crear cuenta',
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

  TextStyle _fieldTextStyle(bool isDark) {
    return GoogleFonts.spaceGrotesk(
      color: isDark ? AppTheme.darkText : AppTheme.lightText,
      fontSize: 15,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    required ThemeData theme,
    IconData? icon,
    Widget? suffix,
  }) {
    final fieldBg = isDark ? AppTheme.darkBg2 : AppTheme.lightBg1;
    final borderColor = isDark ? AppTheme.darkBorder2 : AppTheme.lightBorder;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.spaceGrotesk(
        color: isDark ? AppTheme.darkText3 : AppTheme.lightText3,
        fontSize: 14,
      ),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon,
                  size: 18,
                  color: isDark ? AppTheme.darkText3 : AppTheme.lightText3),
            )
          : null,
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

  Widget _buildLoginLink(BuildContext context, bool isDark) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿Ya tenés cuenta? ',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: isDark ? AppTheme.darkText2 : AppTheme.lightText2,
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Text(
              'Iniciar sesión',
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
