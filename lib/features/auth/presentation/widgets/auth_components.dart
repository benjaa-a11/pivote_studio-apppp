import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

// ─── Paleta de colores para Auth (adaptada a Pivote con color vivo) ───────────
/// Fondo del header: deep navy-slate con matiz deportivo
const Color kAuthHeaderBg = Color(0xFF0D1522);

/// Burbuja izquierda: Verde lima neón insignia de Pivote
const Color kAuthBubble1 = Color(0xFFC8FF47);

/// Burbuja derecha: Azul eléctrico vivo de Pivote
const Color kAuthBubble2 = Color(0xFF1677FF);

/// Color del panel inferior
const Color kAuthPanelBg = Colors.white;

/// Color de fondo de los inputs
const Color kAuthFieldBg = Color(0xFFF4F4F4);

/// Color de borde y separadores
const Color kAuthLineColor = Color(0xFFDCDCDC);

/// Color de texto principal
const Color kAuthInk = Color(0xFF111111);

/// Color de texto secundario / muted
const Color kAuthMuted = Color(0xFF6B6B6B);

// ─── Header con Burbujas (fiel al HTML original) ──────────────────────────────
class AuthHeader extends StatelessWidget {
  final String title;
  final bool compact;
  final VoidCallback? onBack;

  const AuthHeader({
    super.key,
    required this.title,
    this.compact = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    // Dimensiones exactas del HTML: 122px (login/single) y 174px (signup)
    final heroHeight = compact ? 122.0 : 174.0;
    final totalHeight = heroHeight + topPadding;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Fondo base con sutil gradiente deportivo
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF090E17),
                    Color(0xFF0F1B2D),
                    Color(0xFF132238),
                  ],
                ),
              ),
            ),
          ),

          // Manchas de luz radial (efecto body::before del HTML)
          Positioned.fill(
            child: CustomPaint(painter: _AuthLightRaysPainter()),
          ),

          // Burbuja 1: Verde lima neón (HTML: .gold { width:150px; left:-75px; top:77px/57px })
          Positioned(
            left: -75,
            top: topPadding + (compact ? 57 : 77),
            child: const _AuthBubble(
              size: 150,
              color: kAuthBubble1,
            ),
          ),

          // Burbuja 2: Azul eléctrico (HTML: .green { width:130px; right:-45px; top:105px/80px })
          Positioned(
            right: -45,
            top: topPadding + (compact ? 80 : 105),
            child: const _AuthBubble(
              size: 130,
              color: kAuthBubble2,
            ),
          ),

          // Botón volver atrás (si está disponible)
          if (onBack != null)
            Positioned(
              top: topPadding + 8,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: onBack,
                tooltip: 'Volver',
              ),
            ),

          // Título centrado (HTML: .hero h1 { font-size:30px; font-weight:700 })
          Positioned(
            top: topPadding + 42,
            left: 20,
            right: 20,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.figtree(
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _AuthBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _AuthLightRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Luz suave superior derecha
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.9, size.height * 0.1),
        radius: size.width * 0.55,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p1);

    // Luz suave inferior izquierda
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          kAuthBubble1.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(0, size.height),
        radius: size.width * 0.6,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p2);
  }

  @override
  bool shouldRepaint(_AuthLightRaysPainter oldDelegate) => false;
}

// ─── Botón Google (HTML: .btn-google) ─────────────────────────────────────────
class AuthGoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AuthGoogleButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed ?? () {},
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: const BorderSide(color: kAuthLineColor, width: 1),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF333333),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleIcon(size: 22),
            const SizedBox(width: 12),
            Text(
              'Sign in with Google',
              style: GoogleFonts.figtree(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    final colors = [
      const Color(0xFFEA4335), // Rojo
      const Color(0xFF4285F4), // Azul
      const Color(0xFFFBBC05), // Amarillo
      const Color(0xFF34A853), // Verde
    ];
    final sweeps = [1.57, 1.57, 0.79, 1.38];
    final starts = [
      -math.pi / 2,
      math.pi,
      math.pi / 2,
      -math.pi,
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.40;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
        starts[i],
        sweeps[i],
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoogleIconPainter oldDelegate) => false;
}

// ─── Separador "or" (HTML: .or) ──────────────────────────────────────────────
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: kAuthLineColor, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'or',
              style: GoogleFonts.figtree(
                fontSize: 15,
                color: const Color(0xFF555555),
              ),
            ),
          ),
          const Expanded(child: Divider(color: kAuthLineColor, thickness: 1)),
        ],
      ),
    );
  }
}

