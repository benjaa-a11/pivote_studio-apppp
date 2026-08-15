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
  DateTime? _lastUpdated;
  Timer? _timer;

  static const _logoUrl =
      'https://firebasestorage.googleapis.com/v0/b/copafacil-web.appspot.com/o/evts%2F-ncnoo5vqvuwobcpml2n%2F1693084870250.png?alt=media';

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
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
            onPressed: () => _load(),
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
            SliverToBoxAdapter(child: _buildHero(theme, isDark)),
            if (_error != null && _snapshot == null)
              SliverFillRemaining(hasScrollBody: false, child: _buildError(theme)),
            if (_snapshot != null) ...[
              SliverToBoxAdapter(child: _buildStatus(theme)),
              if (_snapshot!.sections.isNotEmpty)
                SliverToBoxAdapter(child: _buildSectionChips(theme, _snapshot!.sections)),
              if (_snapshot!.matches.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _buildEmpty(theme))
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottom),
                  sliver: SliverList.builder(
                    itemCount: _snapshot!.matches.length,
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MatchRow(item: _snapshot!.matches[index]),
                    ),
                  ),
                ),
            ] else if (_loading)
              const SliverFillRemaining(hasScrollBody: false, child: _LoadingState()),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
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
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
              ),
              child: CachedNetworkImage(
                imageUrl: _logoUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => Icon(
                  Icons.emoji_events_rounded,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASCENSO 2026',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _snapshot?.title.isNotEmpty == true
                        ? _snapshot!.title
                        : 'Todos los resultados',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Resultados y novedades de Copa Fácil',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11.5,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(ThemeData theme) {
    final time = _lastUpdated == null
        ? 'Actualizando…'
        : 'Actualizado ${_formatTime(_lastUpdated!)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            time,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: theme.hintColor,
            ),
          ),
          const Spacer(),
          Text(
            '${_snapshot!.matches.length} registros',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionChips(ThemeData theme, List<String> sections) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: sections.length,
        itemBuilder: (_, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            sections[index],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 50, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar Ascenso 2026',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Intentá nuevamente en unos segundos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: theme.hintColor, height: 1.45),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 52, color: theme.colorScheme.primary.withValues(alpha: 0.55)),
            const SizedBox(height: 16),
            Text('Sin resultados publicados todavía', style: GoogleFonts.spaceGrotesk(fontSize: 19, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('La página pública de Copa Fácil no expuso registros de partidos en esta actualización.', style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: theme.hintColor, height: 1.45), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: PivoteLoader(
        color: theme.colorScheme.primary,
        strokeWidth: 3,
        size: 40,
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final AscensoFixtureItem item;

  const _MatchRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = item.status?.toLowerCase().contains('vivo') == true ||
        item.status?.toLowerCase().contains('live') == true ||
        item.status?.toLowerCase().contains('ao vivo') == true;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.10 : 0.025),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isLive
                    ? theme.colorScheme.error.withValues(alpha: 0.10)
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isLive ? Icons.bolt_rounded : Icons.sports_soccer_rounded,
                size: 20,
                color: isLive ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10.5,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.score != null)
                  Text(
                    item.score!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                if (item.status != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLive
                          ? theme.colorScheme.error.withValues(alpha: 0.10)
                          : theme.colorScheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: isLive ? theme.colorScheme.error : theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
