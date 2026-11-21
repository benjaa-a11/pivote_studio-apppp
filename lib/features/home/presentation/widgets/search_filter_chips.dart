import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

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
        physics: const ClampingScrollPhysics(),
        padding: AppResponsive.screenHorizontalPadding(context),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = tabs[index];
          return PivoteFilterPill(
            label: item.label,
            icon: item.icon,
            count: item.count,
            selected: selectedTab == item.tab,
            onTap: () => onTabSelected(item.tab),
          );
        },
      ),
    );
  }
}
