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

  // Estado por fecha seleccionada en la sección Fútbol ('today' o 'yyyy-MM-dd')
  String _selectedDateKey = 'today';
  final Map<String, SoccerData> _dateCache = {};
  bool _isLoadingDate = false;
  String? _dateError;

  SoccerData? get soccerData => _soccerData;
  SoccerData? get data => _soccerData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetchedAt => _lastFetchedAt;

  String get selectedDateKey => _selectedDateKey;
  bool get isViewingToday => _selectedDateKey == 'today';
  bool get isLoadingSelectedDate =>
      isViewingToday ? _isLoading : _isLoadingDate;
  String? get selectedDateError => isViewingToday ? _error : _dateError;
  SoccerData? get selectedDateData =>
      isViewingToday ? _soccerData : _dateCache[_selectedDateKey];

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

  Future<void> refresh() {
    if (isViewingToday) {
      return fetchData(silent: _soccerData != null);
    }
    return selectDate(_selectedDateKey, forceRefresh: true);
  }

  SoccerProvider() {
    // No consultar el Worker ni iniciar el polling antes de autenticar.
    // `_AuthenticationWrapper` invoca `startAuthenticatedSession()` tras cargar `config/app`.
  }

  /// Arranca la carga de partidos y el refresco cada 15 s solo tras autenticar.
  Future<void> startAuthenticatedSession() async {
    await fetchData();
    _startAutoUpdate();
  }

  /// Detiene el polling y limpia los partidos al cerrar sesión o ser revocado.
  void clearOnLogout() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _soccerData = null;
    _dateCache.clear();
    _selectedDateKey = 'today';
    _error = null;
    _dateError = null;
    _lastFetchedAt = null;
    _isLoading = false;
    _isLoadingDate = false;
    _isFetching = false;
    notifyListeners();
  }

  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> selectDate(String dateKey, {bool forceRefresh = false}) async {
    final todayKey = formatDateKey(DateTime.now());
    final normalized = (dateKey == 'today' || dateKey == todayKey)
        ? 'today'
        : dateKey;

    _selectedDateKey = normalized;
    _dateError = null;

    if (normalized == 'today') {
      notifyListeners();
      if (forceRefresh || _soccerData == null) {
        await fetchData(silent: _soccerData != null);
      }
      return;
    }

    if (!forceRefresh && _dateCache.containsKey(normalized)) {
      _isLoadingDate = false;
      notifyListeners();
      return;
    }

    _isLoadingDate = true;
    notifyListeners();

    try {
      final fetched = await _soccerService.fetchMatches(date: normalized);
      _dateCache[normalized] = fetched;
      _dateError = null;
      _warmUpSoccerLogos(fetched);
    } catch (e) {
      if (!_dateCache.containsKey(normalized)) {
        _dateError = e.toString();
      }
    } finally {
      _isLoadingDate = false;
      notifyListeners();
    }
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
      final newData = await _soccerService.fetchMatches(date: 'today');
      _soccerData = newData;
      _isLoading = false;
      _error = null;
      _lastFetchedAt = DateTime.now();

      if (!silent) {
        _warmUpSoccerLogos(newData);
      }
    } catch (e) {
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
    if (isViewingToday) {
      fetchData();
      _startAutoUpdate();
    } else {
      selectDate(_selectedDateKey, forceRefresh: true);
    }
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
