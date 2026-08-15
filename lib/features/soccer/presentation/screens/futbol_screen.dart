import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/soccer/presentation/widgets/soccer_match_card.dart';
import 'package:pivote/features/soccer/presentation/screens/ascenso_2026_screen.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class FutbolScreen extends StatefulWidget {
  const FutbolScreen({super.key});

  @override
  State<FutbolScreen> createState() => _FutbolScreenState();
}

class _FutbolScreenState extends State<FutbolScreen> {
  String _selectedLeagueId = 'all';

  bool _isHeroMatch(SoccerMatch match) {
    if (match.shouldRemoveFromHero || match.isAutoFinished) return false;
    if (!(match.isLive || match.isScheduled || (match.isFinished && !match.shouldRemoveFromHero))) return false;
    return match.tvChannels.any((c) => c.id != null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SoccerProvider>();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(child: _buildContent(provider, theme)),
    );
  }

  Widget _buildContent(SoccerProvider provider, ThemeData theme) {
    if (provider.isLoading && provider.soccerData == null) {
      return Center(child: PivoteLoader(color: theme.colorScheme.primary, strokeWidth: 3, size: 40));
    }
    if (provider.error != null && provider.soccerData == null) return _buildError(provider, theme);
    final data = provider.soccerData;
    if (data == null || data.matches.isEmpty) return _buildEmpty(theme);

    final sourceMatches = _selectedLeagueId == 'all'
        ? data.matches
        : data.matches.where((m) => m.leagueId == _selectedLeagueId).toList();
    // The home screen already exposes these featured matches in MatchesHero.
    // Keep the football tab focused on the complete competition calendar without duplicates.
    final filtered = sourceMatches.where((m) => !_isHeroMatch(m)).toList();
    final live = filtered.where((m) => m.isLive).toList();
    final upcoming = filtered.where((m) => !m.isLive && !m.isFinished).toList();

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      backgroundColor: theme.cardColor,
      strokeWidth: 2.5,
      onRefresh: provider.fetchData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(data, live.length, upcoming.length, theme)),
          SliverToBoxAdapter(child: _buildSectionTitle(theme, 'Competiciones', 'Explorá por torneo')),
          SliverToBoxAdapter(child: _buildLeagueCarousel(data, theme)),
          SliverToBoxAdapter(child: _buildSectionTitle(theme, 'Partidos', 'Resultados, horarios y detalles')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: _buildMatchesList(filtered, data, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SoccerData data, int liveCount, int upcomingCount, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final featured = data.matches.where(_isHeroMatch).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [AppTheme.darkCard.withValues(alpha: 0.98), AppTheme.darkBg2] : [theme.colorScheme.surface, theme.colorScheme.primary.withValues(alpha: 0.045)],
          ),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.10)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.045), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sports_soccer_rounded, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 5),
                            Text('FÚTBOL', style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: theme.colorScheme.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('El mundo del fútbol', style: GoogleFonts.spaceGrotesk(fontSize: 27, height: 1.0, fontWeight: FontWeight.w800, letterSpacing: -1.1)),
                      const SizedBox(height: 7),
                      Text('Partidos, resultados y encuentros en vivo en un solo lugar.', style: GoogleFonts.spaceGrotesk(fontSize: 12.5, height: 1.4, color: theme.hintColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.10))),
                  child: Icon(Icons.sports_score_rounded, size: 20, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _StatBadge(icon: Icons.flash_on_rounded, label: '$liveCount en vivo', active: liveCount > 0, theme: theme),
                const SizedBox(width: 8),
                _StatBadge(icon: Icons.schedule_rounded, label: '$upcomingCount próximos', active: false, theme: theme),
                const Spacer(),
                Text('${filteredMatchCount(data)} partidos', style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w700, color: theme.hintColor)),
              ],
            ),
            if (featured > 0) ...[
              const SizedBox(height: 11),
              Row(children: [Icon(Icons.auto_awesome_rounded, size: 13, color: theme.colorScheme.primary), const SizedBox(width: 5), Text('$featured destacados ya aparecen en Inicio', style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w600, color: theme.hintColor))]),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const Ascenso2026Screen()));
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: theme.colorScheme.onSurface,
                  foregroundColor: theme.scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Image.network(
                        'https://firebasestorage.googleapis.com/v0/b/copafacil-web.appspot.com/o/evts%2F-ncnoo5vqvuwobcpml2n%2F1693084870250.png?alt=media',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.emoji_events_rounded, size: 17, color: theme.scaffoldBackgroundColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('ASCENSO 2026', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.7)),
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: theme.scaffoldBackgroundColor.withValues(alpha: 0.75)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int filteredMatchCount(SoccerData data) {
    final source = _selectedLeagueId == 'all' ? data.matches : data.matches.where((m) => m.leagueId == _selectedLeagueId);
    return source.where((m) => !_isHeroMatch(m)).length;
  }

  Widget _buildSectionTitle(ThemeData theme, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        const SizedBox(height: 3),
        Text(subtitle, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500, color: theme.hintColor)),
      ]),
    );
  }

  Widget _buildLeagueCarousel(SoccerData data, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: data.leagues.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          if (index == 0) {
            final count = data.matches.where((m) => !_isHeroMatch(m)).length;
            return _LeagueChip(label: 'Todo', count: count, selected: _selectedLeagueId == 'all', isAll: true, theme: theme, isDark: isDark, onTap: () => setState(() => _selectedLeagueId = 'all'));
          }
          final league = data.leagues[index - 1];
          final count = data.matches.where((m) => m.leagueId == league.id && !_isHeroMatch(m)).length;
          return _LeagueChip(label: league.shortName, count: count, selected: _selectedLeagueId == league.id, logoUrl: league.logoUrl, theme: theme, isDark: isDark, onTap: () => setState(() => _selectedLeagueId = league.id));
        },
      ),
    );
  }

  Widget _buildMatchesList(List<SoccerMatch> matches, SoccerData data, ThemeData theme) {
    if (matches.isEmpty) return SliverFillRemaining(hasScrollBody: false, child: _buildEmpty(theme, message: 'No hay partidos para esta competición'));
    final grouped = <String, List<SoccerMatch>>{};
    for (final match in matches) grouped.putIfAbsent(match.leagueId, () => []).add(match);
    final entries = grouped.entries.toList();
    if (entries.isEmpty) return SliverFillRemaining(hasScrollBody: false, child: _buildEmpty(theme, message: 'No hay partidos para esta competición'));
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          final league = data.leagues.firstWhere((l) => l.id == entry.key, orElse: () => SoccerLeague(id: entry.key, name: entry.key.toUpperCase(), shortName: entry.key.toUpperCase(), country: ''));
          return AppAnimations.staggeredSlideIn(
            index: index,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.12 : 0.035), blurRadius: 16, offset: const Offset(0, 6))]),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(league.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800))),
                    Text('${entry.value.length} partidos', style: GoogleFonts.spaceGrotesk(fontSize: 9.5, fontWeight: FontWeight.w600, color: theme.hintColor)),
                  ]),
                ),
                for (var i = 0; i < entry.value.length; i++) SoccerMatchCard(match: entry.value[i], data: data, isLast: i == entry.value.length - 1),
              ]),
            ),
          );
        },
        childCount: entries.length,
      ),
    );
  }

  Widget _buildError(SoccerProvider provider, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, size: 52, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('No pudimos actualizar el fútbol', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(provider.error ?? 'Revisá tu conexión e intentá nuevamente.', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 13, color: theme.hintColor)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: provider.fetchData, icon: const Icon(Icons.refresh_rounded), label: const Text('Reintentar')),
        ]),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, {String message = 'No hay partidos disponibles ahora'}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 82, height: 82, decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.sports_soccer_rounded, size: 40, color: theme.colorScheme.primary.withValues(alpha: 0.65))),
          const SizedBox(height: 18),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text('Actualizá para volver a consultar la agenda.', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: theme.hintColor)),
        ]),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final ThemeData theme;
  const _StatBadge({required this.icon, required this.label, required this.active, required this.theme});
  @override
  Widget build(BuildContext context) {
    final color = active ? theme.colorScheme.error : theme.colorScheme.primary;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(11), border: Border.all(color: color.withValues(alpha: 0.10))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: color), const SizedBox(width: 5), Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w800, color: color))]));
  }
}

