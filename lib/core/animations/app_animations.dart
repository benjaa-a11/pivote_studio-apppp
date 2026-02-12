import 'package:flutter/material.dart';

/// Centralized animation configurations for consistent app-wide animations
class AppAnimations {
  // Animation Durations - Optimized for smooth, professional feel
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Animation Curves - Professional and smooth
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve sharpCurve = Curves.easeInOutCubic;
  static const Curve modalCurve = Curves.easeOutCubic;
  static const Curve subtleCurve = Curves.easeInOutQuad;

  // Slide Up Transition for Modals (Bottom Sheets, Dialogs)
  static Route<T> slideUpTransition<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: modalCurve),
        );

        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? medium,
    );
  }

  // Smooth Fade In for elements
  static Widget smoothFadeIn({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration ?? const Duration(milliseconds: 250),
      curve: curve ?? Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  // Scale In for buttons and interactive elements
  static Widget scaleIn({
    required Widget child,
    Duration? duration,
    double? begin,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin ?? 0.8, end: 1.0),
      duration: duration ?? fast,
      curve: smoothCurve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Pulse Animation for navigation icons
  static Widget pulseIcon({
    required Widget child,
    required bool isSelected,
    Duration? duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 1.0,
        end: isSelected ? 1.15 : 1.0,
      ),
      duration: duration ?? const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
      onEnd: () {
        // Return to normal size after pulse
      },
    );
  }

  // Scale Transition
  static Widget scaleTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: smoothCurve),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // Improved Shimmer Animation with more natural motion
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    return _ShimmerAnimation(
      duration: duration,
      child: child,
    );
  }

  // Staggered Slide In for lists - very professional feel
  static Widget staggeredSlideIn({
    required int index,
    required Widget child,
    Duration delay = const Duration(milliseconds: 60),
    Duration duration = const Duration(milliseconds: 450),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Improved Page Transition (iOS-like)
  static Route<T> createRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var slideTween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: animation, curve: const Interval(0.0, 0.5)));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: fadeTween,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Fade Route
  static Route<T> createFadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: fast,
    );
  }
}

// Internal helper for shimmer to avoid repetitive logic
class _ShimmerAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _ShimmerAnimation({required this.child, required this.duration});

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05)),
                Colors.transparent,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
