import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pivote/core/theme/app_colors.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/app_typography.dart';

// ─── Paleta de Auth adaptativa a ambos temas ─────────────────────────────────
class AuthPalette {
  final bool isDark;
  final Color scaffoldBg;
  final Color panelBg;
  final Color heroBg;
  final Color heroBubble1;
  final Color heroBubble2;
  final Color text;
  final Color muted;
  final Color fieldBg;
  final Color fieldFocusBg;
  final Color fieldBorder;
  final Color line;
  final Color btnMainBg;
  final Color btnMainPressed;
  final Gradient? btnMainGradient;
  final Color btnMainText;
  final Color googleBtnBg;
  final Color googleBtnBorder;
  final Color googleBtnText;
  final Color backBtnBg;
  final Color backBtnIcon;
  final Color linkColor;

  const AuthPalette({
    required this.isDark,
    required this.scaffoldBg,
    required this.panelBg,
    required this.heroBg,
    required this.heroBubble1,
    required this.heroBubble2,
    required this.text,
    required this.muted,
    required this.fieldBg,
    required this.fieldFocusBg,
    required this.fieldBorder,
    required this.line,
    required this.btnMainBg,
    required this.btnMainPressed,
    this.btnMainGradient,
    required this.btnMainText,
    required this.googleBtnBg,
    required this.googleBtnBorder,
    required this.googleBtnText,
    required this.backBtnBg,
    required this.backBtnIcon,
    required this.linkColor,
  });

  factory AuthPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      return AuthPalette(
        isDark: true,
        scaffoldBg: AppColors.darkBg,
        panelBg: AppColors.darkBg1,
        heroBg: AppColors.darkBg2,
        heroBubble1: AppColors.accent.withValues(alpha: 0.22),
        heroBubble2: AppColors.accentTint.withValues(alpha: 0.14),
        text: AppColors.darkText,
        muted: AppColors.darkText3,
        fieldBg: AppColors.darkBg2,
        fieldFocusBg: AppColors.darkBg3,
        fieldBorder: AppColors.darkBorder2,
        line: AppColors.darkBorder,
        btnMainBg: AppColors.darkAccent,
        btnMainPressed: AppColors.accentStrong,
        btnMainGradient: AppGradients.buttonPrimary,
        btnMainText: Colors.white,
        googleBtnBg: AppColors.darkBg2,
        googleBtnBorder: AppColors.darkBorder2,
        googleBtnText: AppColors.darkText,
        backBtnBg: AppColors.darkBg3.withValues(alpha: 0.8),
        backBtnIcon: AppColors.darkText,
        linkColor: AppColors.accentTint,
      );
    } else {
      return const AuthPalette(
        isDark: false,
        scaffoldBg: AppColors.lightBg,
        panelBg: Colors.white,
        heroBg: AppColors.darkAccent,
        heroBubble1: Color(0x554887FF),
        heroBubble2: Color(0x407DB0FF),
        text: AppColors.lightText,
        muted: AppColors.lightText2,
        fieldBg: Color(0xFFF4F6F9),
        fieldFocusBg: Color(0xFFECEFF4),
        fieldBorder: AppColors.lightBorder,
        line: AppColors.lightBorder,
        btnMainBg: AppColors.darkAccent,
        btnMainPressed: AppColors.accentStrong,
        btnMainGradient: AppGradients.buttonPrimary,
        btnMainText: Colors.white,
        googleBtnBg: Colors.white,
        googleBtnBorder: AppColors.lightBorder,
        googleBtnText: AppColors.lightText,
        backBtnBg: Color(0x33000000),
        backBtnIcon: Colors.white,
        linkColor: AppColors.darkAccent,
      );
    }
  }
}

// ─── SVG Oficial de Google ───────────────────────────────────────────────────
const String _kGoogleSvg = '''
<svg width="26" height="26" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.6 5.9c4.4-4.1 7-10.1 7-17.6z"/>
  <path fill="#FBBC05" d="M10.5 28.7c-.5-1.4-.8-3-.8-4.7s.3-3.2.8-4.7l-7.9-6.1C.9 16.4 0 20.100 0 24s.9 7.600 2.600 10.800l7.900-6.100z"/>
  <path fill="#34A853" d="M24 48c6.5 0 11.900-2.100 15.900-5.800l-7.600-5.900c-2.100 1.400-4.900 2.300-8.300 2.300-6.300 0-11.600-4.100-13.500-9.800l-7.900 6.100C6.500 42.600 14.600 48 24 48z"/>
</svg>
''';

// ─── Stage Layout (Pantalla completa nativa, adaptativa) ─────────────────────
class AuthStageLayout extends StatelessWidget {
  final Widget card;
  final VoidCallback? onBack;

