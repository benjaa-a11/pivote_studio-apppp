import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';

/// Reusable User Avatar widget. Displays:
/// 1. Cached local image file if available.
/// 2. Remote photoUrl if available.
/// 3. Uppercase initials generated from user's first and last name (e.g. "BF" for Benjamin Ferrer).
class UserAvatar extends StatelessWidget {
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

  String _getInitials(String name, String lastName) {
    final cleanName = name.trim();
    final cleanLastName = lastName.trim();

    String firstLetter = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : '';
    String secondLetter = cleanLastName.isNotEmpty ? cleanLastName[0].toUpperCase() : '';

    if (firstLetter.isEmpty && secondLetter.isEmpty) {
      return 'P';
    }

    if (firstLetter.isNotEmpty && secondLetter.isNotEmpty) {
      return '$firstLetter$secondLetter';
    }

    // If only name is present, try to extract second letter from space if available
    if (cleanName.contains(' ')) {
      final parts = cleanName.split(' ');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
      }
    }

    return firstLetter.isNotEmpty ? firstLetter : 'P';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final localPath = userProvider.profileImagePath;
        final photoUrl = user?.photoUrl;

        ImageProvider? imageProvider;
        if (localPath != null && localPath.isNotEmpty) {
          final file = File(localPath);
          if (file.existsSync()) {
            imageProvider = FileImage(file);
          }
        } else if (photoUrl != null && photoUrl.isNotEmpty) {
          imageProvider = CachedNetworkImageProvider(photoUrl);
        }

        final initials = _getInitials(user?.name ?? '', user?.lastName ?? '');

        final avatarWidget = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: imageProvider == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  )
                : null,
            border: showBorder
                ? Border.all(
                    color: borderColor ??
                        (isDark
                            ? theme.colorScheme.primary.withValues(alpha: 0.4)
                            : theme.colorScheme.primary.withValues(alpha: 0.25)),
                    width: size > 30 ? 1.5 : 1.0,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary
                    .withValues(alpha: isDark ? 0.2 : 0.1),
                blurRadius: size * 0.25,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: imageProvider != null
              ? ClipOval(
                  child: Image(
                    image: imageProvider,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildInitialsFallback(initials),
                  ),
                )
              : _buildInitialsFallback(initials),
        );

        if (onTap != null) {
          return GestureDetector(
            onTap: onTap,
            child: avatarWidget,
          );
        }

        return avatarWidget;
      },
    );
  }

  Widget _buildInitialsFallback(String initials) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.spaceGrotesk(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
