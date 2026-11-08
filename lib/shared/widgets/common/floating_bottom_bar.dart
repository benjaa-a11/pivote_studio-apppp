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
    final theme = Theme.of(context);
    final isDark = theme.isDark;
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
            color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.12),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          if (isDark)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.04),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 4),
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
                  ? AppTheme.darkBg1.withValues(alpha: 0.88)
                  : AppTheme.lightBg1.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppTheme.lightBorder,
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
                    isDark: isDark,
                    theme: theme,
                    onTap: () {
                      if (!isSelected) {
                        HapticFeedback.selectionClick();
                        onTap(index);
                      }
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

class _BarTab extends StatelessWidget {
  final FloatingBottomBarItem item;
  final bool isSelected;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _BarTab({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = theme.colorScheme.primary;
    final inactiveColor = isDark ? AppTheme.darkText3 : AppTheme.lightText3;

    return ApplePressable(
      scaleDownFactor: 0.92,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      enableHaptics: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.springSnappy,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.14 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: isDark ? 0.28 : 0.22)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: AppMotion.fast,
              curve: AppMotion.springBouncy,
              child: isSelected && item.activeIcon != null
                  ? item.activeIcon!
                  : item.icon,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              curve: AppMotion.curveOut,
              style: AppFont.primary(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: isSelected ? -0.1 : 0,
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
