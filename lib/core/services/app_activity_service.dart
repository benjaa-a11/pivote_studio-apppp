import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pivote/features/auth/data/services/auth_service.dart';

/// Service to track and persist app usage statistics and active session time.
/// Stats are stored locally in SharedPreferences AND synced to Firestore
/// so they persist across devices and app reinstalls.
class AppActivityService with ChangeNotifier, WidgetsBindingObserver {
  static const String _keyActiveSeconds = 'pivote_active_seconds';
  static const String _keySessionCount = 'pivote_session_count';
  static const String _keyChannelsWatched = 'pivote_channels_watched';
  static const String _keyRadiosListened = 'pivote_radios_listened';
  static const String _keyMatchesViewed = 'pivote_matches_viewed';
  static const String _keyFirstActive = 'pivote_first_active';

  int _totalActiveSeconds = 0;
  int _sessionCount = 0;
  int _channelsWatched = 0;
  int _radiosListened = 0;
  int _matchesViewed = 0;
  DateTime? _firstActiveDate;

  Timer? _timer;
  bool _isActive = true;
  int _currentSessionSeconds = 0;

  /// Throttle: only write to Firestore at most once every 60 seconds.
  DateTime? _lastFirestoreSync;

  int get totalActiveSeconds => _totalActiveSeconds + _currentSessionSeconds;
  int get sessionCount => _sessionCount;
  int get channelsWatched => _channelsWatched;
  int get radiosListened => _radiosListened;
  int get matchesViewed => _matchesViewed;
  DateTime? get firstActiveDate => _firstActiveDate;

