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
                  ? AppColors.glassPanel
                  : AppTheme.lightBg1.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isDark
                    ? AppColors.glassBorder
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

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: ApplePressable(
        scaleDownFactor: 0.94,
        borderRadius: BorderRadius.circular(AppRadius.md),
        enableHaptics: false,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Indicador discreto superior: no cubre el icono ni el texto.
            Positioned(
              top: 0,
              child: AnimatedContainer(
                duration: AppMotion.normal,
                curve: Curves.easeOutCubic,
                width: isSelected ? 22 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 2),
                AnimatedScale(
                  scale: isSelected ? 1.06 : 1.0,
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
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
    );
  }
}
