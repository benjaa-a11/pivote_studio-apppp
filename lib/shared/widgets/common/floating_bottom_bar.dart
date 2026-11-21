import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

class FloatingBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingBottomBarItem> items;

  FloatingBottomBar({
    super.key,
    int? currentIndex,
    int? selectedIndex,
    ValueChanged<int>? onTap,
    ValueChanged<int>? onDestinationSelected,
    List<FloatingBottomBarItem>? items,
    List<FloatingBottomBarItem>? destinations,
  })  : currentIndex = selectedIndex ?? currentIndex ?? 0,
        onTap = onDestinationSelected ?? onTap ?? ((_) {}),
        items = destinations ?? items ?? const [];

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        bottomInset > 0 ? bottomInset + 8 : 16,
      ),
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.56 : 0.12),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppMaterials.blurRegular,
            sigmaY: AppMaterials.blurRegular,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBg1.withValues(alpha: 0.86)
                  : AppColors.lightBg1.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder2
                    : AppColors.lightBorder,
                width: 1.0,
              ),
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return Expanded(
                  child: _BarTab(
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      if (!isSelected) HapticFeedback.selectionClick();
                      onTap(index);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingBottomBarItem {
  final Widget icon;
  final Widget? activeIcon;
  final String label;

  FloatingBottomBarItem({
    required dynamic icon,
    dynamic activeIcon,
    required this.label,
  })  : icon = icon is IconData ? Icon(icon) : (icon as Widget),
        activeIcon = activeIcon == null
            ? null
            : (activeIcon is IconData
                ? Icon(activeIcon)
                : (activeIcon as Widget));
}

class _BarTab extends StatelessWidget {
  final FloatingBottomBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _BarTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accentColor = AppTheme.accent(context);
    final inactiveColor = AppTheme.textTertiary(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: ApplePressable(
        scaleDownFactor: 0.94,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        enableHaptics: false,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: isSelected
                ? RadialGradient(
                    center: const Alignment(0.0, -0.45),
                    radius: 1.1,
                    colors: [
                      accentColor.withValues(alpha: isDark ? 0.16 : 0.11),
                      accentColor.withValues(alpha: 0.0),
                    ],
                  )
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 1,
                child: AnimatedContainer(
                  duration: AppMotion.normal,
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 22 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: isSelected && isDark
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.55),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 3),
                  AnimatedScale(
                    scale: isSelected ? 1.07 : 1.0,
                    duration: AppMotion.fast,
                    curve: Curves.easeOutCubic,
                    child: isSelected && item.activeIcon != null
                        ? item.activeIcon!
                        : item.icon,
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: AppMotion.fast,
                    curve: Curves.easeOutCubic,
                    style: AppFont.primary(
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? accentColor : inactiveColor,
                      height: 1.1,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
