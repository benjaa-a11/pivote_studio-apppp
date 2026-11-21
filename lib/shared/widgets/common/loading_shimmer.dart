import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';

/// Envoltorio Shimmer unificado del Design System de Pivote.
///
/// Usa exclusivamente los tokens neutros del tema activo (Obsidiana en Oscuro /
/// Porcelana en Claro) para un efecto de brillo profesional y sutil.
class PivoteShimmer extends StatelessWidget {
  final Widget child;
  final Duration period;

  const PivoteShimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1350),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
      highlightColor: isDark ? AppColors.darkBg3 : AppColors.lightBg1,
      period: period,
      child: child,
    );
  }
}

/// Bloque óseo individual para armar esqueletos modernos con shimmer.
class PivoteShimmerBone extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const PivoteShimmerBone({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.xs,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      width: isCircle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Bloque rectangular con shimmer (compatibilidad con llamadas existentes).
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    return PivoteShimmer(
      child: PivoteShimmerBone(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Grilla shimmer compatible con llamadas existentes.
class LoadingShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const LoadingShimmerList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppResponsive.screenHorizontalPadding(context)
          .add(const EdgeInsets.symmetric(vertical: 16)),
      physics: const ClampingScrollPhysics(),
      gridDelegate: AppResponsive.channelGridDelegate(context),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _ChannelCardSkeleton(),
    );
  }
}

/// Esqueleto fiel de `ChannelCard` (escenario del logo + divisor + título/categoría).
class _ChannelCardSkeleton extends StatelessWidget {
  const _ChannelCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1(context),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: PivoteShimmer(
        child: Column(
          children: [
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Center(
                  child: PivoteShimmerBone(
                    width: 68,
                    height: 36,
                    borderRadius: AppRadius.sm,
                  ),
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppTheme.border(context)),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PivoteShimmerBone(width: 96, height: 13, borderRadius: 6),
                  SizedBox(height: 6),
                  PivoteShimmerBone(width: 58, height: 10, borderRadius: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SliverGrid skeleton para la pantalla de Inicio (Canales en vivo).
class PivoteChannelGridSkeleton extends StatelessWidget {
  final int itemCount;

  const PivoteChannelGridSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: AppResponsive.channelGridDelegate(
        context,
        aspectRatio: 1.12,
        spacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => const _ChannelCardSkeleton(),
        childCount: itemCount,
      ),
    );
  }
}

/// Skeleton horizontal fiel al `MatchesHero` mientras cargan los partidos.
class PivoteMatchesHeroSkeleton extends StatelessWidget {
  const PivoteMatchesHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardWidth = AppResponsive.heroCardWidth(context);
    final hPad = AppResponsive.screenHorizontalPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: hPad,
          child: const PivoteShimmer(
            child: Row(
              children: [
                PivoteShimmerBone(width: 4, height: 18, borderRadius: 4),
                SizedBox(width: 10),
                PivoteShimmerBone(width: 148, height: 18, borderRadius: 6),
                Spacer(),
                PivoteShimmerBone(
                  width: 72,
                  height: 26,
                  borderRadius: AppRadius.pill,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: hPad,
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Container(
              width: cardWidth,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: AppTheme.surface1(context),
                borderRadius: BorderRadius.circular(AppRadius.hero),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: const PivoteShimmer(
                child: Column(
                  children: [
                    Row(
                      children: [
                        PivoteShimmerBone(
                          width: 20,
                          height: 20,
                          borderRadius: 6,
                        ),
                        SizedBox(width: 8),
                        PivoteShimmerBone(
                          width: 132,
                          height: 12,
                          borderRadius: 6,
                        ),
                        Spacer(),
                        PivoteShimmerBone(
                          width: 58,
                          height: 22,
                          borderRadius: AppRadius.pill,
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            PivoteShimmerBone(height: 50, isCircle: true),
                            SizedBox(height: 8),
                            PivoteShimmerBone(
                              width: 64,
                              height: 12,
                              borderRadius: 6,
                            ),
                          ],
                        ),
                        PivoteShimmerBone(
                          width: 68,
                          height: 36,
                          borderRadius: 10,
                        ),
                        Column(
                          children: [
                            PivoteShimmerBone(height: 50, isCircle: true),
                            SizedBox(height: 8),
                            PivoteShimmerBone(
                              width: 64,
                              height: 12,
                              borderRadius: 6,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Spacer(),
                    PivoteShimmerBone(
                      width: double.infinity,
                      height: 38,
                      borderRadius: AppRadius.sm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

/// Skeleton fiel a las tarjetas de ligas y filas de partidos en `FutbolScreen`.
class PivoteFutbolSkeleton extends StatelessWidget {
  final int leagueCount;

  const PivoteFutbolSkeleton({super.key, this.leagueCount = 3});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      sliver: SliverList.separated(
        itemCount: leagueCount,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, idx) {
          final rows = idx == 0 ? 3 : 2;
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surface1(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: PivoteShimmer(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        const PivoteShimmerBone(
                          width: 24,
                          height: 24,
                          borderRadius: 7,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PivoteShimmerBone(
                                width: idx == 0 ? 150 : 120,
                                height: 13,
                                borderRadius: 6,
                              ),
                              const SizedBox(height: 5),
                              const PivoteShimmerBone(
                                width: 78,
                                height: 10,
                                borderRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const PivoteShimmerBone(
                          width: 28,
                          height: 22,
                          borderRadius: 7,
                        ),
                      ],
                    ),
                  ),
                  for (int r = 0; r < rows; r++) ...[
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.border(context),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: [
                          PivoteShimmerBone(
                            width: 44,
                            height: 14,
                            borderRadius: 6,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    PivoteShimmerBone(
                                      height: 20,
                                      isCircle: true,
                                    ),
                                    SizedBox(width: 10),
                                    PivoteShimmerBone(
                                      width: 118,
                                      height: 12,
                                      borderRadius: 6,
                                    ),
                                    Spacer(),
                                    PivoteShimmerBone(
                                      width: 18,
                                      height: 14,
                                      borderRadius: 5,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    PivoteShimmerBone(
                                      height: 20,
                                      isCircle: true,
                                    ),
                                    SizedBox(width: 10),
                                    PivoteShimmerBone(
                                      width: 96,
                                      height: 12,
                                      borderRadius: 6,
                                    ),
                                    Spacer(),
                                    PivoteShimmerBone(
                                      width: 18,
                                      height: 14,
                                      borderRadius: 5,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton para el cuerpo de pestañas en `MatchDetailScreen`.
class PivoteMatchDetailSkeleton extends StatelessWidget {
  const PivoteMatchDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface1(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: PivoteShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PivoteShimmerBone(width: 156, height: 14, borderRadius: 6),
            const SizedBox(height: 16),
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              Row(
                children: [
                  const PivoteShimmerBone(width: 34, height: 14, borderRadius: 6),
                  const SizedBox(width: 12),
                  const PivoteShimmerBone(height: 20, isCircle: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PivoteShimmerBone(
                          width: i.isEven ? 140 : 112,
                          height: 13,
                          borderRadius: 6,
                        ),
                        const SizedBox(height: 5),
                        const PivoteShimmerBone(
                          width: 82,
                          height: 10,
                          borderRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  const PivoteShimmerBone(width: 36, height: 22, borderRadius: 7),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton fiel a `SearchRadioTile` para `RadiosScreen`.
class PivoteRadioListSkeleton extends StatelessWidget {
  final int itemCount;

  const PivoteRadioListSkeleton({super.key, this.itemCount = 7});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface1(context),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: PivoteShimmer(
            child: Row(
              children: [
                const PivoteShimmerBone(
                  width: 48,
                  height: 48,
                  borderRadius: AppRadius.sm,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PivoteShimmerBone(
                        width: index.isEven ? 142 : 118,
                        height: 14,
                        borderRadius: 6,
                      ),
                      const SizedBox(height: 7),
                      const PivoteShimmerBone(
                        width: 96,
                        height: 11,
                        borderRadius: 5,
                      ),
                    ],
                  ),
                ),
                const PivoteShimmerBone(height: 22, isCircle: true),
                const SizedBox(width: 12),
                const PivoteShimmerBone(
                  width: 38,
                  height: 38,
                  borderRadius: AppRadius.sm,
                ),
              ],
            ),
          ),
        ),
        childCount: itemCount,
      ),
    );
  }
}

/// Skeleton fiel a las filas de canales en `HistoryScreen`.
class PivoteHistorySkeleton extends StatelessWidget {
  final int itemCount;

  const PivoteHistorySkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface1(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: PivoteShimmer(
        child: Column(
          children: [
            for (int i = 0; i < itemCount; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: AppTheme.border(context)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const PivoteShimmerBone(
                      width: 42,
                      height: 42,
                      borderRadius: AppRadius.sm,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PivoteShimmerBone(
                            width: i.isEven ? 136 : 108,
                            height: 14,
                            borderRadius: 6,
                          ),
                          const SizedBox(height: 6),
                          const PivoteShimmerBone(
                            width: 78,
                            height: 11,
                            borderRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const PivoteShimmerBone(height: 20, isCircle: true),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton para la guía EPG en `PlayerScreen`.
class PivoteProgramGuideSkeleton extends StatelessWidget {
  const PivoteProgramGuideSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface1(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: const PivoteShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PivoteShimmerBone(
                  width: 64,
                  height: 20,
                  borderRadius: AppRadius.pill,
                ),
                SizedBox(width: 10),
                PivoteShimmerBone(width: 112, height: 13, borderRadius: 6),
              ],
            ),
            SizedBox(height: 12),
            PivoteShimmerBone(width: 210, height: 15, borderRadius: 6),
            SizedBox(height: 8),
            PivoteShimmerBone(
              width: double.infinity,
              height: 6,
              borderRadius: AppRadius.pill,
            ),
          ],
        ),
      ),
    );
  }
}