// ─── Campo Pill completo (HTML: .field.pill) ──────────────────────────────────
class AuthPillField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  const AuthPillField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(999));

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: GoogleFonts.figtree(
        color: kAuthInk,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.figtree(
          color: const Color(0xFF8A8A8A),
          fontSize: 17,
        ),
        filled: true,
        fillColor: kAuthFieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 23, vertical: 15),
        border: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1.2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppTheme.darkDanger, width: 1.2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppTheme.darkDanger, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ─── Fila dividida en dos pills (First Name / Last Name en HTML) ───────────────
class AuthSplitPillRow extends StatelessWidget {
  final TextEditingController leftController;
  final TextEditingController rightController;
  final FocusNode? leftFocus;
  final FocusNode? rightFocus;
  final String leftHint;
  final String rightHint;
  final FormFieldValidator<String>? leftValidator;
  final FormFieldValidator<String>? rightValidator;
  final ValueChanged<String>? leftSubmitted;
  final ValueChanged<String>? rightSubmitted;

  const AuthSplitPillRow({
    super.key,
    required this.leftController,
    required this.rightController,
    this.leftFocus,
    this.rightFocus,
    required this.leftHint,
    required this.rightHint,
    this.leftValidator,
    this.rightValidator,
    this.leftSubmitted,
    this.rightSubmitted,
  });

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

    InputDecoration dec(String hint, BorderRadius r) => InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.figtree(
            color: const Color(0xFF8A8A8A),
            fontSize: 17,
          ),
          filled: true,
          fillColor: kAuthFieldBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(borderRadius: r, borderSide: BorderSide.none),
          enabledBorder:
              OutlineInputBorder(borderRadius: r, borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: r,
            borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: r,
            borderSide: const BorderSide(color: AppTheme.darkDanger, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: r,
            borderSide: const BorderSide(color: AppTheme.darkDanger, width: 1.5),
          ),
        );

    final style = GoogleFonts.figtree(
      color: kAuthInk,
      fontSize: 17,
      fontWeight: FontWeight.w400,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: leftController,
            focusNode: leftFocus,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: leftSubmitted,
            validator: leftValidator,
            style: style,
            decoration: dec(leftHint, leftRadius),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextFormField(
            controller: rightController,
            focusNode: rightFocus,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: rightSubmitted,
            validator: rightValidator,
            style: style,
            decoration: dec(rightHint, rightRadius),
          ),
        ),
      ],
    );
  }
}

// ─── Campo Password con botón ojo (HTML: .row.pw) ────────────────────────────
class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  const AuthPasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hint = 'Password',
    required this.isVisible,
    required this.onToggleVisibility,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: !isVisible,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            validator: validator,
            style: GoogleFonts.figtree(
              color: kAuthInk,
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.figtree(
                color: const Color(0xFF8A8A8A),
                fontSize: 17,
              ),
              filled: true,
              fillColor: kAuthFieldBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 23, vertical: 15),
              border: const OutlineInputBorder(
                borderRadius: leftRadius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: leftRadius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: leftRadius,
                borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1.2),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: leftRadius,
                borderSide: BorderSide(color: AppTheme.darkDanger, width: 1.2),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: leftRadius,
                borderSide: BorderSide(color: AppTheme.darkDanger, width: 1.5),
              ),
            ),
          ),
        ),
        Container(
          width: 54,
          height: 50,
          decoration: const BoxDecoration(
            color: kAuthFieldBg,
            borderRadius: rightRadius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: rightRadius,
              onTap: onToggleVisibility,
              child: Center(
                child: Icon(
                  isVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: const Color(0xFF555555),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Botón Principal Negro (HTML: .btn-main) ──────────────────────────────────
class AuthMainButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const AuthMainButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C0C0C),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF0C0C0C).withValues(alpha: 0.4),
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: isLoading
            ? const PivoteLoader(color: Colors.white, size: 22, strokeWidth: 2.5)
            : Text(
                label,
                style: GoogleFonts.figtree(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ─── Enlace al pie (HTML: .foot) ──────────────────────────────────────────────
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prefix,
          style: GoogleFonts.figtree(
            fontSize: 17,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkText,
            style: GoogleFonts.figtree(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: kAuthInk,
              decoration: TextDecoration.underline,
              decorationColor: kAuthInk,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Aviso Legal (HTML: .legal) ───────────────────────────────────────────────
class AuthLegalNotice extends StatelessWidget {
  const AuthLegalNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Text.rich(
        TextSpan(
          text: 'Signing up for a Pivote account means you\nagree to the ',
          style: GoogleFonts.figtree(
            fontSize: 15,
            height: 1.4,
            color: kAuthMuted,
          ),
          children: const [
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                color: kAuthInk,
                decoration: TextDecoration.underline,
                decorationColor: kAuthInk,
              ),
            ),
            TextSpan(text: ' and '),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(
                color: kAuthInk,
                decoration: TextDecoration.underline,
                decorationColor: kAuthInk,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
