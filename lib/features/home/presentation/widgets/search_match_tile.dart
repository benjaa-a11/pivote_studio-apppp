import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/screens/match_detail_screen.dart';
import 'package:pivote/shared/widgets/common/loading_shimmer.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class SearchMatchTile extends StatelessWidget {
  final SoccerMatch match;
  final SoccerData soccerData;

  const SearchMatchTile({
    super.key,
    required this.match,
    required this.soccerData,
  });

  Color _effectiveTeamColor(BuildContext context, SoccerTeam team) {
    final c = team.primaryColor;
    if (c == null || c.computeLuminance() < 0.05 || c.computeLuminance() > 0.92) {
      return AppTheme.accent(context);
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
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
    final homeGlow = _effectiveTeamColor(context, homeTeam);
    final awayGlow = _effectiveTeamColor(context, awayTeam);
    final danger = AppTheme.danger(context);

    return PivoteDiffusedCard(
      borderRadius: AppRadius.card,
      glowColor: homeGlow,
      secondaryGlowColor: awayGlow,
      glowAlignment: const Alignment(-0.9, 0.0),
      secondaryGlowAlignment: const Alignment(0.9, 0.0),
      glowOpacity: 1.05,
      highlighted: isLive,
      borderColor: isLive ? danger.withValues(alpha: 0.45) : null,
      padding: const EdgeInsets.all(15),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          AppAnimations.createRoute(MatchDetailScreen(match: match)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_soccer_rounded,
                size: 14,
                color: AppTheme.textTertiary(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  league.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.primary(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                    color: AppTheme.textTertiary(context),
                  ),
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
                    color: AppTheme.dangerDim(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: danger.withValues(alpha: 0.36),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        match.time.isNotEmpty ? match.time : 'EN VIVO',
                        style: AppFont.mono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: danger,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Text(
                    isScheduled
                        ? (match.startTime.isNotEmpty
                            ? match.startTime
                            : 'PRÓXIMO')
                        : 'FINAL',
                    style: AppFont.mono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isScheduled
                          ? AppTheme.accent(context)
                          : AppTheme.textTertiary(context),
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
                    _buildTeamBadge(context, homeTeam),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        homeTeam.shortName.isNotEmpty
                            ? homeTeam.shortName
                            : homeTeam.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppTheme.textPrimary(context),
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
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface2(context),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Text(
                          '${match.score[0]} - ${match.score.length > 1 ? match.score[1] : 0}',
                          style: AppFont.score(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            color: isLive
                                ? AppTheme.accent(context)
                                : AppTheme.textPrimary(context),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface2(context),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          'VS',
                          style: AppFont.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textTertiary(context),
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
                        awayTeam.shortName.isNotEmpty
                            ? awayTeam.shortName
                            : awayTeam.name,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFont.primary(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    _buildTeamBadge(context, awayTeam),
                  ],
                ),
              ),
            ],
          ),
          if (match.tvChannels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: AppTheme.border(context)),
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(
                  Icons.live_tv_rounded,
                  size: 14,
                  color: AppTheme.accent(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    match.tvChannels.map((c) => c.name).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFont.primary(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: AppTheme.textTertiary(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamBadge(BuildContext context, SoccerTeam team) {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: (team.logoUrl != null && team.logoUrl!.isNotEmpty)
          ? CachedNetworkImage(
              key: ValueKey<String>(team.logoUrl!),
              cacheManager: ImageCacheHelper.logoCacheManager,
              imageUrl: team.logoUrl!,
              fit: BoxFit.contain,
              placeholder: (_, __) => const PivoteShimmer(
                child: PivoteShimmerBone(height: 20, isCircle: true),
              ),
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
    );
  }
}
