import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/presentation/providers/soccer_provider.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';
import 'package:pivote/features/video/presentation/screens/player_screen.dart';
import 'package:pivote/shared/widgets/app_notifications.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'match_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MatchesHero extends StatefulWidget {
  const MatchesHero({super.key});

  @override
  State<MatchesHero> createState() => _MatchesHeroState();
}

class _MatchesHeroState extends State<MatchesHero> {
  Timer? _uiTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refrescar la UI internamente cada minuto
    _uiTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    // Realizar consulta al servidor cada hora
    _refreshTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (mounted) {
        context.read<SoccerProvider>().fetchData(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
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
              physics: const ClampingScrollPhysics(),
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

  /// Filtra partidos destacados (en vivo o próximos hoy con señales válidas)
  List<SoccerMatch> _getFeaturedMatches(List<SoccerMatch> matches) {
    return matches.where((match) {
      // Excluir si ya pasó el tiempo de permanencia (10 min después de finalizar) o auto-finish
      if (match.shouldRemoveFromHero || match.isAutoFinished) return false;

      // Solo mostrar si es en vivo, programado o finalizado recientemente
      final isFeatured = match.isLive ||
          match.isScheduled ||
          (match.isFinished && !match.shouldRemoveFromHero);
      if (!isFeatured) return false;

      // Y solo si tiene al menos un canal con ID válido
      final hasValidChannels = match.tvChannels.any((c) => c.id != null);

      return hasValidChannels;
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
          AppAnimations.createFadeRoute(PlayerScreen(channel: channel)),
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
    AppNotifications.showError(context, message);
  }
}
