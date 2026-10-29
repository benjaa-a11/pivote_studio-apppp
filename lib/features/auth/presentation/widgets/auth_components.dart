import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colores del HTML adaptados a la App Pivote ──────────────────────────────
// Fondo general de la app (dark mode de Pivote)
const Color kAuthScreenBg = Color(0xFF090B0F); // darkBg de Pivote

// Colores de la tarjeta y burbujas (del HTML original)
const Color kHtmlOrange = Color(0xFFE9744D);
const Color kHtmlGold = Color(0xFFD8B968);
const Color kHtmlGreen = Color(0xFF4DBB88);

// Colores del panel blanco y sus inputs
const Color kHtmlInk = Color(0xFF111111);
const Color kHtmlMuted = Color(0xFF6B6B6B);
const Color kHtmlField = Color(0xFFF4F4F4);
const Color kHtmlFieldFocus = Color(0xFFECECEC);
const Color kHtmlLine = Color(0xFFDCDCDC);
const Color kHtmlBtnMain = Color(0xFF0C0C0C);
const Color kHtmlBtnMainPressed = Color(0xFF222222);

// ─── SVG Oficial de Google ───────────────────────────────────────────────────
const String _kGoogleSvg = '''
<svg width="26" height="26" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.6 5.9c4.4-4.1 7-10.1 7-17.6z"/>
  <path fill="#FBBC05" d="M10.5 28.7c-.5-1.4-.8-3-.8-4.7s.3-3.2.8-4.7l-7.9-6.1C.9 16.4 0 20.100 0 24s.9 7.600 2.600 10.800l7.900-6.100z"/>
  <path fill="#34A853" d="M24 48c6.5 0 11.900-2.100 15.900-5.800l-7.600-5.900c-2.100 1.400-4.900 2.300-8.300 2.300-6.300 0-11.600-4.100-13.500-9.800l-7.900 6.100C6.500 42.600 14.600 48 24 48z"/>
</svg>
''';

// ─── Stage Layout (Pantalla completa nativa, sin fondos externos) ─────────────
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
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Contenido con scroll continuo
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: card,
                  ),
                ),
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
                        color: Colors.black.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hero,
        Transform.translate(
          offset: const Offset(0, -20),
          child: panel,
        ),
      ],
    );
  }
}

