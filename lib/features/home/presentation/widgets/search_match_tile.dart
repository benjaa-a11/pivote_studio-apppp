import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/widgets/match_details_bottom_sheet.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';

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
    final palette = ProfilePalette.of(context);

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

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isLive
              ? AppColors.live.withValues(alpha: 0.45)
              : palette.border,
          width: 1,
        ),
        boxShadow: palette.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
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
                    maxHeight: MediaQuery.of(context).size.height * 0.64,
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
          splashColor: Colors.transparent,
          highlightColor: palette.cardPressed,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_soccer_rounded,
                            size: 14,
                            color: palette.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              league.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFont.primary(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: palette.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.live.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.live.withValues(alpha: 0.35),
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
                                color: AppColors.live,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              match.time.isNotEmpty ? match.time : 'EN VIVO',
                              style: AppFont.primary(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.live,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isScheduled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: palette.iconBox,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: palette.border, width: 1),
                        ),
                        child: Text(
                          match.startTime.isNotEmpty
                              ? match.startTime
                              : 'PROGRAMADO',
                          style: AppFont.primary(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: palette.muted,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: palette.iconBox,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'FINAL',
                          style: AppFont.primary(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: palette.muted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildTeamBadge(homeTeam, palette),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              homeTeam.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFont.primary(
                                fontSize: 13.8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: palette.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: match.score.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: palette.iconBox,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xs),
                                border: Border.all(
                                  color: palette.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${match.score[0]} - ${match.score.length > 1 ? match.score[1] : 0}',
                                style: AppFont.score(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: palette.text,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: palette.iconBox,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xs),
                              ),
                              child: Text(
                                'VS',
                                style: AppFont.primary(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: palette.muted,
                                ),
                              ),
                            ),
                    ),
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
                              style: AppFont.primary(
                                fontSize: 13.8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: palette.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildTeamBadge(awayTeam, palette),
                        ],
                      ),
                    ),
                  ],
                ),
                if (match.tvChannels.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, thickness: 1, color: palette.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.live_tv_rounded,
                        size: 14,
                        color: palette.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          match.tvChannels.map((c) => c.name).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.primary(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.muted,
                          ),
                        ),
                      ),
                      ProfileSvgIcons.svg(
                        ProfileSvgIcons.chevronRight,
                        size: 16,
                        color: palette.chevron,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamBadge(SoccerTeam team, ProfilePalette palette) {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.iconBox,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: (team.logoUrl != null && team.logoUrl!.isNotEmpty)
          ? CachedNetworkImage(
              key: ValueKey<String>(team.logoUrl!),
              cacheManager: ImageCacheHelper.logoCacheManager,
              imageUrl: team.logoUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: Icon(
                  Icons.sports_soccer_rounded,
                  size: 15,
                  color: palette.muted,
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.sports_soccer_rounded,
                size: 16,
                color: palette.muted,
              ),
            )
          : Icon(
              Icons.sports_soccer_rounded,
              size: 16,
              color: palette.muted,
            ),
    );
  }
}
