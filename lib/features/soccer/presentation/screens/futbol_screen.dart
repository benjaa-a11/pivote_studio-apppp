import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/screens/match_detail_screen.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/app_state_views.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

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
    final picked = await AppDialogs.showModal<DateTime>(
      context: context,
      child: _CustomCalendarSheet(initialDate: initial),
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
    final hPad = AppResponsive.screenHorizontalPadding(context);

    final data = soccerProvider.selectedDateData;
    final isLoading = soccerProvider.isLoadingSelectedDate && data == null;
    final error = soccerProvider.selectedDateError;
    final sections =
        data != null ? _buildSections(data) : const <_LeagueSectionData>[];
    final liveCount = data?.matches.where((m) => m.isLive).length ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Header principal unificado
              SliverToBoxAdapter(
                child: Padding(
                  padding: hPad.add(const EdgeInsets.only(top: 14, bottom: 14)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fútbol',
                              style: AppFont.primary(
                                color: AppTheme.textPrimary(context),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              liveCount > 0
                                  ? '$liveCount ${liveCount == 1 ? 'partido en vivo' : 'partidos en vivo'}'
                                  : 'Agenda deportiva diaria',
                              style: AppFont.primary(
                                color: liveCount > 0
                                    ? AppTheme.danger(context)
                                    : AppTheme.textTertiary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PivoteIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Actualizar jornada',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          unawaited(soccerProvider.refresh());
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Selector de fecha moderno (Ayer · Hoy · Mañana · Fecha)
              SliverToBoxAdapter(
                child: Padding(
                  padding: hPad.add(const EdgeInsets.only(bottom: 16)),
                  child: _DateSelectorBar(
                    selectedDateKey: soccerProvider.selectedDateKey,
                    onSelectDateKey: (k) {
                      unawaited(soccerProvider.selectDate(k));
                    },
                    onPickCustomDate: () =>
                        _openCustomDatePicker(context, soccerProvider),
                  ),
                ),
              ),

              // Estados de contenido: Skeleton + Shimmer / Error / Vacío / Ligas
              if (isLoading)
                const PivoteFutbolSkeleton(leagueCount: 3)
              else if (error != null && data == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppStateView.error(
                    icon: Icons.wifi_off_rounded,
                    title: 'Error de conexión',
                    subtitle: 'No se pudo cargar la jornada futbolística.',
                    actionLabel: 'Reintentar',
                    onAction: () => unawaited(soccerProvider.refresh()),
                  ),
                )
              else if (sections.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppStateView.empty(
                    icon: Icons.sports_soccer_rounded,
                    title: 'Sin partidos para esta fecha',
                    subtitle:
                        'Probá seleccionando otro día en el calendario superior.',
                  ),
                )
              else
                SliverPadding(
                  padding: hPad.add(const EdgeInsets.only(bottom: 120)),
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

    final selectedIndex = isYesterday
        ? 0
        : isToday
            ? 1
            : isTomorrow
                ? 2
                : 3;

    return PivoteSegmentedBar(
      selectedIndex: selectedIndex,
      items: [
        const PivoteSegmentItem(label: 'Ayer'),
        const PivoteSegmentItem(label: 'Hoy'),
        const PivoteSegmentItem(label: 'Mañana'),
        PivoteSegmentItem(
          label: customLabel,
          icon: Icons.calendar_today_rounded,
        ),
      ],
      onChanged: (idx) {
        if (idx == 0) {
          onSelectDateKey(yesterdayKey);
        } else if (idx == 1) {
          onSelectDateKey('today');
        } else if (idx == 2) {
          onSelectDateKey(tomorrowKey);
        } else {
          onPickCustomDate();
        }
      },
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
    final hasLive = matches.any((m) => m.isLive);

    return PivoteDiffusedCard(
      borderRadius: AppRadius.lg,
      glowColor: hasLive ? AppTheme.danger(context) : AppTheme.accent(context),
      glowAlignment: const Alignment(-0.85, -0.9),
      glowOpacity: hasLive ? 1.15 : 0.65,
      highlighted: hasLive,
      child: Column(
        children: [
          // Cabecera de liga
          Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.border(context)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2(context),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: (league.logoUrl ?? '').isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: league.logoUrl!,
                          cacheManager: ImageCacheHelper.logoCacheManager,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.emoji_events_outlined,
                            color: AppTheme.textTertiary(context),
                            size: 16,
                          ),
                        )
                      : Icon(
                          Icons.emoji_events_outlined,
                          color: AppTheme.textTertiary(context),
                          size: 16,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name.isNotEmpty ? league.name : 'Torneo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          color: AppTheme.textPrimary(context),
                          fontSize: 14.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (league.country.isNotEmpty)
                        Text(
                          league.country,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.primary(
                            color: AppTheme.textTertiary(context),
                            fontSize: 11.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasLive
                        ? AppTheme.dangerDim(context)
                        : AppTheme.surface2(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: hasLive
                          ? AppTheme.danger(context).withValues(alpha: 0.34)
                          : AppTheme.border(context),
                    ),
                  ),
                  child: Text(
                    '${matches.length}',
                    style: AppFont.mono(
                      color: hasLive
                          ? AppTheme.danger(context)
                          : AppTheme.textTertiary(context),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filas de partidos
          for (var i = 0; i < matches.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.border(context),
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
    final isDark = AppTheme.isDark(context);
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
        ? AppTheme.danger(context)
        : isFinished
            ? AppTheme.textTertiary(context)
            : AppTheme.accent(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            AppAnimations.createRoute(MatchDetailScreen(match: match)),
          );
        },
        child: Container(
          decoration: homeColor != null
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      homeColor.withValues(alpha: isDark ? 0.08 : 0.05),
                      Colors.transparent,
                    ],
                  ),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
          child: Row(
            children: [
              // Columna de estado / horario
              SizedBox(
                width: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLive)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.danger(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFont.mono(
                              color: statusColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
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
                            color: AppTheme.textTertiary(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Equipos + marcador
              Expanded(
                child: Column(
                  children: [
                    _TeamScoreLine(
                      name: match.homeTeamData.name.isNotEmpty
                          ? match.homeTeamData.name
                          : match.homeTeam,
                      logoUrl: match.homeTeamData.logoUrl ?? '',
                      score: hasScore ? '${match.homeTeamData.score}' : null,
                      isLive: isLive,
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
                      isLive: isLive,
                      isWinner: isFinished &&
                          hasScore &&
                          match.awayTeamData.score > match.homeTeamData.score,
                    ),
                  ],
                ),
              ),

              // Botón "Ver" únicamente cuando hay señal disponible
              if (canWatch) ...[
                const SizedBox(width: 12),
                ApplePressable(
                  scaleDownFactor: 0.94,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      AppAnimations.createRoute(
                        PlayerScreen(channel: resolvedChannels.first),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: isLive
                          ? AppTheme.danger(context)
                          : AppTheme.accent(context),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: isLive
                              ? Colors.white
                              : AppTheme.onAccent(context),
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Ver',
                          style: AppFont.primary(
                            color: isLive
                                ? Colors.white
                                : AppTheme.onAccent(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
  final bool isLive;

  const _TeamScoreLine({
    required this.name,
    required this.logoUrl,
    this.score,
    this.isWinner = false,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 21,
          height: 21,
          child: logoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: logoUrl,
                  cacheManager: ImageCacheHelper.logoCacheManager,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: AppTheme.textTertiary(context),
                  ),
                )
              : Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppTheme.textTertiary(context),
                ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFont.primary(
              color: isWinner || isLive
                  ? AppTheme.textPrimary(context)
                  : AppTheme.textSecondary(context),
              fontSize: 13.5,
              fontWeight: isWinner || isLive ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        if (score != null) ...[
          const SizedBox(width: 8),
          Text(
            score!,
            style: AppFont.mono(
              color: isWinner || isLive
                  ? AppTheme.accent(context)
                  : AppTheme.textPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w800,
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
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstWeekdayOffset = _displayedMonth.weekday - 1;
    final totalCells = firstWeekdayOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final now = DateTime.now();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PivoteSheetHeader(
              title:
                  '${_months[_displayedMonth.month - 1]} ${_displayedMonth.year}',
              subtitle: 'Elegí un día para ver la jornada',
              icon: Icons.calendar_month_rounded,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PivoteIconButton(
                    size: 36,
                    iconSize: 18,
                    icon: Icons.chevron_left_rounded,
                    onTap: _prevMonth,
                  ),
                  const SizedBox(width: 8),
                  PivoteIconButton(
                    size: 36,
                    iconSize: 18,
                    icon: Icons.chevron_right_rounded,
                    onTap: _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Cabeceras de día
            Row(
              children: _weekdays
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: AppFont.mono(
                            color: AppTheme.textTertiary(context),
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

            // Grilla de días
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
                                ? accent
                                : isToday
                                    ? AppTheme.accentDim(context)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: accent.withValues(alpha: 0.45),
                                  )
                                : null,
                          ),
                          child: Text(
                            '$dayNum',
                            style: AppFont.mono(
                              color: isSelected
                                  ? onAccent
                                  : isToday
                                      ? accent
                                      : AppTheme.textPrimary(context),
                              fontSize: 13,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w800
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
