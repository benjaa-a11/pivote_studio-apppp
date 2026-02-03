import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/match.dart';
import '../providers/match_provider.dart';
import '../providers/channel_provider.dart';
import '../screens/player_screen.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onWatchMatch;

  const MatchCard({
    super.key,
    required this.match,
    required this.onWatchMatch,
  });

  bool get isLive {
    final now = DateTime.now();
    final endTime = match.startTime.add(const Duration(hours: 2, minutes: 30));
    return now.isAfter(match.startTime) && now.isBefore(endTime);
  }

  @override
  Widget build(BuildContext context) {
    final matchProvider = Provider.of<MatchProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final teamA = matchProvider.getTeamById(match.teamAId);
    final teamB = matchProvider.getTeamById(match.teamBId);
    final tournament = matchProvider.getTournamentById(match.tournamentId);
    final tournamentLogoUrl =
        matchProvider.getTournamentLogoUrl(match.tournamentId, true);

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
          _buildHeader(context, tournament, tournamentLogoUrl, headerBg,
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
      dynamic tournament,
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
                  tournament?.name ?? 'Liga Profesional Argentina',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (match.date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    match.date,
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
              teamA?.name ?? 'Equipo A',
              teamA?.logoUrl ?? '',
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
              teamB?.name ?? 'Equipo B',
              teamB?.logoUrl ?? '',
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
        logoUrl.isNotEmpty
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
                    size: 44,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  );
                },
              )
            : FaIcon(
                FontAwesomeIcons.shield,
                size: 44,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.4),
              ),

        const SizedBox(height: 10),

        // Nombre del equipo con altura fija aumentada
        SizedBox(
          height: 38,
          child: Center(
            child: Text(
              teamName,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w900,
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
    final timeFormat = DateFormat('HH:mm');
    final timeText = timeFormat.format(match.startTime);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Estado EN VIVO o HOY
        if (isLive)
          Container(
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
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'EN VIVO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
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

  Widget _buildFooter(BuildContext context, Color primaryColor, bool isDark,
      Color borderColor) {
    final hasMultipleChannels = match.channelIds.length > 1;

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
            ...match.channelIds.map((channelId) {
              final channel = channelProvider.getChannelById(channelId);

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
