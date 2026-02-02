import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../screens/search_screen.dart';
import '../providers/user_provider.dart';

class SearchHeader extends StatefulWidget {
  const SearchHeader({super.key});

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Buenos días,';
    if (hour >= 12 && hour < 19) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

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
                  Text(
                    _getGreeting(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Skeletonizer(
                    enabled: isLoading,
                    child: Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        fontSize: 24,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // High-End Search Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SearchScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      var begin = const Offset(0.0, 0.05);
                      var end = Offset.zero;
                      var curve = Curves.easeOutQuart;
                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.surface.withValues(alpha: 0.8),
                            theme.colorScheme.surface.withValues(alpha: 0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.05),
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
