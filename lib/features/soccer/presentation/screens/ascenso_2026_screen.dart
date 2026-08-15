import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/features/soccer/data/services/ascenso_2026_service.dart';
import 'package:pivote/shared/widgets/common/pivote_app_bar.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class Ascenso2026Screen extends StatefulWidget {
  const Ascenso2026Screen({super.key});

  @override
  State<Ascenso2026Screen> createState() => _Ascenso2026ScreenState();
}

class _Ascenso2026ScreenState extends State<Ascenso2026Screen> {
  Ascenso2026Snapshot? _snapshot;
  String? _error;
  bool _loading = true;
  int _tab = 0;
  DateTime? _lastUpdated;
  Timer? _timer;

  static const _logoUrl =
      'https://firebasestorage.googleapis.com/v0/b/copafacil-web.appspot.com/o/evts%2F-ncnoo5vqvuwobcpml2n%2F1693084870250.png?alt=media';

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_loading) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await Ascenso2026Service.fetch();
      if (!mounted) return;
      setState(() {
        _snapshot = result;
        _lastUpdated = DateTime.now();
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PivoteAppBar(
        title: 'Ascenso 2026',
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : () => _load(),
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _load,
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Hero(snapshot: _snapshot, theme: theme, isDark: isDark)),
            if (_error != null && _snapshot == null)
              SliverFillRemaining(hasScrollBody: false, child: _ErrorState(error: _error!, onRetry: _load)),
            if (_snapshot != null) ...[
              SliverToBoxAdapter(child: _LiveStatus(snapshot: _snapshot!, lastUpdated: _lastUpdated, theme: theme)),
              SliverToBoxAdapter(child: _buildTabs(theme)),
              if (_tab == 0) ...[
                if (_snapshot!.matches.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _EmptyState(theme: theme, label: 'No hay resultados publicados'))
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottom),
                    sliver: SliverList.builder(
                      itemCount: _snapshot!.matches.length,
                      itemBuilder: (_, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FixtureCard(item: _snapshot!.matches[index]),
                      ),
                    ),
                  ),
              ] else if (_tab == 1) ...[
                if (_snapshot!.standings.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _EmptyState(theme: theme, label: 'La tabla todavía no está disponible en el feed público'))
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottom),
                    sliver: SliverToBoxAdapter(child: _StandingsCard(items: _snapshot!.standings)),
                  ),
              ] else ...[
                if (_snapshot!.rankings.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _EmptyState(theme: theme, label: 'Los rankings todavía no están disponibles en el feed público'))
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottom),
                    sliver: SliverToBoxAdapter(child: _RankingCard(items: _snapshot!.rankings)),
                  ),
              ],
            ] else if (_loading)
              const SliverFillRemaining(hasScrollBody: false, child: _LoadingState()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(ThemeData theme) {
    final labels = [
      ('Resultados', Icons.sports_soccer_rounded),
      ('Tabla', Icons.leaderboard_rounded),
      ('Rankings', Icons.workspace_premium_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = index == _tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(labels[index].$2, size: 15, color: selected ? theme.colorScheme.onPrimary : theme.hintColor),
                      const SizedBox(width: 5),
                      Text(labels[index].$1, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w800, color: selected ? theme.colorScheme.onPrimary : theme.hintColor)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Ascenso2026Snapshot? snapshot;
  final ThemeData theme;
  final bool isDark;
  const _Hero({required this.snapshot, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final matchCount = snapshot?.matches.length ?? 0;
    final tableCount = snapshot?.standings.length ?? 0;
    final rankingCount = snapshot?.rankings.length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.darkCard, AppTheme.darkBg2]
                : [theme.colorScheme.surface, theme.colorScheme.primary.withValues(alpha: 0.06)],
          ),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.10)),
                  ),
                  child: CachedNetworkImage(imageUrl: _Ascenso2026ScreenState._logoUrl, fit: BoxFit.contain, errorWidget: (_, __, ___) => Icon(Icons.emoji_events_rounded, color: theme.colorScheme.primary, size: 30)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ASCENSO 2026', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: theme.colorScheme.primary)),
                    const SizedBox(height: 5),
                    Text(snapshot?.title.isNotEmpty == true ? snapshot!.title : 'Copa Fácil', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 22, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                    const SizedBox(height: 6),
                    Text('Resultados, clasificación y estadísticas', style: GoogleFonts.spaceGrotesk(fontSize: 11.5, color: theme.hintColor)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Metric(icon: Icons.sports_soccer_rounded, value: '$matchCount', label: 'partidos', theme: theme),
                const SizedBox(width: 8),
                _Metric(icon: Icons.leaderboard_rounded, value: '$tableCount', label: 'equipos', theme: theme),
                const SizedBox(width: 8),
                _Metric(icon: Icons.workspace_premium_rounded, value: '$rankingCount', label: 'rankings', theme: theme),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ThemeData theme;
  const _Metric({required this.icon, required this.value, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.07)),
          ),
          child: Row(children: [
            Icon(icon, size: 15, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 8.5, fontWeight: FontWeight.w600, color: theme.hintColor)),
            ])),
          ]),
        ),
      );
}

class _LiveStatus extends StatelessWidget {
  final Ascenso2026Snapshot snapshot;
  final DateTime? lastUpdated;
  final ThemeData theme;
  const _LiveStatus({required this.snapshot, required this.lastUpdated, required this.theme});

