import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colores EXACTOS del HTML ────────────────────────────────────────────────
// :root {
//   --bg:#b7cbe4; --orange:#e9744d; --gold:#d8b968; --green:#4dbb88;
//   --ink:#111; --muted:#6b6b6b; --field:#f4f4f4; --line:#dcdcdc;
// }
const Color kHtmlBg = Color(0xFFB7CBE4);
const Color kHtmlOrange = Color(0xFFE9744D);
const Color kHtmlGold = Color(0xFFD8B968);
const Color kHtmlGreen = Color(0xFF4DBB88);
const Color kHtmlInk = Color(0xFF111111);
const Color kHtmlMuted = Color(0xFF6B6B6B);
const Color kHtmlField = Color(0xFFF4F4F4);
const Color kHtmlFieldFocus = Color(0xFFECECEC);
const Color kHtmlLine = Color(0xFFDCDCDC);
const Color kHtmlBtnMain = Color(0xFF0C0C0C);
const Color kHtmlBtnMainPressed = Color(0xFF222222);

// ─── SVGs Oficiales del HTML ─────────────────────────────────────────────────
const String _kGoogleSvg = '''
<svg width="26" height="26" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.6 5.9c4.4-4.1 7-10.1 7-17.6z"/>
  <path fill="#FBBC05" d="M10.5 28.7c-.5-1.4-.8-3-.8-4.7s.3-3.2.8-4.7l-7.9-6.1C.9 16.4 0 20.100 0 24s.9 7.600 2.600 10.800l7.900-6.100z"/>
  <path fill="#34A853" d="M24 48c6.5 0 11.900-2.100 15.900-5.800l-7.600-5.900c-2.100 1.400-4.900 2.300-8.300 2.300-6.300 0-11.600-4.100-13.500-9.800l-7.900 6.100C6.500 42.600 14.600 48 24 48z"/>
</svg>
''';

const String _kEyeOpenSvg = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="#555555">
  <path d="M12 5C6.500 5 2.700 9 1 12c1.700 3 5.500 7 11 7s9.300-4 11-7c-1.700-3-5.500-7-11-7zm0 11.500a4.500 4.500 0 110-9 4.500 4.500 0 010 9zm0-7a2.500 2.500 0 100 5 2.500 2.500 0 000-5z"/>
</svg>
''';

const String _kEyeClosedSvg = '''
<svg width="22" height="22" viewBox="0 0 24 24" fill="#555555">
  <path d="M12 7c2.76 0 5 2.24 5 5 0 .65-.13 1.26-.36 1.83l2.92 2.92c1.51-1.26 2.7-2.89 3.44-4.75-1.73-4.39-6-7.5-11-7.5-1.4 0-2.74.25-3.98.7l2.16 2.16C10.74 7.13 11.35 7 12 7zM2 4.27l2.28 2.28.46.46C3.08 8.3 1.78 10.02 1 12c1.73 4.39 6 7.5 11 7.5 1.55 0 3.03-.3 4.38-.84l.42.42L19.73 22 21 20.73 3.27 3 2 4.27zM7.53 9.8l1.55 1.55c-.05.21-.08.43-.08.65 0 1.66 1.34 3 3 3 .22 0 .44-.03.65-.08l1.55 1.55c-.67.33-1.41.53-2.2.53-2.76 0-5-2.24-5-5 0-.79.2-1.53.53-2.2zm4.31-.78l3.15 3.15.02-.16c0-1.66-1.34-3-3-3l-.17.01z"/>
