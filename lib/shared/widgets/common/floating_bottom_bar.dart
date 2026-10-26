import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

class FloatingBottomBarItem {
  final Widget icon;
  final Widget activeIcon;
  final String label;

  const FloatingBottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class FloatingBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingBottomBarItem> destinations;

  const FloatingBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;

    final backgroundColor =
        theme.cardColor.withValues(alpha: isDark ? 0.82 : 0.88);
    final specularBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.70);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: specularBorderColor, width: 1.0),
        boxShadow: AppShadows.appleDepth(context, elevation: 1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppMaterials.blurRegular,
            sigmaY: AppMaterials.blurRegular,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.06 : 0.02),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final usableWidth = constraints.maxWidth;
                final itemWidth = usableWidth / destinations.length;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Apple-style sliding pill indicator with spring curve
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 340),
                      curve: AppAnimations.appleSpringEase,
                      left: selectedIndex * itemWidth + 4,
                      width: itemWidth - 8,
                      top: 3,
                      bottom: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: isDark ? 0.16 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.28 : 0.22,
                            ),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: isDark ? 0.12 : 0.06,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(destinations.length, (index) {
                        final item = destinations[index];
                        final isSelected = index == selectedIndex;

                        return Expanded(
                          child: ApplePressable(
                            scaleDownFactor: 0.94,
                            enableHaptics: true,
                            onTap: () {
                              onDestinationSelected(index);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.transparent,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: isSelected ? 1.08 : 1.0,
                                    duration: const Duration(milliseconds: 220),
                                    curve: AppAnimations.appleSpringEase,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      child: isSelected
                                          ? SizedBox(
                                              key: ValueKey('active_$index'),
                                              child: item.activeIcon,
                                            )
                                          : SizedBox(
                                              key: ValueKey('inactive_$index'),
                                              child: item.icon,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      letterSpacing: -0.2,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.52),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
