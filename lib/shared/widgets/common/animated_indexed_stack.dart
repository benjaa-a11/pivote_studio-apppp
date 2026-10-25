import 'package:flutter/material.dart';
import 'package:pivote/core/animations/app_animations.dart';

/// Un [IndexedStack] animado de alto rendimiento para navegación entre pestañas.
///
/// Mantiene vivos los estados, controladores y posiciones de scroll de todas las
/// pantallas en memoria (mediante [Offstage] y [TickerMode]), pero ejecuta una
/// transición suave de opacidad y micro-escala al cambiar de pestaña.
///
/// Evita el corte abrupto del [IndexedStack] estándar y proporciona la fluidez
/// de aplicaciones como Spotify, Apple TV y Netflix.
class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 240),
    this.curve = AppAnimations.appleSpringEase,
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _scaleAnimation = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _currentIndex = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: widget.children,
        ),
      ),
    );
  }
}
