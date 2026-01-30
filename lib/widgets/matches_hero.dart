import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../providers/channel_provider.dart';
import '../models/match.dart';
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
    return Consumer<MatchProvider>(
      builder: (context, matchProvider, child) {
        final isLoading = matchProvider.isLoading;

        List<Match> matches = [];
        if (isLoading) {
          matches = List.generate(
              3,
              (index) => Match(
                    id: 'dummy',
                    teamAId: 'team',
                    teamBId: 'team',
                    tournamentId: 'tournament',
                    startTime: DateTime.now(),
                    date: 'Today',
                    channelIds: [],
                  ));
        } else {
          matches = _getActiveMatches(matchProvider.todayMatches);
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

  /// Filtra partidos activos (no finalizados)
  List<Match> _getActiveMatches(List<Match> matches) {
    final now = DateTime.now();

    return matches.where((match) {
      final endTime =
          match.startTime.add(const Duration(hours: 2, minutes: 30));
      return now.isBefore(endTime);
    }).toList();
  }

  void _navigateToChannel(BuildContext context, Match match) {
    if (match.channelIds.isEmpty) {
      _showErrorSnackBar(
        context,
        'No hay canales disponibles para este partido',
      );
      return;
    }

    final channelProvider =
        Provider.of<ChannelProvider>(context, listen: false);

    debugPrint('🔍 Buscando canales para el partido: ${match.id}');
    debugPrint('📺 IDs de canales en el partido: ${match.channelIds}');

    // Navegar siempre al primer canal disponible
    // Intentar encontrar el primer canal válido
    for (var channelId in match.channelIds) {
      debugPrint('🔎 Buscando canal: $channelId');
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
        debugPrint('❌ Canal no encontrado: $channelId');
      }
    }

    // Si no se encontró ningún canal
    debugPrint('⚠️ No se encontró ningún canal disponible');
    _showErrorSnackBar(
      context,
      'Canal no disponible en este momento',
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
