import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/soccer_models.dart';
import '../providers/soccer_provider.dart';
import '../providers/channel_provider.dart';
import '../screens/player_screen.dart';
import 'match_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MatchesHero extends StatefulWidget {
  const MatchesHero({super.key});

  @override
  State<MatchesHero> createState() => _MatchesHeroState();
}

class _MatchesHeroState extends State<MatchesHero> {
  @override
  void initState() {
    super.initState();
    // Actualizar cada minuto para refrescar estados
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SoccerProvider>(
      builder: (context, soccerProvider, child) {
        final isLoading = soccerProvider.isLoading;
        final soccerData = soccerProvider.soccerData;

        List<SoccerMatch> matches = [];
        if (isLoading || soccerData == null) {
          // Dummy matches for skeletonizer
          matches = List.generate(
              3,
              (index) => SoccerMatch(
                    id: 'dummy',
                    homeTeam: 'Team A',
                    awayTeam: 'Team B',
                    homeTeamId: 't1',
                    awayTeamId: 't2',
                    leagueId: 'l1',
                    score: [0, 0],
                    time: '',
                    timeStatus: 'Prog.',
                    status: 'Próximo',
                    startTime: '06-02-2026 17:00',
                    tvChannels: [],
                    stage: 'Fecha 1',
                    goals: [],
                    yellowCards: [],
                    redCards: [],
                  ));
        } else {
          matches = _getFeaturedMatches(soccerData.matches);
        }

        if (!isLoading && matches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 4, bottom: 12),
          child: SizedBox(
            height: 275, // Updated to accommodate new card height
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return Skeletonizer(
                  enabled: isLoading,
                  child: MatchCard(
                    match: match,
                    soccerData: soccerData,
                    onWatchMatch: () => _navigateToChannel(context, match),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Filtra partidos destacados (en vivo o próximos hoy)
  List<SoccerMatch> _getFeaturedMatches(List<SoccerMatch> matches) {
    // Solo mostrar partidos que sean hoy y no hayan terminado hace mucho
    // En este caso, el usuario quiere que los extraigamos de la API.
    // Podríamos filtrar por los que tienen canales o simplemente por estado.
    return matches.where((match) {
      return match.isLive || match.isScheduled;
    }).toList();
  }

  void _navigateToChannel(BuildContext context, SoccerMatch match) {
    final watchableChannels =
        match.tvChannels.where((c) => c.id != null).toList();

    if (watchableChannels.isEmpty) {
      _showErrorSnackBar(
        context,
        'No hay señales disponibles para este partido',
      );
      return;
    }

    final channelProvider =
        Provider.of<ChannelProvider>(context, listen: false);

    debugPrint('🔍 Buscando canales para el partido: ${match.id}');

    // Navegar siempre al primer canal con ID válido
    for (var soccerChannel in watchableChannels) {
      final channelId = soccerChannel.id!;
      debugPrint('🔎 Buscando canal en DB: $channelId');
      final channel = channelProvider.getChannelById(channelId);

      if (channel != null) {
        debugPrint('✅ Canal encontrado: ${channel.name} (${channel.id})');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(channel: channel),
          ),
        );
        return;
      } else {
        debugPrint('❌ Canal no encontrado en nuestra DB: $channelId');
      }
    }

    // Si no se encontró ningún canal en nuestra DB
    debugPrint('⚠️ No se encontró ningún canal coincidente en nuestra DB');
    _showErrorSnackBar(
      context,
      'Canal no disponible en nuestra grilla',
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