// ─── Hero con burbujas EXACTAS del HTML adaptado al notch superior ───────────
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
    final topPadding = MediaQuery.paddingOf(context).top;
    final contentHeight = single ? 126.0 : 166.0;
    final totalHeight = topPadding + contentHeight;

    final goldTop = topPadding + (single ? 44.0 : 66.0);
    final greenTop = topPadding + (single ? 64.0 : 92.0);

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Fondo naranja que llena hasta la parte superior de la pantalla
          Positioned.fill(
            child: Container(color: kHtmlOrange),
          ),

          // Burbuja Dorada (.gold)
          Positioned(
            left: -65,
            top: goldTop,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kHtmlGold,
              ),
            ),
          ),

          // Burbuja Verde (.green)
          Positioned(
            right: -40,
            top: greenTop,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kHtmlGreen,
              ),
            ),
          ),

          // Título centrado
          Positioned(
            top: topPadding + (single ? 32 : 46),
            left: 20,
            right: 20,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.figtree(
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel Blanco (.panel) con Theme claro aislado ────────────────────────────
// .panel { background:#fff; border-radius:30px 30px 0 0; padding:50px 23px 34px; text-align:center; }
class AuthPanel extends StatelessWidget {
  final List<Widget> children;

  const AuthPanel({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    // Forzamos un ThemeData claro dentro del panel blanco para aislarlo
    // totalmente del tema oscuro global de la app
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: kHtmlInk,
      scaffoldBackgroundColor: Colors.white,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: kHtmlInk,
        selectionColor: Color(0x33111111),
        selectionHandleColor: kHtmlInk,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: kHtmlField,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
    );

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Theme(
      data: lightTheme,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(24, 42, 24, 34 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
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
          height: 50,
          decoration: BoxDecoration(
            color: _isPressed ? const Color(0xFFFAFAFA) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kHtmlLine, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(
                _kGoogleSvg,
                width: 26,
                height: 26,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.figtree(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
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
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 22),
      child: Text(
        'o',
        style: GoogleFonts.figtree(
          fontSize: 15,
          color: const Color(0xFF555555),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ─── Input Pill (.field.pill) con fondo garantizado claro ────────────────────
// .field { flex:1; min-width:0; height:50px; border:0; outline:0; background:var(--field); font:400 17px 'Figtree'; color:var(--ink); padding:0 23px; }
// .field:focus { background:#ececec; }
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
    final bgColor = _isFocused ? kHtmlFieldFocus : kHtmlField;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 23),
          alignment: Alignment.center,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            cursorColor: kHtmlInk,
            cursorWidth: 1.5,
            style: GoogleFonts.figtree(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: kHtmlInk, // Texto negro visible
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              filled: true,
              fillColor: bgColor, // Fondo claro explícito
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              hintText: widget.placeholder,
              hintStyle: GoogleFonts.figtree(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8A8A8A),
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
              style: GoogleFonts.figtree(
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
    const leftRadius = BorderRadius.only(
      topLeft: Radius.circular(999),
      bottomLeft: Radius.circular(999),
    );
    const rightRadius = BorderRadius.only(
      topRight: Radius.circular(999),
      bottomRight: Radius.circular(999),
    );

    final firstBg = _firstFocused ? kHtmlFieldFocus : kHtmlField;
    final lastBg = _lastFocused ? kHtmlFieldFocus : kHtmlField;

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
                height: 50,
                decoration: BoxDecoration(
                  color: firstBg,
                  borderRadius: leftRadius,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 23),
                alignment: Alignment.center,
                child: TextFormField(
                  controller: widget.firstController,
                  focusNode: widget.firstFocus,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: widget.onFirstSubmitted,
                  cursorColor: kHtmlInk,
                  cursorWidth: 1.5,
                  style: GoogleFonts.figtree(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: kHtmlInk, // Texto negro visible
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: true,
                    fillColor: firstBg, // Fondo claro explícito
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.firstPlaceholder,
                    hintStyle: GoogleFonts.figtree(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A8A8A),
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
            const SizedBox(width: 4),
            // Last Name
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 50,
                decoration: BoxDecoration(
                  color: lastBg,
                  borderRadius: rightRadius,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 23),
                alignment: Alignment.center,
                child: TextFormField(
                  controller: widget.lastController,
                  focusNode: widget.lastFocus,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: widget.onLastSubmitted,
                  cursorColor: kHtmlInk,
                  cursorWidth: 1.5,
                  style: GoogleFonts.figtree(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: kHtmlInk, // Texto negro visible
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: true,
                    fillColor: lastBg, // Fondo claro explícito
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.lastPlaceholder,
                    hintStyle: GoogleFonts.figtree(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A8A8A),
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
              style: GoogleFonts.figtree(
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

// ─── Input Contraseña + Ojo corregido (Ojo cerrado cuando está oculta) ────────
// .row.pw .field{border-radius:999px 0 0 999px}
// .eye { width:54px; height:50px; border:0; background:var(--field); border-radius:0 999px 999px 0; display:flex; align-items:center; justify-content:center; cursor:pointer; color:#555; }
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
  // Inicia oculta con puntos ••••••
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
    const leftRadius = BorderRadius.only(
      topLeft: Radius.circular(999),
      bottomLeft: Radius.circular(999),
    );
    const rightRadius = BorderRadius.only(
      topRight: Radius.circular(999),
      bottomRight: Radius.circular(999),
    );

    final bgColor = _isFocused ? kHtmlFieldFocus : kHtmlField;

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
                height: 50,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: leftRadius,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 23),
                alignment: Alignment.center,
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: _isObscured,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onSubmitted,
                  cursorColor: kHtmlInk,
                  cursorWidth: 1.5,
                  style: GoogleFonts.figtree(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: kHtmlInk, // Texto negro visible
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: true,
                    fillColor: bgColor, // Fondo claro explícito
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: GoogleFonts.figtree(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A8A8A),
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
            // Botón ojo (.eye):
            // CUANDO ESTÁ OCULTA (_isObscured == true): Muestra ojo tachado (oculto)
            // CUANDO ESTÁ VISIBLE (_isObscured == false): Muestra ojo abierto (visible)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 54,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: rightRadius,
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
                            ? Icons.visibility_off_rounded // Ojo tachado = oculta
                            : Icons.visibility_rounded, // Ojo abierto = visible
                        key: ValueKey<bool>(_isObscured),
                        color: const Color(0xFF555555),
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
              style: GoogleFonts.figtree(
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

// ─── Botón Principal Negro (.btn-main) ────────────────────────────────────────
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
    return Padding(
      padding: const EdgeInsets.only(top: 25),
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
            height: 50,
            decoration: BoxDecoration(
              color: _isPressed ? kHtmlBtnMainPressed : kHtmlBtnMain,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: GoogleFonts.figtree(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Text.rich(
        TextSpan(
          text: 'Al registrarte en Pivote aceptas la\n',
          style: GoogleFonts.figtree(
            fontSize: 15,
            height: 1.4,
            color: kHtmlMuted,
            fontWeight: FontWeight.w400,
          ),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: onPrivacyTap,
                child: Text(
                  'Política de Privacidad',
                  style: GoogleFonts.figtree(
                    fontSize: 15,
                    height: 1.4,
                    color: kHtmlInk,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    decorationColor: kHtmlInk,
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
                  style: GoogleFonts.figtree(
                    fontSize: 15,
                    height: 1.4,
                    color: kHtmlInk,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                    decorationColor: kHtmlInk,
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
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: GoogleFonts.figtree(
              fontSize: 16,
              color: kHtmlMuted,
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
              style: GoogleFonts.figtree(
                fontSize: 16,
                color: kHtmlInk,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
                decorationColor: kHtmlInk,
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
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            prefix,
            style: GoogleFonts.figtree(
              fontSize: 17,
              color: const Color(0xFF111111),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Text(
              linkText,
              style: GoogleFonts.figtree(
                fontSize: 17,
                color: kHtmlInk,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
                decorationColor: kHtmlInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
