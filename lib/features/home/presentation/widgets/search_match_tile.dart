import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/widgets/match_details_bottom_sheet.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

class SearchMatchTile extends StatelessWidget {
  final SoccerMatch match;
  final SoccerData soccerData;

  const SearchMatchTile({
    super.key,
    required this.match,
    required this.soccerData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final homeTeam = soccerData.teams.firstWhere(
      (t) => t.id == match.homeTeamId,
      orElse: () => SoccerTeam(
        id: match.homeTeamId,
        name: match.homeTeam,
        shortName: match.homeTeam,
      ),
    );
    final awayTeam = soccerData.teams.firstWhere(
      (t) => t.id == match.awayTeamId,
      orElse: () => SoccerTeam(
        id: match.awayTeamId,
        name: match.awayTeam,
        shortName: match.awayTeam,
      ),
    );
    final league = soccerData.leagues.firstWhere(
      (l) => l.id == match.leagueId,
      orElse: () => SoccerLeague(
        id: match.leagueId,
        name: 'Fútbol',
        country: '',
        shortName: '',
      ),
    );

    final isLive = match.isLive;
    final isScheduled = match.isScheduled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: MatchDetailsBottomSheet(
                  match: match,
                  homeTeam: homeTeam,
                  awayTeam: awayTeam,
                  league: league,
                ),
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? (isLive
                    ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                    : AppTheme.darkBg2.withValues(alpha: 0.7))
                : (isLive
                    ? const Color(0xFFEF4444).withValues(alpha: 0.05)
                    : theme.colorScheme.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLive
                  ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.06)),
              width: isLive ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // League and Status Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      league.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark
                            ? AppTheme.darkAccent
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            match.time.isNotEmpty ? match.time : 'EN VIVO',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isScheduled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        match.startTime.isNotEmpty
                            ? match.startTime
                            : 'PROGRAMADO',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FINAL',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Teams & Score
              Row(
                children: [
                  // Home Team
                  Expanded(
                    child: Row(
                      children: [
                        _buildTeamBadge(homeTeam),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            homeTeam.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score or VS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: match.score.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${match.score[0]} - ${match.score.length > 1 ? match.score[1] : 0}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          )
                        : Text(
                            'VS',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                  ),

                  // Away Team
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            awayTeam.name,
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildTeamBadge(awayTeam),
                      ],
                    ),
                  ),
                ],
              ),

              // Channels Available Footer
              if (match.tvChannels.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.tv_rounded,
                      size: 13,
                      color: isDark
                          ? AppTheme.darkAccent
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        match.tvChannels.map((c) => c.name).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamBadge(SoccerTeam team) {
    if (team.logoUrl != null && team.logoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        key: ValueKey<String>(team.logoUrl!),
        cacheManager: ImageCacheHelper.logoCacheManager,
        imageUrl: team.logoUrl!,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sports_soccer_rounded, size: 16),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.sports_soccer_rounded, size: 16),
    );
  }
}
