import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';

enum SearchFilterTab { all, channels, radios, soccer }

class SearchFilterChips extends StatelessWidget {
  final SearchFilterTab selectedTab;
  final int totalCount;
  final int channelsCount;
  final int radiosCount;
  final int soccerCount;
  final ValueChanged<SearchFilterTab> onTabSelected;

  const SearchFilterChips({
    super.key,
    required this.selectedTab,
    required this.totalCount,
    required this.channelsCount,
    required this.radiosCount,
    required this.soccerCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.isDark;

    final tabs = [
      (
        tab: SearchFilterTab.all,
        label: 'Todos',
        icon: Icons.all_inclusive_rounded,
        count: totalCount,
      ),
      (
        tab: SearchFilterTab.channels,
        label: 'Canales TV',
        icon: Icons.live_tv_rounded,
        count: channelsCount,
      ),
      (
        tab: SearchFilterTab.radios,
        label: 'Radios',
        icon: Icons.radio_rounded,
        count: radiosCount,
      ),
      (
        tab: SearchFilterTab.soccer,
        label: 'Fútbol',
        icon: Icons.sports_soccer_rounded,
        count: soccerCount,
      ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = tabs[index];
          final isSelected = selectedTab == item.tab;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTabSelected(item.tab);
              },
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark
                          ? AppTheme.darkBg2.withValues(alpha: 0.8)
                          : theme.colorScheme.primary.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06)),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? AppShadows.glow(theme.colorScheme.primary, alpha: 0.3)
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 15,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppTheme.darkAccent
                              : theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (item.count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.count}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppTheme.darkAccent
                                    : theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