  @override
  Widget build(BuildContext context) {
    final liveCount = snapshot.matches.where((m) => (m.status ?? '').toLowerCase().contains('vivo')).length;
    final hhmm = lastUpdated == null ? '--:--' : '${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: liveCount > 0 ? theme.colorScheme.error : theme.colorScheme.primary, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(liveCount > 0 ? '$liveCount en vivo' : 'Actualizado $hhmm', style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w700, color: liveCount > 0 ? theme.colorScheme.error : theme.hintColor)),
        const Spacer(),
        Text('Actualización automática', style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.hintColor)),
      ]),
    );
  }
}

class _FixtureCard extends StatelessWidget {
  final AscensoFixtureItem item;
  const _FixtureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lower = (item.status ?? '').toLowerCase();
    final isLive = lower.contains('vivo') || lower.contains('live');
    final isFinal = lower.contains('final');

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isLive ? theme.colorScheme.error : theme.dividerColor).withValues(alpha: isLive ? 0.18 : 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.10 : 0.025), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: (isLive ? theme.colorScheme.error : theme.colorScheme.primary).withValues(alpha: 0.09), borderRadius: BorderRadius.circular(13)), child: Icon(isLive ? Icons.bolt_rounded : Icons.sports_soccer_rounded, size: 21, color: isLive ? theme.colorScheme.error : theme.colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w800, height: 1.2)),
            if (item.subtitle.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: theme.hintColor)),
            ],
          ])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (item.score != null) Text(item.score!, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900)),
            if (item.status != null) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: (isLive ? theme.colorScheme.error : isFinal ? theme.hintColor : theme.colorScheme.primary).withValues(alpha: 0.09), borderRadius: BorderRadius.circular(8)), child: Text(item.status!, style: GoogleFonts.spaceGrotesk(fontSize: 8.5, fontWeight: FontWeight.w900, color: isLive ? theme.colorScheme.error : isFinal ? theme.hintColor : theme.colorScheme.primary))),
          ]),
        ]),
      ),
    );
  }
}

class _StandingsCard extends StatelessWidget {
  final List<AscensoStandingItem> items;
  const _StandingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08))),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(padding: const EdgeInsets.fromLTRB(14, 14, 14, 10), color: theme.colorScheme.primary.withValues(alpha: 0.055), child: Row(children: [
          Expanded(child: Text('CLASIFICACIÓN', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .6, color: theme.colorScheme.primary))),
          _HeaderCell('PJ'), _HeaderCell('G'), _HeaderCell('E'), _HeaderCell('P'), _HeaderCell('DG'), _HeaderCell('PTS'),
        ])),
        for (final item in items) _StandingRow(item: item, last: item == items.last),
      ]),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);
  @override
  Widget build(BuildContext context) => SizedBox(width: 27, child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 8, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor)));
}

class _StandingRow extends StatelessWidget {
  final AscensoStandingItem item;
  final bool last;
  const _StandingRow({required this.item, required this.last});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.06)))),
      child: Row(children: [
        SizedBox(width: 26, child: Text(item.position == 0 ? '—' : '${item.position}', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: item.position <= 4 && item.position > 0 ? theme.colorScheme.primary : theme.hintColor))),
        const SizedBox(width: 8),
        Expanded(child: Text(item.team, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700))),
        _TableValue(item.played), _TableValue(item.wins), _TableValue(item.draws), _TableValue(item.losses), _TableValue(item.goalDifference),
        SizedBox(width: 30, child: Text('${item.points}', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: theme.colorScheme.primary))),
      ]),
    );
  }
}

class _TableValue extends StatelessWidget {
  final int value;
  const _TableValue(this.value);
  @override
  Widget build(BuildContext context) => SizedBox(width: 27, child: Text('$value', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).hintColor)));
}

class _RankingCard extends StatelessWidget {
  final List<AscensoRankingItem> items;
  const _RankingCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08))),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 10), child: Row(children: [Icon(Icons.workspace_premium_rounded, size: 18, color: theme.colorScheme.primary), const SizedBox(width: 7), Text('RANKING DE JUGADORES', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .6, color: theme.colorScheme.primary))])),
        for (final item in items) Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: item.position == 1 ? 0.07 : 0.035), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.10), shape: BoxShape.circle), child: Text(item.position > 0 ? '${item.position}' : '—', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.primary))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w800)), Text(item.team, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 9.5, color: theme.hintColor))])),
            Text(item.value, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
          ]),
        )),
        const SizedBox(height: 6),
      ]),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Center(child: PivoteLoader(color: Theme.of(context).colorScheme.primary, strokeWidth: 3, size: 40));
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  final String label;
  const _EmptyState({required this.theme, required this.label});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.data_exploration_rounded, size: 50, color: theme.colorScheme.primary.withValues(alpha: 0.55)), const SizedBox(height: 16), Text(label, textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('La app queda preparada para mostrar los datos en cuanto estén expuestos por la fuente.', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, height: 1.45, color: theme.hintColor))])));
}

class _ErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cloud_off_rounded, size: 50, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16), Text('No pudimos cargar Ascenso 2026', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(error, textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: Theme.of(context).hintColor)), const SizedBox(height: 18), ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Reintentar'))])));
}
