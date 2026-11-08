import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivote/core/theme/app_colors.dart';
import 'package:pivote/core/theme/app_typography.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';

/// Reusable User Avatar widget with the signature animated colorful SweepGradient ring.
/// Preserves the exact outer [size] (e.g. 40 on Home header, 24 on bottom nav).
class UserAvatar extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.size = 44,
    this.onTap,
    this.showBorder = true,
    this.borderColor,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getInitials(String name, String lastName) {
    final cleanName = name.trim();
    final cleanLastName = lastName.trim();

    final firstLetter =
        cleanName.isNotEmpty ? cleanName[0].toUpperCase() : '';
    final secondLetter =
        cleanLastName.isNotEmpty ? cleanLastName[0].toUpperCase() : '';

    if (firstLetter.isEmpty && secondLetter.isEmpty) {
      return 'U';
    }

    if (firstLetter.isNotEmpty && secondLetter.isNotEmpty) {
      return '$firstLetter$secondLetter';
    }

    if (cleanName.contains(' ')) {
      final parts = cleanName.split(' ');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
      }
    }

    return firstLetter.isNotEmpty ? firstLetter : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceAnimations = context.select<ThemeProvider, bool>(
      (p) => p.reduceAnimations,
    );

    if (reduceAnimations && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceAnimations && !_controller.isAnimating) {
      _controller.repeat();
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final localPath = userProvider.profileImagePath;
        final photoUrl = user?.photoUrl;

        ImageProvider? imageProvider;
        if (!kIsWeb && localPath != null && localPath.isNotEmpty) {
          final file = File(localPath);
          if (file.existsSync()) {
            imageProvider = FileImage(file);
          }
        } else if (photoUrl != null && photoUrl.isNotEmpty) {
          imageProvider = CachedNetworkImageProvider(photoUrl);
        }

        final initials = _getInitials(user?.name ?? '', user?.lastName ?? '');
        final ringPadding = widget.showBorder
            ? (widget.size >= 34 ? 2.2 : 1.6)
            : 0.0;
        final gapPadding = widget.showBorder
            ? (widget.size >= 34 ? 1.8 : 1.2)
            : 0.0;
        final innerSize =
            math.max(0.0, widget.size - (ringPadding + gapPadding) * 2);

        final innerCircle = Container(
          padding: EdgeInsets.all(gapPadding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.scaffoldBackgroundColor,
          ),
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF28282E)
                  : const Color(0xFF94A3B8),
            ),
            child: imageProvider != null
                ? ClipOval(
                    child: Image(
                      image: imageProvider,
                      width: innerSize,
                      height: innerSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialsFallback(initials, innerSize),
                    ),
                  )
                : _buildInitialsFallback(initials, innerSize),
          ),
        );

        final avatarWidget = widget.showBorder
            ? AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final angle = 3.4906585 + (_controller.value * 2 * math.pi);
                  return Container(
                    width: widget.size,
                    height: widget.size,
                    padding: EdgeInsets.all(ringPadding),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: const [
                          AppColors.violet,
                          AppColors.info,
                          AppColors.positive,
                          AppColors.warning,
                          AppColors.violet,
                        ],
                        transform: GradientRotation(angle),
                      ),
                    ),
                    child: child,
                  );
                },
                child: innerCircle,
              )
            : SizedBox(
                width: widget.size,
                height: widget.size,
                child: innerCircle,
              );

        if (widget.onTap != null) {
          return GestureDetector(
            onTap: widget.onTap,
            child: avatarWidget,
          );
        }

        return avatarWidget;
      },
    );
  }

  Widget _buildInitialsFallback(String initials, double innerSize) {
    return Center(
      child: Text(
        initials,
        style: AppFont.primary(
          fontSize: innerSize * 0.42,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
