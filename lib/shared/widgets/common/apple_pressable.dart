import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivote/core/animations/app_animations.dart';

/// Apple-grade interactive pressable wrapper.
///
/// Implements Emil Kowalski's Apple Design principles:
/// 1. "Respond on pointer-down, not on release."
/// 2. Critically damped spring physics on release (damping 1.0 feel).
/// 3. Immediate subtle tactile scale (0.965) + instant haptic feedback.
class ApplePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDownFactor;
  final double? opacityDownFactor;
  final bool enableHaptics;
  final HitTestBehavior behavior;
  final BorderRadius? borderRadius;

  const ApplePressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDownFactor = 0.965,
    this.opacityDownFactor,
    this.enableHaptics = true,
    this.behavior = HitTestBehavior.opaque,
    this.borderRadius,
  });

  @override
  State<ApplePressable> createState() => _ApplePressableState();
}

class _ApplePressableState extends State<ApplePressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Fast attack on pointer-down, smooth spring settle on release
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDownFactor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: AppAnimations.appleSpringEase,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: widget.opacityDownFactor ?? 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void didUpdateWidget(ApplePressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleDownFactor != widget.scaleDownFactor) {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.scaleDownFactor,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: AppAnimations.appleSpringEase,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _controller.forward();
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    Widget content = widget.child;

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress != null
          ? () {
              if (widget.enableHaptics) {
                HapticFeedback.mediumImpact();
              }
              widget.onLongPress!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final opacity = _opacityAnimation.value;

          Widget current = child!;
          if (widget.opacityDownFactor != null && opacity < 1.0) {
            current = Opacity(opacity: opacity, child: current);
          }

          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: current,
          );
        },
        child: content,
      ),
    );
  }
}
