import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/data/services/soccer_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';
import 'package:pivote/features/video/data/models/channel.dart';
import 'package:pivote/features/video/presentation/providers/channel_provider.dart';

class SoccerProvider extends ChangeNotifier {
  final SoccerService _soccerService = SoccerService();

  SoccerData? _soccerData;
  bool _isLoading = false;
  bool _isFetching = false;
  String? _error;
  Timer? _updateTimer;
  DateTime? _lastFetchedAt;

  SoccerData? get soccerData => _soccerData;
  SoccerData? get data => _soccerData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetchedAt => _lastFetchedAt;

  bool get hasMatchesForToday {
    final matches = _soccerData?.matches ?? [];
    return matches.any((m) => m.isToday);
  }

  List<SoccerMatch> get heroMatches {
    final matches = _soccerData?.matches ?? [];
    return matches.where((m) => !m.shouldRemoveFromHero).toList();
  }

  /// Filtra los partidos para el Hero del inicio: solo aparecen los partidos que
  /// tienen al menos un canal de transmisión cuyo `id` coincide con un canal
  /// real en la base de datos de la app (`ChannelProvider`).
  List<SoccerMatch> playableHeroMatches(ChannelProvider channelProvider) {
    return heroMatches
        .where((m) => resolveChannelsForMatch(m, channelProvider).isNotEmpty)
        .toList();
  }

  /// Devuelve los canales de nuestra app que coinciden por `id` con los
  /// `broadcasts` del partido.
  List<Channel> resolveChannelsForMatch(
    SoccerMatch match,
    ChannelProvider channelProvider,
  ) {
    final resolved = <Channel>[];
    final seenIds = <String>{};
    for (final b in match.tvChannels) {
      final bid = b.id?.trim();
      if (bid == null || bid.isEmpty) continue;
      final ch = channelProvider.getChannelById(bid);
      if (ch != null && seenIds.add(ch.id)) {
        resolved.add(ch);
      }
    }
    return resolved;
  }

  int get liveMatchesCount {
    final matches = _soccerData?.matches ?? [];
    return matches.where((m) => m.isLive).length;
  }

  Future<void> refresh() => fetchData(silent: _soccerData != null);

  SoccerProvider() {
    fetchData();
    _startAutoUpdate();
  }

  Future<void> fetchData({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final newData = await _soccerService.fetchLiveSoccerData();
      _soccerData = newData;
      _isLoading = false;
      _error = null;
      _lastFetchedAt = DateTime.now();

      if (!silent) {
        _warmUpSoccerLogos(newData);
      }
    } catch (e) {
      // En refrescos silenciosos (cada 15s), conservar la última data válida sin mostrar error
      if (!silent || _soccerData == null) {
        _error = e.toString();
      }
      _isLoading = false;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  void _startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchData(silent: true);
    });
  }

  void retry() {
    fetchData();
    _startAutoUpdate();
  }

  void refreshIfStale() {
    if (_lastFetchedAt == null) {
      fetchData(silent: true);
      return;
    }

    final difference = DateTime.now().difference(_lastFetchedAt!);
    if (difference.inSeconds >= 15) {
      fetchData(silent: true);
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  /// Pre-carga logos de equipos y ligas de fútbol en background
  void _warmUpSoccerLogos(SoccerData data) {
    try {
      final logoUrls = <String>{};

      for (final team in data.teams) {
        final url = team.logoUrl;
        if (url != null && url.isNotEmpty && url.startsWith('http')) {
          logoUrls.add(url);
        }
      }

      for (final league in data.leagues) {
        final url = league.logoUrl;
        if (url != null && url.isNotEmpty && url.startsWith('http')) {
          logoUrls.add(url);
        }
      }

      if (logoUrls.isNotEmpty) {
        ImageCacheHelper.warmUpCache(
          logoUrls.take(50).toList(),
          isLogos: true,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error pre-cargando logos de fútbol: $e');
    }
  }
}
