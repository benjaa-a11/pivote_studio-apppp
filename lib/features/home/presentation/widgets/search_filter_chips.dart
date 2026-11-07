import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';

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
    final palette = ProfilePalette.of(context);

    final tabs = [
      (
        tab: SearchFilterTab.all,
        label: 'Todos',
        icon: Icons.grid_view_rounded,
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
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = tabs[index];
          final isSelected = selectedTab == item.tab;

          final Color bgColor =
              isSelected ? palette.primaryBtnBg : palette.card;
          final Color fgColor =
              isSelected ? palette.primaryBtnText : palette.text;
          final Color borderColor =
              isSelected ? palette.primaryBtnBg : palette.border;

          return Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTabSelected(item.tab);
              },
              borderRadius: BorderRadius.circular(999),
              splashColor: Colors.transparent,
              highlightColor: palette.cardPressed.withValues(alpha: 0.5),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 15,
                      color: isSelected ? fgColor : palette.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 13.2,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: fgColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (item.count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? fgColor.withValues(alpha: 0.16)
                              : palette.iconBox,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${item.count}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? fgColor : palette.muted,
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
