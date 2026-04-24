import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class MatchCard extends StatelessWidget {
  final SoccerMatch match;
  final SoccerData? soccerData;
  final VoidCallback onWatchMatch;

  const MatchCard({
    super.key,
    required this.match,
    this.soccerData,
    required this.onWatchMatch,
  });

  bool get isLive => match.isLive;

  @override
  Widget build(BuildContext context) {
    if (soccerData == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.88;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final teamA = soccerData!.teams.firstWhere(
      (t) => t.id == match.homeTeamId,
      orElse: () => SoccerTeam(
          id: match.homeTeamId,
          name: match.homeTeam,
          shortName: match.homeTeam),
    );
    final teamB = soccerData!.teams.firstWhere(
      (t) => t.id == match.awayTeamId,
      orElse: () => SoccerTeam(
          id: match.awayTeamId,
          name: match.awayTeam,
          shortName: match.awayTeam),
    );
    final league = soccerData!.leagues.firstWhere(
      (t) => t.id == match.leagueId,
      orElse: () => SoccerLeague(
          id: match.leagueId, name: 'Liga', country: '', shortName: 'L'),
    );
    final tournamentLogoUrl = league.logoUrl ?? '';

    return Container(
      width: cardWidth,
      height: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withValues(alpha: 0.5)
              : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? theme.colorScheme.error
                    .withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: isLive ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with league info
          _buildHeader(context, league, tournamentLogoUrl, theme, isDark),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark
                      ? AppTheme.darkBorder.withValues(alpha: 0.3)
                      : AppTheme.lightBorder.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Teams section
          Expanded(
            child: _buildTeamsSection(context, teamA, teamB, theme, isDark),
          ),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark
                      ? AppTheme.darkBorder.withValues(alpha: 0.3)
                      : AppTheme.lightBorder.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Footer
          _buildFooter(context, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SoccerLeague league,
      String tournamentLogoUrl, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Tournament logo
          if (tournamentLogoUrl.isNotEmpty)
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: CachedNetworkImage(
                cacheManager: ImageCacheHelper.customCacheManager,
                imageUrl: tournamentLogoUrl,
                fit: BoxFit.contain,
                memCacheWidth: 200,
                memCacheHeight: 200,
                maxWidthDiskCache: 200,
                maxHeightDiskCache: 200,
                fadeInDuration: const Duration(milliseconds: 100),
                fadeOutDuration: const Duration(milliseconds: 50),
                placeholder: (context, url) => const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: PivoteLoader(
                        strokeWidth: 2,
                        color: Colors.white24,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, error, stackTrace) {
                  return FaIcon(
                    FontAwesomeIcons.trophy,
                    size: 20,
                    color: Colors.amber.withValues(alpha: 0.6),
                  );
                },
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FaIcon(
                FontAwesomeIcons.trophy,
                size: 18,
                color: Colors.amber.withValues(alpha: 0.6),
              ),
            ),

          const SizedBox(width: 12),

          // League name & stage
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  league.name,
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (match.stage.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    match.stage,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Live indicator
          if (isLive) _HeroLiveIndicator(theme: theme),
        ],
      ),
    );
  }

  Widget _buildTeamsSection(BuildContext context, dynamic teamA, dynamic teamB,
      ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Team A
          Expanded(
            child: _buildTeam(
                context, teamA.shortName, teamA.logoUrl ?? '', theme, isDark),
          ),

          // Center: Score or Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildCenterInfo(context, theme, isDark),
          ),

          // Team B
          Expanded(
            child: _buildTeam(
                context, teamB.shortName, teamB.logoUrl ?? '', theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTeam(BuildContext context, String teamName, String logoUrl,
      ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Team logo — clean, no background
        SizedBox(
          width: 68,
          height: 68,
          child: logoUrl.isNotEmpty
              ? CachedNetworkImage(
                  cacheManager: ImageCacheHelper.customCacheManager,
                  imageUrl: logoUrl,
                  fit: BoxFit.contain,
                  memCacheWidth: 200,
                  memCacheHeight: 200,
                  maxWidthDiskCache: 200,
                  maxHeightDiskCache: 200,
                  fadeInDuration: const Duration(milliseconds: 100),
                  fadeOutDuration: const Duration(milliseconds: 50),
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: PivoteLoader(
                        strokeWidth: 2,
                        color: Colors.white24,
                        size: 20,
                      ),
                    ),
                  ),
                  errorWidget: (context, error, stackTrace) {
                    return FaIcon(
                      FontAwesomeIcons.shield,
                      size: 28,
                      color: theme.hintColor.withValues(alpha: 0.3),
                    );
                  },
                )
              : FaIcon(
                  FontAwesomeIcons.shield,
                  size: 32,
                  color: theme.hintColor.withValues(alpha: 0.3),
                ),
        ),
        const SizedBox(height: 8),

        // Team name
        SizedBox(
          height: 34,
          child: Center(
            child: Text(
              teamName,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterInfo(BuildContext context, ThemeData theme, bool isDark) {
    String timeText = '';
    try {
      final parts = match.startTime.split(' ');
      if (parts.length > 1) {
        timeText = parts[1];
      } else {
        timeText = match.startTime;
      }
    } catch (e) {
      timeText = match.startTime;
    }

    final isFinished = match.isFinished;
    final timeStatus = match.timeStatus;

    // Show score if live or finished
    if ((isLive || isFinished) && match.score.isNotEmpty) {
      return _buildScoreDisplay(theme, isDark, isFinished);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (timeStatus.toLowerCase().contains('prog') ||
            timeStatus.toLowerCase().contains('aplaz') ||
            timeStatus.toLowerCase().contains('susp'))
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                ),
                child: Text(
                  timeStatus.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timeText,
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          )
        else ...[
          Text(
            'HOY',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.hintColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            timeText,
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreDisplay(ThemeData theme, bool isDark, bool isFinished) {
    final homeScore = match.score.isNotEmpty ? match.score[0].toString() : '0';
    final awayScore = match.score.length > 1 ? match.score[1].toString() : '0';

    final scoreColor =
        isLive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status label
        if (isLive)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              match.timeStatus.isNotEmpty ? match.timeStatus : 'EN VIVO',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.error,
                letterSpacing: 0.3,
              ),
            ),
          )
        else if (isFinished)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'FINAL',
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: theme.hintColor.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),

        // Score
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              homeScore,
              style: GoogleFonts.syne(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: scoreColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: GoogleFonts.syne(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: scoreColor.withValues(alpha: 0.4),
                ),
              ),
            ),
            Text(
              awayScore,
              style: GoogleFonts.syne(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: scoreColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme, bool isDark) {
    final hasMultipleChannels =
        match.tvChannels.where((c) => c.id != null).length > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: SizedBox(
        height: 44,
        child: isLive
            ? _buildLiveButton(context, hasMultipleChannels, theme, isDark)
            : match.isWatchable
                ? _buildWatchButton(context, hasMultipleChannels, theme, isDark)
                : _buildComingSoonButton(context, theme, isDark),
      ),
    );
  }

  Widget _buildLiveButton(BuildContext context, bool hasMultipleChannels,
      ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onWatchMatch,
            icon: const FaIcon(FontAwesomeIcons.solidCirclePlay, size: 16),
            label: Text(
              'Ver en vivo',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ),
        if (hasMultipleChannels) ...[
          const SizedBox(width: 8),
          _buildOptionsButton(context, theme, isDark),
        ],
      ],
    );
  }

  Widget _buildWatchButton(BuildContext context, bool hasMultipleChannels,
      ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onWatchMatch,
            icon: const FaIcon(FontAwesomeIcons.circlePlay, size: 16),
            label: Text(
              'Ver partido',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ),
        if (hasMultipleChannels) ...[
          const SizedBox(width: 8),
          _buildOptionsButton(context, theme, isDark),
        ],
      ],
    );
  }

  Widget _buildOptionsButton(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg3 : AppTheme.lightBg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withValues(alpha: 0.5)
              : AppTheme.lightBorder,
        ),
      ),
      child: IconButton(
        onPressed: () => _showChannelOptions(context),
        icon: FaIcon(
          FontAwesomeIcons.ellipsis,
          color: theme.hintColor,
          size: 18,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildComingSoonButton(
      BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg3 : AppTheme.lightBg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withValues(alpha: 0.3)
              : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.clock,
            size: 14,
            color: theme.hintColor.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Text(
            'Próximamente',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.hintColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showChannelOptions(BuildContext context) {
    final channelProvider = Provider.of<ChannelProvider>(
      context,
      listen: false,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.hintColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Selecciona un canal',
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${match.homeTeam} vs ${match.awayTeam}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: isDark
                  ? AppTheme.darkBorder.withValues(alpha: 0.3)
                  : AppTheme.lightBorder.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            ...match.tvChannels.map((soccerChannel) {
              if (soccerChannel.id == null) return const SizedBox.shrink();
              final channel = channelProvider.getChannelById(soccerChannel.id!);

              if (channel == null) return const SizedBox.shrink();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBg3 : AppTheme.lightBg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder.withValues(alpha: 0.3)
                          : AppTheme.lightBorder,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: channel.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          cacheManager: ImageCacheHelper.customCacheManager,
                          imageUrl: channel.logoUrl.first,
                          fit: BoxFit.contain,
                          memCacheWidth: 150,
                          memCacheHeight: 150,
                          fadeInDuration: const Duration(milliseconds: 100),
                          fadeOutDuration: const Duration(milliseconds: 50),
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: PivoteLoader(
                                strokeWidth: 2,
                                color: Colors.white24,
                                size: 16,
                              ),
                            ),
                          ),
                          errorWidget: (context, error, stackTrace) {
                            return Icon(
                              Icons.live_tv_rounded,
                              color: theme.colorScheme.primary,
                              size: 22,
                            );
                          },
                        )
                      : Icon(
                          Icons.live_tv_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                ),
                title: Text(
                  channel.name,
                  style: GoogleFonts.dmSans(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(channel: channel),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Animated live indicator for hero cards
class _HeroLiveIndicator extends StatefulWidget {
  final ThemeData theme;

  const _HeroLiveIndicator({required this.theme});

  @override
  State<_HeroLiveIndicator> createState() => _HeroLiveIndicatorState();
}

class _HeroLiveIndicatorState extends State<_HeroLiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.theme.colorScheme.error.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.theme.colorScheme.error
                    .withValues(alpha: _pulseAnimation.value * 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.error
                      .withValues(alpha: _pulseAnimation.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.colorScheme.error
                          .withValues(alpha: _pulseAnimation.value * 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'EN VIVO',
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: widget.theme.colorScheme.error,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
