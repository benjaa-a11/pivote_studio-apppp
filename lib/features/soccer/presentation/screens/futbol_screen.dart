import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/screens/match_detail_screen.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class FutbolScreen extends StatefulWidget {
  const FutbolScreen({super.key});

  @override
  State<FutbolScreen> createState() => _FutbolScreenState();
}

class _FutbolScreenState extends State<FutbolScreen> {
  List<_LeagueSectionData> _buildSections(SoccerData data) {
    if (data.leagueGroups.isNotEmpty) {
      return data.leagueGroups
          .where((g) => g.matches.isNotEmpty)
          .map((g) => _LeagueSectionData(league: g.league, matches: g.matches))
          .toList();
    }

    final grouped = <String, List<SoccerMatch>>{};
    final leagueById = <String, SoccerLeague>{};
    for (final m in data.matches) {
      final lid = m.leagueData.id.isNotEmpty ? m.leagueData.id : 'other';
      leagueById[lid] = m.leagueData;
      grouped.putIfAbsent(lid, () => []).add(m);
    }

    return grouped.entries
        .map((e) => _LeagueSectionData(
              league: leagueById[e.key]!,
              matches: e.value,
            ))
        .toList();
  }

  DateTime _currentSelectedDate(String key) {
    if (key == 'today') return DateTime.now();
    return DateTime.tryParse(key) ?? DateTime.now();
  }