  AppActivityService() {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalActiveSeconds = prefs.getInt(_keyActiveSeconds) ?? 0;
      _sessionCount = prefs.getInt(_keySessionCount) ?? 0;
      _channelsWatched = prefs.getInt(_keyChannelsWatched) ?? 0;
      _radiosListened = prefs.getInt(_keyRadiosListened) ?? 0;
      _matchesViewed = prefs.getInt(_keyMatchesViewed) ?? 0;

      final firstActiveStr = prefs.getString(_keyFirstActive);
      if (firstActiveStr != null) {
        _firstActiveDate = DateTime.tryParse(firstActiveStr);
      } else {
        _firstActiveDate = DateTime.now();
        await prefs.setString(_keyFirstActive, _firstActiveDate!.toIso8601String());
      }

      // Increment session count for new app launch
      _sessionCount++;
      await prefs.setInt(_keySessionCount, _sessionCount);

      // Merge with any cloud data (keeps the highest values)
      await _mergeFromFirestore(prefs);

      _startTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing AppActivityService: $e');
    }
  }

  // ─── Firestore sync ──────────────────────────────────────────────

  /// Pull stats from Firestore and merge by keeping the maximum value.
  Future<void> _mergeFromFirestore(SharedPreferences prefs) async {
    try {
      final uid = AuthService.currentUserId;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!doc.exists) return;
      final data = doc.data()!;

      final remoteSeconds = (data['totalActiveSeconds'] as num?)?.toInt() ?? 0;
      final remoteSessions = (data['sessionCount'] as num?)?.toInt() ?? 0;
      final remoteChannels = (data['channelsWatched'] as num?)?.toInt() ?? 0;
      final remoteRadios = (data['radiosListened'] as num?)?.toInt() ?? 0;
      final remoteMatches = (data['matchesViewed'] as num?)?.toInt() ?? 0;
      final remoteFirstActive = data['firstActiveDate'] as String?;

      if (remoteSeconds > _totalActiveSeconds) {
        _totalActiveSeconds = remoteSeconds;
        await prefs.setInt(_keyActiveSeconds, _totalActiveSeconds);
      }
      if (remoteSessions > _sessionCount) {
        _sessionCount = remoteSessions;
        await prefs.setInt(_keySessionCount, _sessionCount);
      }
      if (remoteChannels > _channelsWatched) {
        _channelsWatched = remoteChannels;
        await prefs.setInt(_keyChannelsWatched, _channelsWatched);
      }
      if (remoteRadios > _radiosListened) {
        _radiosListened = remoteRadios;
        await prefs.setInt(_keyRadiosListened, _radiosListened);
      }
      if (remoteMatches > _matchesViewed) {
        _matchesViewed = remoteMatches;
        await prefs.setInt(_keyMatchesViewed, _matchesViewed);
      }
      if (remoteFirstActive != null) {
        final remoteDate = DateTime.tryParse(remoteFirstActive);
        if (remoteDate != null &&
            (_firstActiveDate == null || remoteDate.isBefore(_firstActiveDate!))) {
          _firstActiveDate = remoteDate;
          await prefs.setString(_keyFirstActive, remoteFirstActive);
        }
      }

      debugPrint('✅ AppActivityService: Stats merged from Firestore');
    } catch (e) {
      debugPrint('⚠️ AppActivityService: Could not merge from Firestore: $e');
    }
  }

  /// Write current stats to Firestore (throttled to max once per 60 s unless forced).
  Future<void> _syncToFirestore({bool force = false}) async {
    try {
      final uid = AuthService.currentUserId;
      if (uid == null) return;

      final now = DateTime.now();
      if (!force &&
          _lastFirestoreSync != null &&
          now.difference(_lastFirestoreSync!).inSeconds < 60) {
        return;
      }
      _lastFirestoreSync = now;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'totalActiveSeconds': totalActiveSeconds,
        'sessionCount': _sessionCount,
        'channelsWatched': _channelsWatched,
        'radiosListened': _radiosListened,
        'matchesViewed': _matchesViewed,
        'firstActiveDate': _firstActiveDate?.toIso8601String(),
        'statsUpdatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ AppActivityService: Stats synced to Firestore');
    } catch (e) {
      debugPrint('⚠️ AppActivityService: Could not sync to Firestore: $e');
    }
  }

  // ─── Timer ───────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isActive) {
        _currentSessionSeconds++;
        // Notify listeners every 5 seconds to keep the UI feeling "alive"
        if (_currentSessionSeconds % 5 == 0) {
          notifyListeners();
        }
        // Persist to disk every 30 seconds
        if (_currentSessionSeconds % 30 == 0) {
          _persistActiveTime();
        }
        // Sync to Firestore every 60 seconds
        if (_currentSessionSeconds % 60 == 0) {
          _syncToFirestore();
        }
      }
    });
  }

  Future<void> _persistActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalActiveSeconds += _currentSessionSeconds;
      _currentSessionSeconds = 0;
      await prefs.setInt(_keyActiveSeconds, _totalActiveSeconds);
    } catch (e) {
      debugPrint('❌ Error persisting active time: $e');
    }
  }

  // ─── Tracking methods ────────────────────────────────────────────

  Future<void> trackChannelWatch() async {
    _channelsWatched++;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyChannelsWatched, _channelsWatched);
      await _syncToFirestore();
    } catch (e) {
      debugPrint('❌ Error tracking channel watch: $e');
    }
  }

  Future<void> trackRadioListen() async {
    _radiosListened++;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyRadiosListened, _radiosListened);
      await _syncToFirestore();
    } catch (e) {
      debugPrint('❌ Error tracking radio listen: $e');
    }
  }

  Future<void> trackMatchView() async {
    _matchesViewed++;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyMatchesViewed, _matchesViewed);
      await _syncToFirestore();
    } catch (e) {
      debugPrint('❌ Error tracking match view: $e');
    }
  }

  /// Call this after a successful login so stats re-merge from Firestore.
  /// Useful when the user signs in on a new device.
  Future<void> onUserLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await _mergeFromFirestore(prefs);
    notifyListeners();
  }

  // ─── Lifecycle ───────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isActive = true;
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached) {
      _isActive = false;
      _persistActiveTime().then((_) => _syncToFirestore(force: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _persistActiveTime().then((_) => _syncToFirestore(force: true));
    super.dispose();
  }

  // ─── Formatting helpers ──────────────────────────────────────────

  String getFormattedActiveTime() {
    final total = totalActiveSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String getFormattedStartDate() {
    if (_firstActiveDate == null) return 'Hoy';
    final day = _firstActiveDate!.day.toString().padLeft(2, '0');
    final month = _firstActiveDate!.month.toString().padLeft(2, '0');
    final year = _firstActiveDate!.year;
    return '$day/$month/$year';
  }

  String getArgentineRank() {
    final minutes = totalActiveSeconds / 60;
    if (minutes < 5) {
      return 'Cebador de Mate';
    } else if (minutes < 30) {
      return 'Pasador de Facturas';
    } else if (minutes < 120) {
      return 'Asador de Fin de Semana';
    } else if (minutes < 480) {
      return 'Convocado a la Scaloneta';
    } else {
      return 'Campeón del Mundo ⭐⭐⭐';
    }
  }

  String getArgentineRankDescription() {
    final minutes = totalActiveSeconds / 60;
    if (minutes < 5) {
      return 'Recién arrancás el viaje, ¡preparate unos amargos!';
    } else if (minutes < 30) {
      return 'Ya te movés por la app como quien busca medialunas.';
    } else if (minutes < 120) {
      return 'Un maestro del fuego. Manejás los canales con maestría.';
    } else if (minutes < 480) {
      return 'Tenés lugar asegurado en el banco. ¡Sos clave en el equipo!';
    } else {
      return '¡Qué elegancia la de Francia! Mentira, ¡somos el mejor país del mundo!';
    }
  }

  String getArgentineRankEmoji() {
    final minutes = totalActiveSeconds / 60;
    if (minutes < 5) {
      return '🧉';
    } else if (minutes < 30) {
      return '🥐';
    } else if (minutes < 120) {
      return '🥩';
    } else if (minutes < 480) {
      return '🏆';
    } else {
      return '👑';
    }
  }
}
