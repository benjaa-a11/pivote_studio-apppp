import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/app_animations.dart';
import '../widgets/app_notifications.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        AppNotifications.showSuccess(context, '¡Bienvenido de nuevo!');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthService.getErrorMessage(e);
        AppNotifications.showError(context, errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) {
        AppNotifications.showSuccess(context, 'Sesión iniciada con Google');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = AuthService.getErrorMessage(e);
        AppNotifications.showError(context, errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE7714D), Color(0xFFE57C5D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Blob 1 (Yellow)
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFD4B455).withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Blob 2 (Greenish)
          Positioned(
            top: 40,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF5BB389).withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Blur effects for blobs
          Positioned.fill(
            child: BackdropFilter(
              filter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.05),
                BlendMode.dstATop,
              ),
              child: const SizedBox(),
            ),
          ),
          // Texture overlay
          Opacity(
            opacity: 0.15,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAxeOP_Q52z599Av7oc256ySH9s_MQEWVrZYoFRLi0tyUI1gl160aHqiTIFyeEiryN4QCKwDX9X_lZGQ0pOkqwpPisVkVbg0CYQ-AuuHVXV9NKlXphh9Yp99N65bBuaUlVFHi_bLAmaHrEfYwDOBeQ-MhpSIeXgsbg1mYkxMdfrQ58u6cqmgdnIIvdsZIKjU-_9bmrEz8iprH74WyTxl3Wqk5qQcTGCCkQvMWL6-BVRR1bJdpv6uA0fEj4QzEU8j89XS0PC9nwelbw',
                  ),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: AppAnimations.smoothFadeIn(
              child: const Text(
                'Inicia Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);

    return Transform.translate(
      offset: const Offset(0, -40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Google Login Button
              AppAnimations.staggeredListItem(
                index: 0,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continuar con Google',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: theme.dividerColor.withValues(alpha: 0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('o', style: theme.textTheme.bodyMedium),
                  ),
                  Expanded(
                      child: Divider(
                          color: theme.dividerColor.withValues(alpha: 0.1))),
                ],
              ),
              const SizedBox(height: 24),
              // Email
              AppAnimations.staggeredListItem(
                index: 1,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Correo electrónico',
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    if (!value.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Password
              AppAnimations.staggeredListItem(
                index: 2,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    if (value.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),
              // Login Button
              AppAnimations.staggeredListItem(
                index: 3,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Entrar',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Links
              AppAnimations.staggeredListItem(
                index: 4,
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Olvidé mi contraseña',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿Nuevo aquí? ',
                            style: theme.textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()),
                            );
                          },
                          child: Text(
                            'Crea una cuenta',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Footer
              Text(
                'Al iniciar sesión aceptas nuestra\nPolítica de Privacidad y Términos de Servicio',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 24),
              // Skip Button for Development
              AppAnimations.staggeredListItem(
                index: 5,
                child: TextButton(
                  onPressed: () {
                    // Este botón es solo para desarrollo, permite entrar sin login
                    // Usamos pushReplacement para que no pueda volver atrás al login
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saltar',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