  Future<void> _openCustomDatePicker(
    BuildContext context,
    SoccerProvider soccerProvider,
  ) async {
    unawaited(HapticFeedback.lightImpact());
    final initial = _currentSelectedDate(soccerProvider.selectedDateKey);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xBD02040A),
      useSafeArea: true,
      builder: (_) => _CustomCalendarSheet(initialDate: initial),
    );
    if (picked != null && context.mounted) {
      final now = DateTime.now();
      final isToday = picked.year == now.year &&
          picked.month == now.month &&
          picked.day == now.day;
      unawaited(
        soccerProvider.selectDate(
          isToday ? 'today' : SoccerProvider.formatDateKey(picked),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final soccerProvider = context.watch<SoccerProvider>();
    final channelProvider = context.watch<ChannelProvider>();

    final data = soccerProvider.selectedDateData;
    final isLoading = soccerProvider.isLoadingSelectedDate && data == null;
    final error = soccerProvider.selectedDateError;
    final sections =
        data != null ? _buildSections(data) : const <_LeagueSectionData>[];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Top-right subtle lime radial glow (CSS body)
          Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.darkAccent.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.darkAccent,
              backgroundColor: AppColors.darkBg1,
              onRefresh: soccerProvider.refresh,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            'Fútbol',
                            style: AppFont.primary(
                              color: AppColors.darkText,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Date Selector Bar (Ayer · Hoy · Mañana · Fecha)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _DateSelectorBar(
                        selectedDateKey: soccerProvider.selectedDateKey,
                        onSelectDateKey: (k) {
                          HapticFeedback.selectionClick();
                          unawaited(soccerProvider.selectDate(k));
                        },
                        onPickCustomDate: () =>
                            _openCustomDatePicker(context, soccerProvider),
                      ),
                    ),
                  ),

                  // Body states
                  if (isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: PivoteLoader(size: 36)),
                    )
                  else if (error != null && data == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyStateView(
                        icon: Icons.wifi_off_rounded,
                        title: 'Error de conexión',
                        subtitle: 'No se pudo cargar la jornada futbolística.',
                        actionLabel: 'Reintentar',
                        onAction: soccerProvider.refresh,
                      ),
                    )
                  else if (sections.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyStateView(
                        icon: Icons.sports_soccer_rounded,
                        title: 'Sin partidos para esta fecha',
                        subtitle:
                            'Probá seleccionando otro día en el calendario superior.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList.separated(
                        itemCount: sections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, idx) {
                          final section = sections[idx];
                          return _LeagueGroupCard(
                            league: section.league,
                            matches: section.matches,
                            channelProvider: channelProvider,
                            soccerProvider: soccerProvider,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueSectionData {
  final SoccerLeague league;
  final List<SoccerMatch> matches;

  const _LeagueSectionData({required this.league, required this.matches});
}

class _DateSelectorBar extends StatelessWidget {
  final String selectedDateKey;
  final ValueChanged<String> onSelectDateKey;
  final VoidCallback onPickCustomDate;

  const _DateSelectorBar({
    required this.selectedDateKey,
    required this.onSelectDateKey,
    required this.onPickCustomDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterdayKey =
        SoccerProvider.formatDateKey(now.subtract(const Duration(days: 1)));
    final todayKey = SoccerProvider.formatDateKey(now);
    final tomorrowKey =
        SoccerProvider.formatDateKey(now.add(const Duration(days: 1)));

    final isToday = selectedDateKey == 'today' || selectedDateKey == todayKey;
    final isYesterday = selectedDateKey == yesterdayKey;
    final isTomorrow = selectedDateKey == tomorrowKey;
    final isCustom = !isToday && !isYesterday && !isTomorrow;

    String customLabel = 'Fecha';
    if (isCustom) {
      final parsed = DateTime.tryParse(selectedDateKey);
      if (parsed != null) {
        final d = parsed.day.toString().padLeft(2, '0');
        final m = parsed.month.toString().padLeft(2, '0');
        customLabel = '$d/$m';
      }
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DatePill(
              label: 'Ayer',
              selected: isYesterday,
              onTap: () => onSelectDateKey(yesterdayKey),
            ),
          ),
          Expanded(
            child: _DatePill(
              label: 'Hoy',
              selected: isToday,
              onTap: () => onSelectDateKey('today'),
            ),
          ),
          Expanded(
            child: _DatePill(
              label: 'Mañana',
              selected: isTomorrow,
              onTap: () => onSelectDateKey(tomorrowKey),
            ),
          ),
          Expanded(
            child: _DatePill(
              label: customLabel,
              icon: Icons.calendar_today_rounded,
              selected: isCustom,
              onTap: onPickCustomDate,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _DatePill({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color:
                    selected ? AppColors.onDarkAccent : AppColors.darkText3,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFont.primary(
                  color:
                      selected ? AppColors.onDarkAccent : AppColors.darkText2,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueGroupCard extends StatelessWidget {
  final SoccerLeague league;
  final List<SoccerMatch> matches;
  final ChannelProvider channelProvider;
  final SoccerProvider soccerProvider;

  const _LeagueGroupCard({
    required this.league,
    required this.matches,
    required this.channelProvider,
    required this.soccerProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBg1,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.darkBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // League Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.glass,
              border: Border(
                bottom: BorderSide(color: AppColors.darkBorder),
              ),
            ),
            child: Row(
              children: [
                if ((league.logoUrl ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CachedNetworkImage(
                      imageUrl: league.logoUrl!,
                      cacheManager: ImageCacheHelper.logoCacheManager,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.emoji_events_outlined,
                        color: AppColors.darkText3,
                        size: 18,
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: AppColors.darkText3,
                      size: 18,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name.isNotEmpty ? league.name : 'Torneo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          color: AppColors.darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (league.country.isNotEmpty)
                        Text(
                          league.country,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.primary(
                            color: AppColors.darkText3,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Text(
                    '${matches.length}',
                    style: AppFont.mono(
                      color: AppColors.darkText3,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Match Rows
          for (var i = 0; i < matches.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.darkBorder,
              ),
            _MatchRow(
              match: matches[i],
              resolvedChannels: matches[i].isWatchable
                  ? soccerProvider.resolveChannelsForMatch(
                      matches[i],
                      channelProvider,
                    )
                  : const <Channel>[],
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final SoccerMatch match;
  final List<Channel> resolvedChannels;

  const _MatchRow({
    required this.match,
    required this.resolvedChannels,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;
    final isFinished = match.isFinished;
    final hasScore = !match.isScheduled;
    final canWatch = match.isWatchable && resolvedChannels.isNotEmpty;

    final homeColor = match.homeTeamData.primaryColor;
    final statusLabel = isFinished
        ? (match.matchStatus.shortLabel.isNotEmpty
            ? match.matchStatus.shortLabel.toUpperCase()
            : 'FIN')
        : isLive
            ? (match.time.isNotEmpty
                ? match.time
                : (match.matchStatus.shortLabel.isNotEmpty
                    ? match.matchStatus.shortLabel
                    : 'VIVO'))
            : (match.timeLocalAr.isNotEmpty
                ? match.timeLocalAr
                : match.formattedTime);

    final statusColor = isLive
        ? AppColors.live
        : isFinished
            ? AppColors.darkText3
            : AppColors.darkAccent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            AppAnimations.createRoute(
              MatchDetailScreen(match: match),
            ),
          );
        },
        child: Container(
          decoration: homeColor != null
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      homeColor.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
          child: Row(
            children: [
              // Status / Time column
              SizedBox(
                width: 54,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLive) ...[
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: const BoxDecoration(
                              color: AppColors.live,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFont.mono(
                              color: statusColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (match.stageRound.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          match.stageRound,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.primary(
                            color: AppColors.darkText3,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Teams + Score column
              Expanded(
                child: Column(
                  children: [
                    _TeamScoreLine(
                      name: match.homeTeamData.name.isNotEmpty
                          ? match.homeTeamData.name
                          : match.homeTeam,
                      logoUrl: match.homeTeamData.logoUrl ?? '',
                      score: hasScore ? '${match.homeTeamData.score}' : null,
                      isWinner: isFinished &&
                          hasScore &&
                          match.homeTeamData.score > match.awayTeamData.score,
                    ),
                    const SizedBox(height: 8),
                    _TeamScoreLine(
                      name: match.awayTeamData.name.isNotEmpty
                          ? match.awayTeamData.name
                          : match.awayTeam,
                      logoUrl: match.awayTeamData.logoUrl ?? '',
                      score: hasScore ? '${match.awayTeamData.score}' : null,
                      isWinner: isFinished &&
                          hasScore &&
                          match.awayTeamData.score > match.homeTeamData.score,
                    ),
                  ],
                ),
              ),

              // "Ver" button ONLY when watchable (never on finished matches!)
              if (canWatch) ...[
                const SizedBox(width: 12),
                Material(
                  color: AppColors.darkAccent,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        AppAnimations.createRoute(
                          PlayerScreen(
                            channel: resolvedChannels.first,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(11),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.onDarkAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Ver',
                            style: AppFont.primary(
                              color: AppColors.onDarkAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamScoreLine extends StatelessWidget {
  final String name;
  final String logoUrl;
  final String? score;
  final bool isWinner;

  const _TeamScoreLine({
    required this.name,
    required this.logoUrl,
    this.score,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: logoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: logoUrl,
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: AppColors.darkText3,
                  ),
                )
              : const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppColors.darkText3,
                ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFont.primary(
              color: isWinner ? AppColors.darkText : AppColors.darkText2,
              fontSize: 13.5,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        if (score != null) ...[
          const SizedBox(width: 8),
          Text(
            score!,
            style: AppFont.mono(
              color: isWinner ? AppColors.darkAccent : AppColors.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _CustomCalendarSheet extends StatefulWidget {
  final DateTime initialDate;

  const _CustomCalendarSheet({required this.initialDate});

  @override
  State<_CustomCalendarSheet> createState() => _CustomCalendarSheetState();
}

class _CustomCalendarSheetState extends State<_CustomCalendarSheet> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstWeekdayOffset = _displayedMonth.weekday - 1; // Mon=0 .. Sun=6
    final totalCells = firstWeekdayOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final now = DateTime.now();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.darkBg1,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.darkBorder2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.darkBorder2,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // Month navigation
            Row(
              children: [
                Text(
                  '${_months[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: AppFont.primary(
                    color: AppColors.darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _CalendarNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _prevMonth,
                ),
                const SizedBox(width: 8),
                _CalendarNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weekday headers
            Row(
              children: _weekdays
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: AppFont.mono(
                            color: AppColors.darkText3,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Calendar Grid
            for (var r = 0; r < rows; r++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: List.generate(7, (c) {
                    final cellIndex = r * 7 + c;
                    final dayNum = cellIndex - firstWeekdayOffset + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 40));
                    }

                    final cellDate = DateTime(
                      _displayedMonth.year,
                      _displayedMonth.month,
                      dayNum,
                    );
                    final isSelected = cellDate.year == _selectedDate.year &&
                        cellDate.month == _selectedDate.month &&
                        cellDate.day == _selectedDate.day;
                    final isToday = cellDate.year == now.year &&
                        cellDate.month == now.month &&
                        cellDate.day == now.day;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop(cellDate);
                        },
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.all(2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkAccent
                                : isToday
                                    ? AppColors.glass
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: AppColors.darkAccent
                                        .withValues(alpha: 0.45),
                                  )
                                : null,
                          ),
                          child: Text(
                            '$dayNum',
                            style: AppFont.mono(
                              color: isSelected
                                  ? AppColors.onDarkAccent
                                  : isToday
                                      ? AppColors.darkAccent
                                      : AppColors.darkText,
                              fontSize: 13,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CalendarNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Icon(icon, color: AppColors.darkText, size: 18),
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Icon(icon, color: AppColors.darkText3, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFont.primary(
              color: AppColors.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppFont.primary(
              color: AppColors.darkText3,
              fontSize: 13,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkAccent,
                foregroundColor: AppColors.onDarkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                actionLabel!,
                style: AppFont.primary(
                  color: AppColors.onDarkAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
