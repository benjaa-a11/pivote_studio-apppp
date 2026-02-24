import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pivote/features/home/presentation/screens/search_screen.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/services/greeting_service.dart';

class SearchHeader extends StatefulWidget {
  const SearchHeader({super.key});

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ??
                theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final isLoading =
                  userProvider.isLoading || userProvider.user == null;
              final name = userProvider.user?.name ?? 'Usuario Pro';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppAnimations.staggeredSlideIn(
                    index: 0,
                    child: Row(
                      children: [
                        Text(
                          GreetingService.getGreeting(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '👋',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Skeletonizer(
                    enabled: isLoading,
                    child: Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        fontSize: 26,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppAnimations.staggeredSlideIn(
                    index: 1,
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          GreetingService.getSubtitle(),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // High-End Search Button (Glassmorphic)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  AppAnimations.createFadeRoute(const SearchScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Hero(
                  tag: 'search_icon',
                  child: Icon(
                    Icons.search_rounded,
                    size: 24,
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
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