class _LeagueChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final bool isAll;
  final String? logoUrl;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onTap;
  const _LeagueChip({required this.label, required this.count, required this.selected, this.isAll = false, this.logoUrl, required this.theme, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: selected ? LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.82)]) : LinearGradient(colors: isDark ? [AppTheme.darkCard, AppTheme.darkBg2] : [theme.colorScheme.surface, theme.scaffoldBackgroundColor]), border: Border.all(color: selected ? theme.colorScheme.primary.withValues(alpha: 0.30) : theme.dividerColor.withValues(alpha: 0.09)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: selected ? 0.08 : 0.025), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!isAll && logoUrl != null && logoUrl!.isNotEmpty)
            SizedBox(width: 18, height: 18, child: Image.network(logoUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.emoji_events_rounded, size: 16, color: selected ? Colors.white70 : theme.hintColor)))
          else
            Icon(isAll ? Icons.apps_rounded : Icons.emoji_events_rounded, size: 16, color: selected ? Colors.white : theme.colorScheme.primary),
          const SizedBox(width: 7),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : theme.colorScheme.onSurface)),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: selected ? Colors.white.withValues(alpha: 0.22) : theme.colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(7)), child: Text('$count', style: GoogleFonts.spaceGrotesk(fontSize: 8.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : theme.colorScheme.primary))),
        ]),
      ),
    );
  }
}
