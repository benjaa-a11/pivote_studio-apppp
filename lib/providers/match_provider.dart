import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import '../services/firebase_service.dart';

class MatchProvider extends ChangeNotifier {
  List<Match> _matches = [];
  final Map<String, Team> _teams = {};
  final Map<String, Tournament> _tournaments = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  MatchProvider() {
    // Cargar partidos automáticamente cuando se inicializa el provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadMatchesFromFirestore();
    });
  }

  List<Match> get matches {
    // Ordenar por hora de inicio
    final sortedMatches = List<Match>.from(_matches);
    sortedMatches.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sortedMatches;
  }

  bool get isLoading => _isLoading;

  bool get isInitialized => _isInitialized;

  // Obtener partidos de hoy
  List<Match> get todayMatches {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return matches.where((match) {
      // Check if match is today
      final isToday =
          match.startTime.isAfter(today) && match.startTime.isBefore(tomorrow);

      // Matches should disappear 2 hours and 15 minutes after start time
      final hideTime =
          match.startTime.add(const Duration(hours: 2, minutes: 15));

      // Only include matches that are today and haven't passed the hide time
      return isToday && now.isBefore(hideTime);
    }).toList();
  }

  // Obtener próximos partidos (hoy y mañana)
  List<Match> get upcomingMatches {
    final now = DateTime.now();
    final twoDaysFromNow = now.add(const Duration(days: 2));

    return matches.where((match) {
      // Matches should appear 30 minutes before start time
      final showTime = match.startTime.subtract(const Duration(minutes: 30));

      // Matches should disappear 2 hours and 15 minutes after start time
      final hideTime =
          match.startTime.add(const Duration(hours: 2, minutes: 15));

      return now.isAfter(showTime) &&
          now.isBefore(hideTime) &&
          match.startTime.isBefore(twoDaysFromNow);
    }).toList();
  }

  Future<void> loadMatchesFromFirestore() async {
    _isLoading = true;
    _isInitialized = false;
    notifyListeners();

    try {
      // Load matches
      final matchesSnapshot = await FirebaseService.matchesCollection.get();
      _matches = matchesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Match.fromJson(data);
      }).toList();

      // Load related data (teams, tournaments)
      await _loadRelatedData();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading matches from Firestore: $e');
      _isInitialized = true; // Still mark as initialized to not block app
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRelatedData() async {
    try {
      // Load teams
      final teamsSnapshot = await FirebaseService.teamsCollection.get();
      for (var doc in teamsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID to the data
        _teams[doc.id] = Team.fromJson(data);
      }

      // Load tournaments
      final tournamentsSnapshot =
          await FirebaseService.tournamentsCollection.get();
      for (var doc in tournamentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID to the data
        _tournaments[doc.id] = Tournament.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error loading related data: $e');
    }
  }

  void setMatches(List<Match> matches) {
    _matches = matches;
    notifyListeners();
  }

  void addMatch(Match match) {
    _matches.add(match);
    notifyListeners();
  }

  void removeMatch(String matchId) {
    _matches.removeWhere((match) => match.id == matchId);
    notifyListeners();
  }

  void updateMatch(Match updatedMatch) {
    final index = _matches.indexWhere((match) => match.id == updatedMatch.id);
    if (index != -1) {
      _matches[index] = updatedMatch;
      notifyListeners();
    }
  }

  // Get match by ID
  Match? getMatchById(String id) {
    try {
      return _matches.firstWhere((match) => match.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get team by ID
  Team? getTeamById(String id) {
    return _teams[id];
  }

  // Get tournament by ID
  Tournament? getTournamentById(String id) {
    return _tournaments[id];
  }

  // Get teams for a match
  Team? getTeamA(Match match) {
    return getTeamById(match.teamAId);
  }

  Team? getTeamB(Match match) {
    return getTeamById(match.teamBId);
  }

  // Get tournament for a match
  Tournament? getTournament(Match match) {
    return getTournamentById(match.tournamentId);
  }

  // Get tournament logo URL by ID based on theme
  String getTournamentLogoUrl(String tournamentId, bool isDarkMode) {
    final tournament = getTournamentById(tournamentId);
    if (tournament == null) return '';
    return tournament.getLogoUrl(isDarkMode);
  }

  // Load sample matches (for testing)
  void loadSampleMatches() {
    // This is kept for testing purposes
    _matches = [
      // Sample matches would go here
    ];
    notifyListeners();
  }
}
