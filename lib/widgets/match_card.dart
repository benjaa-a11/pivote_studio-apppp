import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/soccer_models.dart';
import '../providers/channel_provider.dart';
import '../screens/player_screen.dart';

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
    final cardWidth = screenWidth * 0.9;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    // Theme-aware colors
    final cardBg = isDark ? const Color(0xFF0D0F14) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF1E2128) : const Color(0xFFE5E7EB);
    final headerBg = isDark ? const Color(0xFF161921) : const Color(0xFFF9FAFB);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final textMuted = isDark ? Colors.white54 : const Color(0xFF9CA3AF);

    return Container(
      width: cardWidth,
      height: 255, // Increased height to prevent team name cutting
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con torneo y fase
          _buildHeader(context, league, tournamentLogoUrl, headerBg,
              textPrimary, textMuted),

          // Línea divisoria
          Container(
            height: 1,
            color: borderColor,
          ),

          // Equipos y hora
          Expanded(
            child: _buildTeamsSection(context, teamA, teamB, primaryColor,
                textPrimary, textSecondary, textMuted),
          ),

          // Línea divisoria
          Container(
            height: 1,
            color: borderColor,
          ),

          // Footer con botón
          _buildFooter(context, primaryColor, isDark, borderColor),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      SoccerLeague league,
      String tournamentLogoUrl,
      Color headerBg,
      Color textPrimary,
      Color textMuted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Logo del torneo
          if (tournamentLogoUrl.isNotEmpty)
            SizedBox(
              width: 44,
              height: 44,
              child: CachedNetworkImage(
                imageUrl: tournamentLogoUrl,
                fit: BoxFit.contain,
                memCacheWidth: 200,
                memCacheHeight: 200,
                maxWidthDiskCache: 200,
                maxHeightDiskCache: 200,
                fadeInDuration: const Duration(milliseconds: 100),
                fadeOutDuration: const Duration(milliseconds: 50),
                placeholder: (context, url) => const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, error, stackTrace) {
                  return FaIcon(
                    FontAwesomeIcons.trophy,
                    size: 24,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  );
                },
              ),
            )
          else
            FaIcon(
              FontAwesomeIcons.trophy,
              size: 28,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),

          const SizedBox(width: 12),

          // Nombre del torneo y fase
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  league.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
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
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                      letterSpacing: 0,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsSection(
      BuildContext context,
      dynamic teamA,
      dynamic teamB,
      Color primaryColor,
      Color textPrimary,
      Color textSecondary,
      Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Equipo A
          Expanded(
            child: _buildTeam(
              context,
              teamA.shortName,
              teamA.logoUrl ?? '',
              textPrimary,
            ),
          ),

          // Centro: Estado y Hora
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCenterInfo(context, primaryColor, textSecondary),
          ),

          // Equipo B
          Expanded(
            child: _buildTeam(
              context,
              teamB.shortName,
              teamB.logoUrl ?? '',
              textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeam(
      BuildContext context, String teamName, String logoUrl, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo del equipo
        SizedBox(
          width: 70,
          height: 70,
          child: logoUrl.isNotEmpty
              ? CachedNetworkImage(
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
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                  errorWidget: (context, error, stackTrace) {
                    return FaIcon(
                      FontAwesomeIcons.shield,
                      size: 36,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4),
                    );
                  },
                )
              : FaIcon(
                  FontAwesomeIcons.shield,
                  size: 40,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                ),
        ),
        const SizedBox(height: 10),

        // Nombre del equipo con altura fija aumentada
        SizedBox(
          height: 38,
          child: Center(
            child: Text(
              teamName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
                letterSpacing: -0.2,
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

  Widget _buildCenterInfo(
      BuildContext context, Color primaryColor, Color textSecondary) {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Estado EN VIVO, FINALIZADO o TIEMPO
        if (isLive)
          _buildLiveIndicator()
        else if (isFinished)
          _buildStatusBadge(
              timeStatus.isEmpty ? 'FINAL' : timeStatus.toUpperCase(),
              Colors.grey)
        else if (timeStatus.toLowerCase().contains('prog') ||
            timeStatus.toLowerCase().contains('aplaz') ||
            timeStatus.toLowerCase().contains('susp'))
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(timeStatus.toUpperCase(), primaryColor),
              const SizedBox(height: 6),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          )
        else ...[
          Text(
            'HOY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLivePulse(),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'EN VIVO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (match.timeStatus.isNotEmpty)
                Text(
                  match.timeStatus,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePulse() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, Color primaryColor, bool isDark,
      Color borderColor) {
    final hasMultipleChannels =
        match.tvChannels.where((c) => c.id != null).length > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SizedBox(
        height: 46,
        child: isLive
            ? _buildLiveButton(
                context, hasMultipleChannels, primaryColor, isDark, borderColor)
            : match.isWatchable
                ? _buildWatchButton(context, hasMultipleChannels, primaryColor,
                    isDark, borderColor)
                : _buildComingSoonButton(isDark, borderColor),
      ),
    );
  }

  Widget _buildLiveButton(BuildContext context, bool hasMultipleChannels,
      Color primaryColor, bool isDark, Color borderColor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onWatchMatch,
            icon: const FaIcon(FontAwesomeIcons.solidCirclePlay, size: 18),
            label: const Text(
              'Ver en vivo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        if (hasMultipleChannels) ...[
          const SizedBox(width: 10),
          _buildOptionsButton(context, isDark, borderColor),
        ],
      ],
    );
  }

  Widget _buildWatchButton(BuildContext context, bool hasMultipleChannels,
      Color primaryColor, bool isDark, Color borderColor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onWatchMatch,
            icon: const FaIcon(FontAwesomeIcons.circlePlay, size: 18),
            label: const Text(
              'Ver partido',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        if (hasMultipleChannels) ...[
          const SizedBox(width: 10),
          _buildOptionsButton(context, isDark, borderColor),
        ],
      ],
    );
  }

  Widget _buildOptionsButton(
      BuildContext context, bool isDark, Color borderColor) {
    final iconColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final buttonBg = isDark ? const Color(0xFF1E2128) : const Color(0xFFF3F4F6);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: buttonBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: () => _showChannelOptions(context),
        icon: FaIcon(
          FontAwesomeIcons.ellipsis,
          color: iconColor,
          size: 22,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildComingSoonButton(bool isDark, Color borderColor) {
    final textColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);
    final buttonBg = isDark ? const Color(0xFF1E2128) : const Color(0xFFF3F4F6);

    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: buttonBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.clock,
            size: 18,
            color: textColor,
          ),
          const SizedBox(width: 10),
          Text(
            'Próximamente',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? const Color(0xFF0D0F14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final itemBg = isDark ? const Color(0xFF1E2128) : const Color(0xFFF9FAFB);

    showModalBottomSheet(
      context: context,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Selecciona un canal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...match.tvChannels.map((soccerChannel) {
              if (soccerChannel.id == null) return const SizedBox.shrink();
              final channel = channelProvider.getChannelById(soccerChannel.id!);

              if (channel == null) return const SizedBox.shrink();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 6,
                ),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: channel.logoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: channel.logoUrl.first,
                          fit: BoxFit.contain,
                          memCacheWidth: 150,
                          memCacheHeight: 150,
                          fadeInDuration: const Duration(milliseconds: 100),
                          fadeOutDuration: const Duration(milliseconds: 50),
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                          errorWidget: (context, error, stackTrace) {
                            return Icon(
                              Icons.live_tv_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 26,
                            );
                          },
                        )
                      : Icon(
                          Icons.live_tv_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 26,
                        ),
                ),
                title: Text(
                  channel.name,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                trailing: FaIcon(
                  FontAwesomeIcons.chevronRight,
                  color: textSecondary,
                  size: 14,
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
            })
          ],
        ),
      ),
    );
  }
}