  const AuthStageLayout({
    super.key,
    required this.card,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: palette.isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: palette.panelBg,
        systemNavigationBarIconBrightness:
            palette.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.scaffoldBg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Contenido con distribución de altura completa y scroll sin rebote
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 480,
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: card,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Botón volver atrás integrado sobre el Hero superior
            if (onBack != null)
              Positioned(
                top: topPadding + 8,
                left: 14,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onBack!();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: palette.backBtnBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.isDark
                              ? palette.fieldBorder
                              : Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: palette.backBtnIcon,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta / Contenedor principal adaptado a la pantalla ────────────────────
class AuthCard extends StatelessWidget {
  final Widget hero;
  final Widget panel;

  const AuthCard({
    super.key,
    required this.hero,
    required this.panel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    return ColoredBox(
      color: palette.heroBg,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hero,
          Expanded(
            child: panel,
          ),
        ],
      ),
    );
  }
}

// ─── Hero con burbujas adaptado al notch superior ────────────────────────────
class AuthHero extends StatelessWidget {
  final String title;
  final bool single;

  const AuthHero({
    super.key,
    required this.title,
    this.single = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;
    final screenHeight = media.size.height;

    final visibleHeight = single
        ? (screenHeight * 0.22).clamp(164.0, 204.0)
        : (screenHeight * 0.235).clamp(176.0, 216.0);
    const bottomCurveOverlap = 28.0;
    final totalHeight = topPadding + visibleHeight + bottomCurveOverlap;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Fondo que llena hasta la parte superior de la pantalla
          Positioned.fill(
            child: Container(color: palette.heroBg),
          ),

          // Burbuja 1 (.gold) posicionada armónicamente
          Positioned(
            left: -62,
            bottom: -42,
            child: Container(
              width: 164,
              height: 164,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.heroBubble1,
              ),
            ),
          ),

          // Burbuja 2 (.green) posicionada armónicamente a la derecha
          Positioned(
            right: -38,
            bottom: -48,
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.heroBubble2,
              ),
            ),
          ),

          // Título centrado vertical y horizontalmente en el área visible del Hero
          Positioned(
            top: topPadding + 8,
            left: 24,
            right: 24,
            bottom: bottomCurveOverlap,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppFont.primary(
                  fontSize: 32,
                  height: 1.14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Curva superior del panel integrada sin huecos fantasma
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: bottomCurveOverlap + 1,
            child: Container(
              decoration: BoxDecoration(
                color: palette.panelBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel (.panel) adaptativo ───────────────────────────────────────────────
class AuthPanel extends StatelessWidget {
  final List<Widget> children;
  final Widget? footer;

  const AuthPanel({
    super.key,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      color: palette.panelBg,
      padding: EdgeInsets.fromLTRB(26, 12, 26, 26 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: footer!,
            ),
        ],
      ),
    );
  }
}

// ─── Botón Google (.btn-google) ──────────────────────────────────────────────
class AuthGoogleBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const AuthGoogleBtn({
    super.key,
    this.label = 'Iniciar sesión con Google',
    required this.onTap,
  });

  @override
  State<AuthGoogleBtn> createState() => _AuthGoogleBtnState();
}

class _AuthGoogleBtnState extends State<AuthGoogleBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: _isPressed
                ? (palette.isDark ? palette.fieldFocusBg : const Color(0xFFFAFAFA))
                : palette.googleBtnBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.googleBtnBorder, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(
                _kGoogleSvg,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: AppFont.primary(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w500,
                  color: palette.googleBtnText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Divisor "o" (.or) ───────────────────────────────────────────────────────
class AuthOrText extends StatelessWidget {
  const AuthOrText({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'o',
        style: AppFont.primary(
          fontSize: 15,
          color: palette.muted,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ─── Input Pill (.field.pill) adaptativo ─────────────────────────────────────
class AuthPillInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  const AuthPillInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
  });

  @override
  State<AuthPillInput> createState() => _AuthPillInputState();
}

class _AuthPillInputState extends State<AuthPillInput> {
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    final bgColor = _isFocused ? palette.fieldFocusBg : palette.fieldBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _isFocused
                  ? palette.linkColor
                  : (palette.isDark ? palette.fieldBorder : Colors.transparent),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            cursorColor: palette.linkColor,
            cursorWidth: 1.5,
            style: AppFont.primary(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: palette.text,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              filled: true,
              fillColor: bgColor,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              hintText: widget.placeholder,
              hintStyle: AppFont.primary(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: palette.muted,
              ),
            ),
            validator: (value) {
              final err = widget.validator?.call(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _errorText != err) {
                  setState(() => _errorText = err);
                }
              });
              return err;
            },
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: Text(
              _errorText!,
              style: AppFont.primary(
                fontSize: 12,
                color: const Color(0xFFD32F2F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Fila Dividida Nombre / Apellido (.row con 2 .field) ─────────────────────
class AuthSplitNameRow extends StatefulWidget {
  final TextEditingController firstController;
  final TextEditingController lastController;
  final FocusNode firstFocus;
  final FocusNode lastFocus;
  final String firstPlaceholder;
  final String lastPlaceholder;
  final ValueChanged<String>? onFirstSubmitted;
  final ValueChanged<String>? onLastSubmitted;
  final FormFieldValidator<String>? firstValidator;
  final FormFieldValidator<String>? lastValidator;

  const AuthSplitNameRow({
    super.key,
    required this.firstController,
    required this.lastController,
    required this.firstFocus,
    required this.lastFocus,
    this.firstPlaceholder = 'Nombre',
    this.lastPlaceholder = 'Apellido',
    this.onFirstSubmitted,
    this.onLastSubmitted,
    this.firstValidator,
    this.lastValidator,
  });

  @override
  State<AuthSplitNameRow> createState() => _AuthSplitNameRowState();
}

class _AuthSplitNameRowState extends State<AuthSplitNameRow> {
  bool _firstFocused = false;
  bool _lastFocused = false;
  String? _firstError;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    widget.firstFocus.addListener(_onFirstFocus);
    widget.lastFocus.addListener(_onLastFocus);
  }

  @override
  void dispose() {
    widget.firstFocus.removeListener(_onFirstFocus);
    widget.lastFocus.removeListener(_onLastFocus);
    super.dispose();
  }

  void _onFirstFocus() {
    if (mounted) setState(() => _firstFocused = widget.firstFocus.hasFocus);
  }

  void _onLastFocus() {
    if (mounted) setState(() => _lastFocused = widget.lastFocus.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    const leftRadius = BorderRadius.only(
      topLeft: Radius.circular(999),
      bottomLeft: Radius.circular(999),
    );
    const rightRadius = BorderRadius.only(
      topRight: Radius.circular(999),
      bottomRight: Radius.circular(999),
    );

    final firstBg = _firstFocused ? palette.fieldFocusBg : palette.fieldBg;
    final lastBg = _lastFocused ? palette.fieldFocusBg : palette.fieldBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // First Name
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 52,
                decoration: BoxDecoration(
                  color: firstBg,
                  borderRadius: leftRadius,
                  border: Border.all(
                    color: _firstFocused
                        ? palette.linkColor
                        : (palette.isDark ? palette.fieldBorder : Colors.transparent),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                child: TextFormField(
                  controller: widget.firstController,
                  focusNode: widget.firstFocus,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: widget.onFirstSubmitted,
                  cursorColor: palette.linkColor,
                  cursorWidth: 1.5,
                  style: AppFont.primary(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: palette.text,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: true,
                    fillColor: firstBg,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.firstPlaceholder,
                    hintStyle: AppFont.primary(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: palette.muted,
                    ),
                  ),
                  validator: (value) {
                    final err = widget.firstValidator?.call(value);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _firstError != err) {
                        setState(() => _firstError = err);
                      }
                    });
                    return err;
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Last Name
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 52,
                decoration: BoxDecoration(
                  color: lastBg,
                  borderRadius: rightRadius,
                  border: Border.all(
                    color: _lastFocused
                        ? palette.linkColor
                        : (palette.isDark ? palette.fieldBorder : Colors.transparent),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                child: TextFormField(
                  controller: widget.lastController,
                  focusNode: widget.lastFocus,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: widget.onLastSubmitted,
                  cursorColor: palette.linkColor,
                  cursorWidth: 1.5,
                  style: AppFont.primary(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: palette.text,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: true,
                    fillColor: lastBg,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.lastPlaceholder,
                    hintStyle: AppFont.primary(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: palette.muted,
                    ),
                  ),
                  validator: (value) {
                    final err = widget.lastValidator?.call(value);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _lastError != err) {
                        setState(() => _lastError = err);
                      }
                    });
                    return err;
                  },
                ),
              ),
            ),
          ],
        ),
        if (_firstError != null || _lastError != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: Text(
              _firstError ?? _lastError!,
              style: AppFont.primary(
                fontSize: 12,
                color: const Color(0xFFD32F2F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Input Contraseña + Ojo ──────────────────────────────────────────────────
class AuthPasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  const AuthPasswordInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.placeholder = 'Contraseña',
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.validator,
  });

  @override
  State<AuthPasswordInput> createState() => _AuthPasswordInputState();
}

class _AuthPasswordInputState extends State<AuthPasswordInput> {
  bool _isFocused = false;
  bool _isObscured = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    const leftRadius = BorderRadius.only(
      topLeft: Radius.circular(999),
      bottomLeft: Radius.circular(999),
    );
    const rightRadius = BorderRadius.only(
      topRight: Radius.circular(999),
      bottomRight: Radius.circular(999),
    );

    final bgColor = _isFocused ? palette.fieldFocusBg : palette.fieldBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Campo de contraseña
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: leftRadius,
                  border: Border.all(
                    color: _isFocused
                        ? palette.linkColor
                        : (palette.isDark ? palette.fieldBorder : Colors.transparent),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.center,
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: _isObscured,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onSubmitted,
                  cursorColor: palette.linkColor,
                  cursorWidth: 1.5,
                  style: AppFont.primary(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: palette.text,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: true,
                    fillColor: bgColor,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: AppFont.primary(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: palette.muted,
                    ),
                  ),
                  validator: (value) {
                    final err = widget.validator?.call(value);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _errorText != err) {
                        setState(() => _errorText = err);
                      }
                    });
                    return err;
                  },
                ),
              ),
            ),
            // Botón ojo
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 54,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: rightRadius,
                border: Border.all(
                  color: _isFocused
                      ? palette.linkColor
                      : (palette.isDark ? palette.fieldBorder : Colors.transparent),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: rightRadius,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isObscured = !_isObscured);
                  },
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _isObscured
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        key: ValueKey<bool>(_isObscured),
                        color: _isFocused ? palette.linkColor : palette.muted,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 4),
            child: Text(
              _errorText!,
              style: AppFont.primary(
                fontSize: 12,
                color: const Color(0xFFD32F2F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Botón Principal (.btn-main) adaptativo ──────────────────────────────────
class AuthMainBtn extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const AuthMainBtn({
    super.key,
    required this.label,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  State<AuthMainBtn> createState() => _AuthMainBtnState();
}

class _AuthMainBtnState extends State<AuthMainBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.isLoading) setState(() => _isPressed = true);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          if (!widget.isLoading) {
            HapticFeedback.mediumImpact();
            widget.onTap();
          }
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: _isPressed ? palette.btnMainPressed : palette.btnMainBg,
              gradient: palette.btnMainGradient,
              boxShadow: [
                BoxShadow(
                  color: palette.btnMainBg.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: palette.btnMainText,
                    ),
                  )
                : Text(
                    widget.label,
                    style: AppFont.primary(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.btnMainText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Aviso Legal (.legal) ────────────────────────────────────────────────────
class AuthLegalNotice extends StatelessWidget {
  final VoidCallback? onPrivacyTap;
  final VoidCallback? onTermsTap;

  const AuthLegalNotice({
    super.key,
    this.onPrivacyTap,
    this.onTermsTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Text.rich(
        TextSpan(
          text: 'Al registrarte en Pivote aceptas la\n',
          style: AppFont.primary(
            fontSize: 14.5,
            height: 1.45,
            color: palette.muted,
            fontWeight: FontWeight.w400,
          ),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: onPrivacyTap,
                child: Text(
                  'Política de Privacidad',
                  style: AppFont.primary(
                    fontSize: 14.5,
                    height: 1.45,
                    color: palette.text,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: palette.text,
                  ),
                ),
              ),
            ),
            const TextSpan(text: ' y los '),
            WidgetSpan(
              child: GestureDetector(
                onTap: onTermsTap,
                child: Text(
                  'Términos de Servicio',
                  style: AppFont.primary(
                    fontSize: 14.5,
                    height: 1.45,
                    color: palette.text,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: palette.text,
                  ),
                ),
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Enlace pequeño (.small: "¿Olvidaste tu contraseña?") ─────────────────────
class AuthSmallLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const AuthSmallLink({
    super.key,
    this.text = '¿Olvidaste tu contraseña? ',
    this.linkText = 'Recupérala',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: AppFont.primary(
              fontSize: 15.5,
              color: palette.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Text(
              linkText,
              style: AppFont.primary(
                fontSize: 15.5,
                color: palette.linkColor,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: palette.linkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enlace al pie (.foot.tight) ─────────────────────────────────────────────
class AuthFootLink extends StatelessWidget {
  final String prefix;
  final String linkText;
  final VoidCallback onTap;

  const AuthFootLink({
    super.key,
    required this.prefix,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            prefix,
            style: AppFont.primary(
              fontSize: 16.5,
              color: palette.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Text(
              linkText,
              style: AppFont.primary(
                fontSize: 16.5,
                color: palette.linkColor,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: palette.linkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