</svg>
''';

// ─── Fondo de pantalla con manchas radiales del HTML ─────────────────────────
// radial-gradient(60% 45% at 100% 8%, rgba(255,255,255,.35), transparent 70%),
// radial-gradient(50% 50% at 0% 85%, rgba(255,255,255,.3), transparent 70%);
class StageBackgroundPainter extends CustomPainter {
  const StageBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Mancha superior derecha (100% 8%)
    final p1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.0, -0.84),
        radius: 0.70,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.70],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p1);

    // Mancha inferior izquierda (0% 85%)
    final p2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1.0, 0.70),
        radius: 0.65,
        colors: [
          Colors.white.withValues(alpha: 0.30),
          Colors.transparent,
        ],
        stops: const [0.0, 0.70],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p2);
  }

  @override
  bool shouldRepaint(StageBackgroundPainter oldDelegate) => false;
}

// ─── Stage Container (Envoltorio de tarjeta centrado) ─────────────────────────
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
    return Scaffold(
      backgroundColor: kHtmlBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fondo con manchas radiales
          const Positioned.fill(
            child: CustomPaint(
              painter: StageBackgroundPainter(),
            ),
          ),

          // Botón volver atrás
          if (onBack != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onBack,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: kHtmlInk,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Tarjeta centrada con scroll
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 370),
                    child: card,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta con sombra idéntica al HTML ──────────────────────────────────────
// .card { width:370px; border-radius:30px; overflow:hidden; background:var(--orange); box-shadow:0 30px 60px -20px rgba(40,60,100,.35); }
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
    return Container(
      decoration: BoxDecoration(
        color: kHtmlOrange,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C64).withValues(alpha: 0.35),
            blurRadius: 60,
            offset: const Offset(0, 30),
            spreadRadius: -20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hero,
            // margin-top: -1px en el panel para evitar líneas de subpixel
            Transform.translate(
              offset: const Offset(0, -1),
              child: panel,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero con burbujas EXACTAS del HTML ──────────────────────────────────────
// .hero { position:relative; height:174px; padding-top:58px; text-align:center; color:#fff; overflow:hidden }
// .hero.single { height:122px; padding-top:58px }
// .hero .gold { width:150px; height:150px; left:-75px; top:77px; background:var(--gold) }
// .hero .green { width:130px; height:130px; right:-45px; top:105px; background:var(--green) }
// .hero.single .gold { top:57px }
// .hero.single .green { top:80px }
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
    final height = single ? 122.0 : 174.0;
    final goldTop = single ? 57.0 : 77.0;
    final greenTop = single ? 80.0 : 105.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Fondo naranja
          Positioned.fill(
            child: Container(color: kHtmlOrange),
          ),

          // Burbuja Dorada (.gold: width 150, height 150, left -75)
          Positioned(
            left: -75,
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

          // Burbuja Verde (.green: width 130, height 130, right -45)
          Positioned(
            right: -45,
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

          // Título h1 (padding-top: 58px)
          Positioned(
            top: 58,
            left: 16,
            right: 16,
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

// ─── Panel Blanco (.panel) ───────────────────────────────────────────────────
// .panel { background:#fff; border-radius:30px 30px 0 0; padding:50px 23px 34px; text-align:center; }
class AuthPanel extends StatelessWidget {
  final List<Widget> children;

  const AuthPanel({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(23, 50, 23, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ─── Botón Google (.btn-google) ──────────────────────────────────────────────
// .btn-google { width:100%; height:50px; border-radius:999px; font:500 17px 'Figtree'; display:flex; align-items:center; justify-content:center; gap:12px; background:#fff; border:1px solid var(--line); color:#333; }
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
// .or { margin:20px 0 22px; font-size:15px; color:#555 }
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

// ─── Input Pill Individual (.field.pill) ─────────────────────────────────────
// .field { flex:1; min-width:0; height:50px; border:0; outline:0; background:var(--field); font:400 17px 'Figtree'; color:var(--ink); padding:0 23px; }
// .field:focus { background:#ececec; }
// .pill { border-radius:999px }
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
            color: _isFocused ? kHtmlFieldFocus : kHtmlField,
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
              color: kHtmlInk,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
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
// .row .field:first-child:not(:last-child){border-radius:999px 0 0 999px}
// .row .field:last-child:not(:first-child){border-radius:0 999px 999px 0}
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
                  color: _firstFocused ? kHtmlFieldFocus : kHtmlField,
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
                    color: kHtmlInk,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
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
                  color: _lastFocused ? kHtmlFieldFocus : kHtmlField,
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
                    color: kHtmlInk,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
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

// ─── Input Password con Botón Ojo (.row.pw .field + .eye) ───────────────────
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
            // Password Field
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
                    color: kHtmlInk,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
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
            // Eye Button (exact SVG)
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
                      child: SvgPicture.string(
                        _isObscured ? _kEyeOpenSvg : _kEyeClosedSvg,
                        key: ValueKey<bool>(_isObscured),
                        width: 22,
                        height: 22,
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
// .btn-main { margin-top:25px; border:0; background:#0c0c0c; color:#fff; font-weight:700; width:100%; height:50px; border-radius:999px; }
// .btn-main:hover { background:#222; }
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
// .legal { margin:22px 0 0; font-size:15px; line-height:1.4; color:var(--muted) }
// .legal a { color:var(--ink); text-decoration:none; border-bottom:1px solid var(--ink) }
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
// .small { margin:16px 0 0; font-size:16px; color:var(--muted) }
// .small a { color:var(--ink); text-decoration:none; border-bottom:1px solid var(--ink) }
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
// .foot { margin:26px 0 0; font-size:17px }
// .foot.tight { margin-top:24px }
// .foot a { color:var(--ink); text-decoration:none; border-bottom:1px solid var(--ink) }
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
